#!/usr/bin/env python3
"""
Simple OAuth helper script for Google Calendar
This runs separately from the widget to handle OAuth flow
"""

import sys
import json
import os
from pathlib import Path

try:
    from google_auth_oauthlib.flow import InstalledAppFlow
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    from googleapiclient.discovery import build
except ImportError:
    sys.stderr.write("ERROR: Install required packages: sudo apt install python3-google-auth-oauthlib python3-google-api-python-client\n")
    sys.exit(1)

SCOPES = ['https://www.googleapis.com/auth/calendar.readonly']
config_dir = Path.home() / ".config" / "kagenda"
config_dir.mkdir(parents=True, exist_ok=True)
token_file = config_dir / "token.json"
credentials_file = config_dir / "credentials.json"
config_file = config_dir / "config.json"

def authenticate():
    """Run OAuth flow and save token"""
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
                # If refresh fails (e.g., token revoked, client deleted), re-authenticate
                # Don't write to stderr here as it will be shown as error in QML
                # Just remove the old token and re-authenticate silently
                if token_file.exists():
                    token_file.unlink()
                creds = None
        
        if not creds or not creds.valid:
            if not credentials_file.exists():
                sys.stderr.write(f"ERROR: Place credentials.json in {credentials_file}\n")
                sys.exit(1)
            
            # Load credentials file
            try:
                with open(credentials_file, 'r') as f:
                    client_config = json.load(f)
                    # Verify the credentials file structure
                    if 'installed' not in client_config:
                        sys.stderr.write(f"ERROR: credentials.json must have 'installed' key. Current keys: {list(client_config.keys())}\n")
                        sys.exit(1)
            except json.JSONDecodeError as e:
                sys.stderr.write(f"ERROR: credentials.json is not valid JSON: {e}\n")
                sys.exit(1)
            except Exception as e:
                sys.stderr.write(f"ERROR: Cannot read credentials.json: {e}\n")
                sys.exit(1)
            
            flow = InstalledAppFlow.from_client_secrets_file(str(credentials_file), SCOPES)
            # Run local server with automatic browser opening
            # port=0 means use any available port
            # The redirect_uri will be automatically set to http://localhost:PORT
            try:
                creds = flow.run_local_server(port=0, open_browser=True)
            except Exception as e:
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
    
    config['access_token'] = creds.token
    # Ensure the directory exists
    config_file.parent.mkdir(parents=True, exist_ok=True)
    import os
    with open(config_file, 'w') as f:
        json.dump(config, f)
        f.flush()  # Ensure it's written to disk
        try:
            os.fsync(f.fileno())  # Force write to disk
        except (OSError, ValueError):
            # If fsync fails (e.g., on some file systems), that's OK
            pass
    
    # Fetch calendar list using the authenticated credentials
    try:
        service = build('calendar', 'v3', credentials=creds)
        calendar_list = service.calendarList().list().execute()
        
        # Output only the calendar list as clean JSON
        print(json.dumps(calendar_list, indent=None, separators=(',', ':')))
    except Exception as e:
        sys.stderr.write(f"ERROR: Failed to fetch calendar list: {e}\n")
        sys.exit(1)

if __name__ == '__main__':
    authenticate()


