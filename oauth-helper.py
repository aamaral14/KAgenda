#!/usr/bin/env python3
"""
OAuth helper script for Google Calendar and Nextcloud Calendar
This runs separately from the widget to handle OAuth flow
"""

import sys
import json
import os
import time
import urllib.parse
import socket
import re
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
import webbrowser
import threading

# Google OAuth imports
try:
    from google_auth_oauthlib.flow import InstalledAppFlow
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    from googleapiclient.discovery import build
    GOOGLE_AVAILABLE = True
except ImportError:
    GOOGLE_AVAILABLE = False

# Nextcloud OAuth imports
try:
    import requests
    REQUESTS_AVAILABLE = True
except ImportError:
    REQUESTS_AVAILABLE = False

SCOPES = ['https://www.googleapis.com/auth/calendar.readonly']
config_dir = Path.home() / ".config" / "kagenda"
config_dir.mkdir(parents=True, exist_ok=True)
token_file = config_dir / "token.json"
credentials_file = config_dir / "credentials.json"
config_file = config_dir / "config.json"
nextcloud_token_file = config_dir / "nextcloud_token.json"
nextcloud_credentials_file = config_dir / "nextcloud_credentials.json"

# Global variable to store auth code
oauth_auth_code = None

class OAuthCallbackHandler(BaseHTTPRequestHandler):
    """HTTP handler for OAuth callback"""
    
    def do_GET(self):
        global oauth_auth_code
        query = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(query)
        
        if 'code' in params:
            oauth_auth_code = params['code'][0]
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b'<html><body><h1>Authentication successful!</h1><p>You can close this window.</p></body></html>')
        elif 'error' in params:
            self.send_response(400)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(f'<html><body><h1>Authentication failed</h1><p>{params["error"][0]}</p></body></html>'.encode())
        else:
            self.send_response(400)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b'<html><body><h1>Invalid request</h1></body></html>')
    
    def log_message(self, format, *args):
        pass  # Suppress logging


class ReusableHTTPServer(HTTPServer):
    """HTTPServer subclass that allows quick reuse of the same address/port.
    
    This avoids 'address already in use' errors when the helper is run
    multiple times in quick succession (common when re-authenticating).
    """
    allow_reuse_address = True


def find_free_port(preferred_port: int = 8080, max_offset: int = 20) -> int | None:
    """Find a free TCP port on localhost, starting from preferred_port.
    
    Tries preferred_port, preferred_port+1, ... up to max_offset range.
    Returns the first free port number, or None if none found.
    """
    for offset in range(max_offset):
        port = preferred_port + offset
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                s.bind(("localhost", port))
            except OSError:
                continue
        return port
    return None

def authenticate_google(client_id=None, client_secret=None, port=None):
    """Run Google OAuth flow and save token"""
    if not GOOGLE_AVAILABLE:
        sys.stderr.write("ERROR: Google OAuth libraries not available. Install: sudo apt install python3-google-auth-oauthlib python3-google-api-python-client\n")
        sys.exit(1)
    
    creds = None
    
    if token_file.exists():
        try:
            creds = Credentials.from_authorized_user_file(str(token_file), SCOPES)
        except:
            pass
    
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
            except Exception as e:
                if token_file.exists():
                    token_file.unlink()
                creds = None
        
        if not creds or not creds.valid:
            # Use provided credentials or try to read from file
            if client_id and client_secret:
                # Create credentials dict from provided values
                client_config = {
                    "installed": {
                        "client_id": client_id,
                        "client_secret": client_secret,
                        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                        "token_uri": "https://oauth2.googleapis.com/token",
                        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                        "redirect_uris": ["http://localhost"]
                    }
                }
                sys.stderr.write("DEBUG: Using provided Google OAuth credentials\n")
            else:
                # Fallback to credentials file
                if not credentials_file.exists():
                    sys.stderr.write(f"ERROR: Either provide client_id and client_secret as arguments, or place credentials.json in {credentials_file}\n")
                    sys.exit(1)
                
                try:
                    with open(credentials_file, 'r') as f:
                        client_config = json.load(f)
                        if 'installed' not in client_config:
                            sys.stderr.write(f"ERROR: credentials.json must have 'installed' key. Current keys: {list(client_config.keys())}\n")
                            sys.exit(1)
                except json.JSONDecodeError as e:
                    sys.stderr.write(f"ERROR: credentials.json is not valid JSON: {e}\n")
                    sys.exit(1)
                except Exception as e:
                    sys.stderr.write(f"ERROR: Cannot read credentials.json: {e}\n")
                    sys.exit(1)
            
            # Create a temporary credentials file if using provided credentials
            temp_creds_file = None
            if client_id and client_secret:
                import tempfile
                temp_creds_file = tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False)
                json.dump(client_config, temp_creds_file)
                temp_creds_file.close()
                credentials_path = temp_creds_file.name
            else:
                credentials_path = str(credentials_file)
            
            try:
                flow = InstalledAppFlow.from_client_secrets_file(credentials_path, SCOPES)
                
                # Use provided port or find a free one
                if port:
                    oauth_port = port
                else:
                    oauth_port = find_free_port(8080, 20)
                    if oauth_port is None:
                        sys.stderr.write(
                            "ERROR: Could not find a free local port for OAuth callback "
                            "(tried ports 8080-8099 on localhost).\n"
                        )
                        if temp_creds_file:
                            os.unlink(temp_creds_file.name)
                        sys.exit(1)
                
                # Use the found port and report it
                redirect_uri = f"http://localhost:{oauth_port}/"
                sys.stderr.write(f"Using redirect URI: {redirect_uri}\n")
                sys.stderr.write("Make sure this URI is registered in your Google OAuth app settings.\n")
                
                creds = flow.run_local_server(port=oauth_port, open_browser=True)
                
                # Clean up temporary file if created
                if temp_creds_file:
                    os.unlink(temp_creds_file.name)
            except Exception as e:
                if temp_creds_file:
                    try:
                        os.unlink(temp_creds_file.name)
                    except:
                        pass
                error_msg = str(e)
                if "access_denied" in error_msg or "blocked" in error_msg.lower():
                    sys.stderr.write(f"ERROR: Authorization blocked. Possible causes:\n")
                    sys.stderr.write(f"  1. OAuth client is deleted or disabled in Google Cloud Console\n")
                    sys.stderr.write(f"  2. Google Calendar API is not enabled for this project\n")
                    sys.stderr.write(f"  3. Your Google account is not authorized for this OAuth client\n")
                    sys.stderr.write(f"  4. Redirect URI mismatch - ensure 'http://localhost' is authorized\n")
                    sys.stderr.write(f"  5. OAuth client is in testing mode and your account is not a test user\n")
                    sys.stderr.write(f"\nPlease check your Google Cloud Console settings.\n")
                else:
                    sys.stderr.write(f"ERROR: Authentication failed: {error_msg}\n")
                sys.exit(1)
        
        with open(token_file, 'w') as f:
            f.write(creds.to_json())
    
    # Save access token to config for QML to use
    config = {}
    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
        except:
            pass
    
    config['provider'] = 'google'
    config['access_token'] = creds.token
    config_file.parent.mkdir(parents=True, exist_ok=True)
    with open(config_file, 'w') as f:
        json.dump(config, f)
        f.flush()
        try:
            os.fsync(f.fileno())
        except (OSError, ValueError):
            pass
    
    # Fetch calendar list
    try:
        service = build('calendar', 'v3', credentials=creds)
        calendar_list = service.calendarList().list().execute()
        print(json.dumps(calendar_list, indent=None, separators=(',', ':')))
    except Exception as e:
        sys.stderr.write(f"ERROR: Failed to fetch calendar list: {e}\n")
        sys.exit(1)

def authenticate_nextcloud(server_url, client_id, client_secret, auth_endpoint=None, token_endpoint=None, port=None):
    """Run Nextcloud OAuth flow and save token"""
    if not REQUESTS_AVAILABLE:
        sys.stderr.write("ERROR: requests library not available. Install: pip3 install requests\n")
        sys.exit(1)
    
    # Debug: Log all input parameters
    sys.stderr.write(f"DEBUG: ===== Nextcloud Authentication Parameters =====\n")
    sys.stderr.write(f"DEBUG: Input server_url parameter: {server_url}\n")
    sys.stderr.write(f"DEBUG: Input auth_endpoint parameter: {auth_endpoint}\n")
    sys.stderr.write(f"DEBUG: Input token_endpoint parameter: {token_endpoint}\n")
    sys.stderr.write(f"DEBUG: Input client_id: {client_id[:8] + '***' if client_id and len(client_id) > 8 else '***'} (masked)\n")
    sys.stderr.write(f"DEBUG: Input client_secret: ***masked***\n")
    sys.stderr.write(f"DEBUG: Input port: {port}\n")
    
    # Extract base URL - prefer token_endpoint over auth_endpoint to avoid localhost confusion
    # This ensures we use the actual Nextcloud server URL from the user's input
    original_server_url = server_url
    if token_endpoint:
        parsed_token = urllib.parse.urlparse(token_endpoint)
        base_url = f"{parsed_token.scheme}://{parsed_token.netloc}"
        sys.stderr.write(f"DEBUG: Parsed token_endpoint - scheme: {parsed_token.scheme}, netloc: {parsed_token.netloc}\n")
        # Only use if it's not localhost (which would be the redirect URI)
        if 'localhost' not in base_url and '127.0.0.1' not in base_url:
            server_url = base_url.rstrip('/')
            sys.stderr.write(f"DEBUG: ✓ Using base URL from token_endpoint: {server_url}\n")
        else:
            sys.stderr.write(f"DEBUG: ✗ token_endpoint contains localhost, trying auth_endpoint...\n")
            # Token endpoint is localhost, try auth_endpoint instead
            if auth_endpoint:
                parsed_auth = urllib.parse.urlparse(auth_endpoint)
                base_url = f"{parsed_auth.scheme}://{parsed_auth.netloc}"
                sys.stderr.write(f"DEBUG: Parsed auth_endpoint - scheme: {parsed_auth.scheme}, netloc: {parsed_auth.netloc}\n")
                if 'localhost' not in base_url and '127.0.0.1' not in base_url:
                    server_url = base_url.rstrip('/')
                    sys.stderr.write(f"DEBUG: ✓ Using base URL from auth_endpoint: {server_url}\n")
                else:
                    sys.stderr.write(f"DEBUG: ✗ auth_endpoint also contains localhost\n")
                    sys.stderr.write(f"WARNING: Both endpoints contain localhost. Falling back to provided server_url parameter: {original_server_url}\n")
                    server_url = original_server_url.rstrip('/') if original_server_url else ""
            else:
                sys.stderr.write(f"DEBUG: No auth_endpoint provided, using server_url parameter: {original_server_url}\n")
                server_url = original_server_url.rstrip('/') if original_server_url else ""
    elif auth_endpoint:
        parsed_auth = urllib.parse.urlparse(auth_endpoint)
        base_url = f"{parsed_auth.scheme}://{parsed_auth.netloc}"
        sys.stderr.write(f"DEBUG: Parsed auth_endpoint - scheme: {parsed_auth.scheme}, netloc: {parsed_auth.netloc}\n")
        server_url = base_url.rstrip('/')
        sys.stderr.write(f"DEBUG: ✓ Using base URL from auth_endpoint: {server_url}\n")
    else:
        # Normalize server URL
        server_url = server_url.rstrip('/') if server_url else ""
        sys.stderr.write(f"DEBUG: No endpoints provided, using server_url parameter: {server_url}\n")
        auth_endpoint = f"{server_url}/index.php/apps/oauth2/authorize"
    
    sys.stderr.write(f"DEBUG: Final server_url: {server_url}\n")
    
    # Set default endpoints if not provided
    if not auth_endpoint:
        auth_endpoint = f"{server_url}/index.php/apps/oauth2/authorize"
    if not token_endpoint:
        token_endpoint = f"{server_url}/index.php/apps/oauth2/api/v1/token"
    
    sys.stderr.write(f"DEBUG: Final auth_endpoint: {auth_endpoint}\n")
    sys.stderr.write(f"DEBUG: Final token_endpoint: {token_endpoint}\n")
    sys.stderr.write(f"DEBUG: ============================================\n")
    
    # Use provided token endpoint or default
    if not token_endpoint:
        token_endpoint = f"{server_url}/index.php/apps/oauth2/api/v1/token"
    
    # Load existing token if available
    token_data = None
    if nextcloud_token_file.exists():
        try:
            with open(nextcloud_token_file, 'r') as f:
                token_data = json.load(f)
        except:
            pass
    
    # Check if token needs refresh
    access_token = None
    refresh_token = None
    
    if token_data:
        access_token = token_data.get('access_token')
        refresh_token = token_data.get('refresh_token')
        expires_at = token_data.get('expires_at', 0)
        
        # Try to refresh if expired
        if expires_at and expires_at < int(time.time()) and refresh_token:
            try:
                # Use provided token endpoint
                refresh_token_url = token_endpoint
                data = {
                    'grant_type': 'refresh_token',
                    'refresh_token': refresh_token,
                    'client_id': client_id,
                    'client_secret': client_secret
                }
                response = requests.post(refresh_token_url, data=data)
                if response.status_code == 200:
                    token_data = response.json()
                    access_token = token_data['access_token']
                    refresh_token = token_data.get('refresh_token', refresh_token)
                    token_data['expires_at'] = int(time.time()) + token_data.get('expires_in', 3600)
                    with open(nextcloud_token_file, 'w') as f:
                        json.dump(token_data, f)
                else:
                    # Mask any potential secrets in error response
                    error_text = response.text if hasattr(response, 'text') else str(response)
                    error_text = re.sub(r'["\']?access_token["\']?\s*[:=]\s*["\']?[^"\'\s]+["\']?', 'access_token=***masked***', error_text, flags=re.IGNORECASE)
                    error_text = re.sub(r'["\']?refresh_token["\']?\s*[:=]\s*["\']?[^"\'\s]+["\']?', 'refresh_token=***masked***', error_text, flags=re.IGNORECASE)
                    error_text = re.sub(r'["\']?client_secret["\']?\s*[:=]\s*["\']?[^"\'\s]+["\']?', 'client_secret=***masked***', error_text, flags=re.IGNORECASE)
                    sys.stderr.write(f"DEBUG: Token refresh failed (status {response.status_code}): {error_text[:200]}\n")
                    access_token = None
            except Exception as e:
                # Refresh failed, need to re-authenticate
                sys.stderr.write(f"DEBUG: Token refresh exception: {str(e)}\n")
                access_token = None
    
    # If no valid token, start OAuth flow
    if not access_token:
        # Use provided auth endpoint (Nextcloud instance URL, may contain query params)
        auth_url = auth_endpoint

        # Use provided port, or dynamically find a free local port for the callback server.
        # This avoids collisions when multiple helpers or other services
        # are using common ports.
        if port is not None:
            # Validate that the provided port is available
            try:
                port = int(port)
                with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                    s.bind(("localhost", port))
            except (ValueError, OSError) as e:
                sys.stderr.write(
                    f"ERROR: Provided port {port} is not available: {e}\n"
                )
                sys.exit(1)
        else:
            port = find_free_port(8080, 20)
            if port is None:
                sys.stderr.write(
                    "ERROR: Could not find a free local port for OAuth callback "
                    "(tried ports 8080-8099 on localhost).\n"
                )
                sys.exit(1)

        redirect_uri = f"http://localhost:{port}/oauth-callback"
        
        params = {
            'response_type': 'code',
            'client_id': client_id,
            'redirect_uri': redirect_uri,
            'scope': 'calendars'
        }
        
        # Parse the auth endpoint URL
        parsed_auth = urllib.parse.urlparse(auth_url)
        
        # Get base URL without query string
        auth_url_base = urllib.parse.urlunparse(
            (
                parsed_auth.scheme,
                parsed_auth.netloc,
                parsed_auth.path,
                parsed_auth.params,
                "",  # query will be set separately
                parsed_auth.fragment,
            )
        )
        
        # Merge existing query params (if any) with our required params
        # Our params always take precedence to ensure redirect_uri is set
        existing_query = urllib.parse.parse_qs(parsed_auth.query)
        merged = {}
        
        # First, add existing params (but skip redirect_uri if it exists, we'll override it)
        for k, v in existing_query.items():
            if k != 'redirect_uri':  # Always use our redirect_uri
                merged[k] = v[0] if isinstance(v, list) and len(v) > 0 else v
        
        # Then add our required params (this ensures redirect_uri is always set)
        merged.update(params)
        
        # Build query string
        query_string = urllib.parse.urlencode(merged)
        auth_url_with_params = f"{auth_url_base}?{query_string}"
        
        # Debug: print the final URL to stderr so user can verify
        sys.stderr.write(f"DEBUG: Final authorization URL: {auth_url_with_params}\n")
        
        # Start local server for callback
        global oauth_auth_code
        oauth_auth_code = None

        try:
            # Use reusable server to avoid 'address already in use' errors
            server = ReusableHTTPServer(('localhost', port), OAuthCallbackHandler)
            server.timeout = 1  # Short timeout for checking
        except OSError as e:
            sys.stderr.write(
                f"ERROR: Cannot start local callback server on {redirect_uri}: {e}\n"
            )
            sys.stderr.write(
                "Hint: Another KAgenda OAuth helper may still be running, or this port is blocked.\n"
            )
            sys.exit(1)
        
        sys.stderr.write(
            f"Using redirect URI: {redirect_uri}\n"
            "Make sure this URI is registered in your Nextcloud OAuth app settings (including port).\n"
        )
        print(f"Opening browser for Nextcloud authentication...", file=sys.stderr)
        webbrowser.open(auth_url_with_params)
        
        # Wait for callback
        auth_code = None
        try:
            for _ in range(300):  # Wait up to 5 minutes (300 seconds)
                server.handle_request()
                if oauth_auth_code:
                    auth_code = oauth_auth_code
                    break
                time.sleep(1)
        finally:
            try:
                server.server_close()
            except Exception:
                pass
        
        if not auth_code:
            sys.stderr.write("ERROR: Authentication timeout or cancelled\n")
            sys.exit(1)
        
        # Exchange code for token
        # Use provided token endpoint
        exchange_token_url = token_endpoint
        data = {
            'grant_type': 'authorization_code',
            'code': auth_code,
            'client_id': client_id,
            'client_secret': client_secret,
            'redirect_uri': redirect_uri
        }
        
        response = requests.post(exchange_token_url, data=data)
        if response.status_code != 200:
            # Mask any potential secrets in error response
            error_text = response.text
            # Remove any tokens or secrets that might be in the error
            error_text = re.sub(r'["\']?access_token["\']?\s*[:=]\s*["\']?[^"\'\s]+["\']?', 'access_token=***masked***', error_text, flags=re.IGNORECASE)
            error_text = re.sub(r'["\']?refresh_token["\']?\s*[:=]\s*["\']?[^"\'\s]+["\']?', 'refresh_token=***masked***', error_text, flags=re.IGNORECASE)
            error_text = re.sub(r'["\']?client_secret["\']?\s*[:=]\s*["\']?[^"\'\s]+["\']?', 'client_secret=***masked***', error_text, flags=re.IGNORECASE)
            sys.stderr.write(f"ERROR: Failed to get access token: {error_text}\n")
            sys.exit(1)
        
        token_data = response.json()
        token_data['expires_at'] = int(time.time()) + token_data.get('expires_in', 3600)
        
        with open(nextcloud_token_file, 'w') as f:
            json.dump(token_data, f)
        
        access_token = token_data['access_token']
        refresh_token = token_data.get('refresh_token')
    
    # Save access token to config for QML to use
    config = {}
    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
        except:
            pass
    
    config['provider'] = 'nextcloud'
    config['nextcloud_server'] = server_url
    config['access_token'] = access_token
    sys.stderr.write(f"DEBUG: Saving to config file - nextcloud_server: {server_url}\n")
    config_file.parent.mkdir(parents=True, exist_ok=True)
    with open(config_file, 'w') as f:
        json.dump(config, f)
        f.flush()
        try:
            os.fsync(f.fileno())
        except (OSError, ValueError):
            pass
    
    def extract_calendar_path_from_dav(cal, username):
        """Extract the full CalDAV path (username/calendar) from calendar data"""
        # Try to get the full DAV URL
        dav_url = None
        if isinstance(cal.get('dav'), dict):
            dav_url = cal.get('dav', {}).get('url', '')
        elif cal.get('url'):
            dav_url = cal.get('url')
        
        if dav_url:
            # Extract path from DAV URL: /remote.php/dav/calendars/{username}/{calendar}/
            parts = dav_url.split('/remote.php/dav/calendars/')
            if len(parts) > 1:
                path = parts[1].rstrip('/')
                return path  # Returns "username/calendar"
        
        # Fallback: construct from username and calendar name/ID
        if username:
            calendar_name = cal.get('id', '') or cal.get('calendarId', '') or cal.get('name', '')
            if calendar_name:
                return f"{username}/{calendar_name}"
        
        # Last resort: just return the calendar ID
        return cal.get('id', '') or cal.get('calendarId', '') or ''
    
    # Fetch calendar list using Nextcloud Calendar API or CalDAV
    try:
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Accept': 'application/json'
        }
        
        # Method 1: Try Nextcloud Calendar API v1 (most reliable)
        # Use the base URL extracted from auth_endpoint (the actual server URL the user provided)
        cal_api_url = f"{server_url}/apps/calendar/api/v1/calendars"
        sys.stderr.write(f"DEBUG: ===== Fetching Calendar List =====\n")
        sys.stderr.write(f"DEBUG: Using server_url: {server_url}\n")
        sys.stderr.write(f"DEBUG: Calendar API URL: {cal_api_url}\n")
        sys.stderr.write(f"DEBUG: Request headers: Authorization=Bearer ***masked***\n")
        response = requests.get(cal_api_url, headers=headers)
        sys.stderr.write(f"DEBUG: Calendar API response status: {response.status_code}\n")
        if response.status_code != 200:
            sys.stderr.write(f"DEBUG: Calendar API response text (first 200 chars): {response.text[:200]}\n")
        
        if response.status_code == 200:
            calendars_data = response.json()
            # Handle different response formats
            calendars = []
            if isinstance(calendars_data, dict):
                if 'ocs' in calendars_data and 'data' in calendars_data['ocs']:
                    calendars = calendars_data['ocs']['data']
                elif 'data' in calendars_data:
                    calendars = calendars_data['data']
            elif isinstance(calendars_data, list):
                calendars = calendars_data
            
            if calendars:
                # Get username for CalDAV path construction
                username = None
                user_info_url = f"{server_url}/ocs/v2.php/cloud/user"
                user_response = requests.get(user_info_url, headers=headers)
                if user_response.status_code == 200:
                    user_data = user_response.json()
                    if 'ocs' in user_data and 'data' in user_data['ocs']:
                        username = user_data['ocs']['data'].get('id')
                
                # Convert to Google Calendar API format for compatibility
                calendar_list_items = []
                for i, cal in enumerate(calendars):
                    # Extract calendar ID
                    cal_id = None
                    if username:
                        cal_id = extract_calendar_path_from_dav(cal, username)
                    if not cal_id:
                        if isinstance(cal.get('dav'), dict):
                            dav_url = cal.get('dav', {}).get('url', '')
                            if dav_url:
                                cal_id = dav_url.split('/')[-1]
                        if not cal_id and cal.get('url'):
                            cal_id = cal.get('url').split('/')[-1]
                        if not cal_id:
                            cal_id = cal.get('id', '') or cal.get('calendarId', '') or str(i)
                    
                    cal_summary = cal.get('displayname', '') or cal.get('name', '') or cal.get('title', '') or 'Unnamed Calendar'
                    
                    sys.stderr.write(f"DEBUG: Calendar {i}: summary='{cal_summary}', id='{cal_id}'\n")
                    sys.stderr.write(f"DEBUG: Calendar {i} raw data keys: {list(cal.keys())}\n")
                    
                    # Skip invalid calendar IDs (including single character invalid IDs)
                    if not cal_id or len(cal_id) < 1 or cal_id == '<' or cal_id == '>':
                        sys.stderr.write(f"WARNING: Calendar {i} has invalid ID '{cal_id}', skipping\n")
                        continue
                    
                    calendar_list_items.append({
                        'id': cal_id,
                        'summary': cal_summary,
                        'primary': i == 0
                    })
                
                # Sort calendars by summary (name) for consistent ordering, with primary first
                calendar_list_items.sort(key=lambda x: (not x.get('primary', False), x.get('summary', '').lower()))
                
                calendar_list = {'items': calendar_list_items}
                sys.stderr.write(f"DEBUG: Final calendar list with {len(calendar_list_items)} calendars (after filtering and sorting)\n")
                print(json.dumps(calendar_list, indent=None, separators=(',', ':')))
            else:
                raise Exception("No calendars found in API response")
        else:
            # Method 2: Try CalDAV PROPFIND to get calendar list
            sys.stderr.write(f"DEBUG: Calendar API returned {response.status_code}, trying CalDAV...\n")
            sys.stderr.write(f"DEBUG: Calendar API URL that failed: {cal_api_url}\n")
            sys.stderr.write(f"DEBUG: Server URL being used: {server_url}\n")
            
            # Get user info first to determine username
            # Use the base URL extracted from auth_endpoint
            user_info_url = f"{server_url}/ocs/v2.php/cloud/user"
            user_response = requests.get(user_info_url, headers=headers)
            
            username = None
            if user_response.status_code == 200:
                user_data = user_response.json()
                if 'ocs' in user_data and 'data' in user_data['ocs']:
                    username = user_data['ocs']['data'].get('id')
            
            if not username:
                # Try to get username from token or use a default
                # For OAuth, we might need to use the principal URL
                caldav_url = f"{server_url}/remote.php/dav/calendars/"
            else:
                caldav_url = f"{server_url}/remote.php/dav/calendars/{username}/"
            
            # Use CalDAV PROPFIND to list calendars
            propfind_headers = {
                'Authorization': f'Bearer {access_token}',
                'Depth': '1',
                'Content-Type': 'application/xml'
            }
            
            propfind_body = '''<?xml version="1.0" encoding="utf-8" ?>
<d:propfind xmlns:d="DAV:" xmlns:c="http://calendarserver.org/ns/" xmlns:cs="http://calendarserver.org/ns/">
  <d:prop>
    <d:displayname />
    <c:calendar-description />
    <d:resourcetype />
  </d:prop>
</d:propfind>'''
            
            caldav_response = requests.request('PROPFIND', caldav_url, headers=propfind_headers, data=propfind_body)
            
            if caldav_response.status_code in [207, 200]:  # 207 Multi-Status is normal for PROPFIND
                # Parse XML response (simplified - in production use proper XML parser)
                # Extract calendar paths and displaynames, matching them by position
                calendar_paths = re.findall(r'calendars/[^/]+/([^/]+)/', caldav_response.text)
                displaynames = re.findall(r'<d:displayname>([^<]+)</d:displayname>', caldav_response.text)
                
                if calendar_paths:
                    # Create a dictionary to track unique calendars by ID
                    # Use the first occurrence of each calendar ID to maintain consistency
                    seen_calendars = {}
                    calendar_items = []
                    
                    for i, cal_id in enumerate(calendar_paths):
                        # Skip invalid calendar IDs
                        if not cal_id or len(cal_id) < 1 or cal_id == '<' or cal_id == '>':
                            sys.stderr.write(f"WARNING: Skipping invalid calendar ID: '{cal_id}'\n")
                            continue
                        
                        # Only add if we haven't seen this ID before (use first occurrence)
                        if cal_id not in seen_calendars:
                            displayname = displaynames[i] if i < len(displaynames) else cal_id
                            # Clean up displayname - remove any invalid characters
                            displayname = displayname.strip()
                            if not displayname or displayname == '<' or displayname == '>':
                                displayname = cal_id
                            
                            calendar_items.append({
                                'id': cal_id,
                                'summary': displayname,
                                'primary': len(calendar_items) == 0  # First valid calendar is primary
                            })
                            seen_calendars[cal_id] = True
                    
                    # Sort calendars by summary (name) for consistent ordering
                    calendar_items.sort(key=lambda x: (not x.get('primary', False), x.get('summary', '').lower()))
                    
                    calendar_list = {'items': calendar_items}
                    sys.stderr.write(f"DEBUG: Final calendar list with {len(calendar_items)} calendars (after filtering and sorting)\n")
                    print(json.dumps(calendar_list, indent=None, separators=(',', ':')))
                else:
                    raise Exception("No calendars found in CalDAV response")
            else:
                raise Exception(f"CalDAV request failed with status {caldav_response.status_code}")
    except Exception as e:
        sys.stderr.write(f"ERROR: Failed to fetch calendar list: {e}\n")
        sys.stderr.write(f"DEBUG: ===== Error Summary =====\n")
        sys.stderr.write(f"DEBUG: Server URL used: {server_url}\n")
        # Log more details for debugging
        if 'response' in locals() and hasattr(response, 'status_code'):
            sys.stderr.write(f"DEBUG: Calendar API response status: {response.status_code}\n")
        if 'caldav_response' in locals() and hasattr(caldav_response, 'status_code'):
            sys.stderr.write(f"DEBUG: CalDAV response status: {caldav_response.status_code}\n")
        sys.stderr.write(f"DEBUG: =========================\n")
        # Return default calendar so user can still configure
        calendar_list = {'items': [{'id': 'default', 'summary': 'Default Calendar', 'primary': True}]}
        print(json.dumps(calendar_list, indent=None, separators=(',', ':')))

def authenticate():
    """Main authentication function - determines provider and calls appropriate function"""
    # Read provider from config or command line argument
    provider = None
    
    # Check command line arguments
    if len(sys.argv) > 1:
        provider = sys.argv[1].lower()
    
    # If not provided, check config file
    if not provider and config_file.exists():
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
                provider = config.get('provider', 'google')
        except:
            provider = 'google'
    
    # Default to Google if not specified
    if not provider:
        provider = 'google'
    
    if provider == 'google':
        # Check if credentials are provided as command line arguments
        # Format: python3 oauth-helper.py google [client_id] [client_secret] [port]
        client_id = None
        client_secret = None
        port = None
        
        if len(sys.argv) >= 3:
            client_id = sys.argv[2]
        if len(sys.argv) >= 4:
            client_secret = sys.argv[3]
        if len(sys.argv) >= 5:
            try:
                port = int(sys.argv[4])
            except ValueError:
                sys.stderr.write(f"WARNING: Invalid port number: {sys.argv[4]}, will find available port\n")
        
        authenticate_google(client_id=client_id, client_secret=client_secret, port=port)
    elif provider == 'nextcloud':
        # Check if endpoints and credentials are provided as command-line arguments
        auth_endpoint = None
        token_endpoint = None
        client_id = None
        client_secret = None
        port = None
        server_url = None
        
        if len(sys.argv) > 2:
            auth_endpoint = sys.argv[2]
        if len(sys.argv) > 3:
            token_endpoint = sys.argv[3]
        if len(sys.argv) > 4:
            client_id = sys.argv[4]
        if len(sys.argv) > 5:
            client_secret = sys.argv[5]
        if len(sys.argv) > 6:
            try:
                port = int(sys.argv[6])
            except ValueError:
                sys.stderr.write(f"WARNING: Invalid port number '{sys.argv[6]}', will scan for available port\n")
                port = None

        # If CLI credentials are provided, derive server URL from authorization endpoint
        if auth_endpoint and client_id and client_secret:
            parsed = urllib.parse.urlparse(auth_endpoint)
            server_url = f"{parsed.scheme}://{parsed.netloc}"
        else:
            # Fall back to credentials file
            if not nextcloud_credentials_file.exists():
                sys.stderr.write(f"ERROR: Place nextcloud_credentials.json in {nextcloud_credentials_file}\n")
                sys.stderr.write("Format: {\"server_url\": \"https://your-nextcloud.com\", \"client_id\": \"...\", \"client_secret\": \"...\"}\n")
                sys.exit(1)
            
            try:
                with open(nextcloud_credentials_file, 'r') as f:
                    nc_creds = json.load(f)
                    server_url = nc_creds.get('server_url')
                    if not client_id:
                        client_id = nc_creds.get('client_id')
                    if not client_secret:
                        client_secret = nc_creds.get('client_secret')
                    
                    if not all([server_url, client_id, client_secret]):
                        sys.stderr.write("ERROR: nextcloud_credentials.json must contain server_url, client_id, and client_secret\n")
                        sys.exit(1)
            except json.JSONDecodeError as e:
                sys.stderr.write(f"ERROR: nextcloud_credentials.json is not valid JSON: {e}\n")
                sys.exit(1)
            except Exception as e:
                sys.stderr.write(f"ERROR: Cannot read nextcloud_credentials.json: {e}\n")
                sys.exit(1)
        
        authenticate_nextcloud(server_url, client_id, client_secret, auth_endpoint, token_endpoint, port)
    else:
        sys.stderr.write(f"ERROR: Unknown provider: {provider}. Use 'google' or 'nextcloud'\n")
        sys.exit(1)

def fetch_caldav_events(server_url, calendar_id, access_token, time_min, time_max):
    """Fetch calendar events using CalDAV REPORT"""
    if not REQUESTS_AVAILABLE:
        sys.stderr.write("ERROR: requests library not available\n")
        sys.exit(1)
    
    # Format dates for CalDAV (YYYYMMDDTHHMMSSZ)
    def format_caldav_date(iso_date):
        from datetime import datetime
        # Handle ISO 8601 format with or without Z
        iso_date = iso_date.replace('Z', '+00:00')
        try:
            dt = datetime.fromisoformat(iso_date)
        except ValueError:
            # Fallback: parse manually
            iso_date = iso_date.replace('+00:00', 'Z')
            try:
                dt = datetime.strptime(iso_date, '%Y-%m-%dT%H:%M:%S.%fZ')
            except ValueError:
                dt = datetime.strptime(iso_date, '%Y-%m-%dT%H:%M:%SZ')
        return dt.strftime('%Y%m%dT%H%M%SZ')
    
    caldav_start = format_caldav_date(time_min)
    caldav_end = format_caldav_date(time_max)
    
    # CalDAV endpoint - calendar_id should be in format "username/calendar" or just "calendar"
    # If it doesn't contain "/", we need to get the username first
    if '/' not in calendar_id:
        sys.stderr.write(f"DEBUG: Calendar ID '{calendar_id}' doesn't include username, fetching username...\n")
        headers = {'Authorization': f'Bearer {access_token}', 'Accept': 'application/json'}
        user_info_url = f"{server_url}/ocs/v2.php/cloud/user"
        user_response = requests.get(user_info_url, headers=headers)
        if user_response.status_code == 200:
            user_data = user_response.json()
            if 'ocs' in user_data and 'data' in user_data['ocs']:
                username = user_data['ocs']['data'].get('id')
                calendar_id = f"{username}/{calendar_id}"
                sys.stderr.write(f"DEBUG: Constructed full calendar path: {calendar_id}\n")
    
    # CalDAV endpoint
    caldav_url = f"{server_url}/remote.php/dav/calendars/{calendar_id}/"
    if not caldav_url.endswith('/'):
        caldav_url += '/'
    
    sys.stderr.write(f"DEBUG: CalDAV URL: {caldav_url}\n")
    
    # CalDAV REPORT request body
    report_body = f'''<?xml version="1.0" encoding="utf-8" ?>
<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
<d:prop><d:getetag/><c:calendar-data/></d:prop>
<c:filter><c:comp-filter name="VCALENDAR">
<c:comp-filter name="VEVENT">
<c:time-range start="{caldav_start}" end="{caldav_end}"/>
</c:comp-filter></c:comp-filter></c:filter></c:calendar-query>'''
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/xml; charset=utf-8',
        'Depth': '1'
    }
    
    try:
        response = requests.request('REPORT', caldav_url, headers=headers, data=report_body)
        if response.status_code in [200, 207]:
            # Parse XML and extract iCalendar data
            import xml.etree.ElementTree as ET
            root = ET.fromstring(response.text)
            
            events = []
            # Find all calendar-data elements
            for calendar_data in root.iter():
                if calendar_data.tag.endswith('calendar-data') or 'calendar-data' in calendar_data.tag:
                    ical_content = calendar_data.text
                    if ical_content:
                        # Parse iCalendar format
                        current_event = {}
                        for line in ical_content.split('\n'):
                            line = line.strip()
                            if line.startswith('BEGIN:VEVENT'):
                                current_event = {}
                            elif line.startswith('DTSTART'):
                                current_event['start'] = line.split(':', 1)[1] if ':' in line else None
                            elif line.startswith('DTEND'):
                                current_event['end'] = line.split(':', 1)[1] if ':' in line else None
                            elif line.startswith('SUMMARY'):
                                current_event['summary'] = line.split(':', 1)[1] if ':' in line else 'No Title'
                            elif line.startswith('LOCATION'):
                                current_event['location'] = line.split(':', 1)[1] if ':' in line else ''
                            elif line.startswith('END:VEVENT'):
                                if current_event.get('start'):
                                    events.append(current_event)
                                current_event = {}
            
            # Convert to JSON format
            result = {'items': events}
            print(json.dumps(result, indent=None, separators=(',', ':')))
        else:
            sys.stderr.write(f"ERROR: CalDAV REPORT failed with status {response.status_code}\n")
            sys.stderr.write(f"Response: {response.text[:500]}\n")
            sys.exit(1)
    except Exception as e:
        sys.stderr.write(f"ERROR: CalDAV request failed: {e}\n")
        sys.exit(1)

if __name__ == '__main__':
    # Check if we're just finding a port
    if len(sys.argv) > 1 and sys.argv[1] == '--find-port':
        port = find_free_port(8080, 20)
        if port:
            print(port)
            sys.exit(0)
        else:
            sys.stderr.write("ERROR: Could not find a free port\n")
            sys.exit(1)
    elif len(sys.argv) > 1 and sys.argv[1] == '--fetch-events':
        # Fetch events via CalDAV
        if len(sys.argv) < 7:
            sys.stderr.write("ERROR: Usage: --fetch-events server_url calendar_id access_token time_min time_max\n")
            sys.exit(1)
        fetch_caldav_events(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6])
    else:
        authenticate()


