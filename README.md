# KAgenda

A KDE Plasma widget that displays Google Calendar events for the next 7 days.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/N4N41RQDPR)

## Introduction

KAgenda is a modern, lightweight widget for KDE Plasma 6 that brings your Google Calendar directly to your desktop. Stay organized and never miss an important event with a beautiful, integrated calendar view that shows your upcoming events at a glance.

**Features:**
- Display Google Calendar events for the next 7 days
- Seamless OAuth 2.0 authentication
- Support for multiple calendars
- Automatic event refresh
- Clean, native Plasma 6 design
- Easy configuration through Plasma's settings interface

## Compatibility

**This widget is designed for KDE Plasma 6.0 and later.** It is **not compatible** with Plasma 5 or earlier versions.

## Dependencies

Before using the widget, install the required Python packages:

### On Debian/Ubuntu:
```bash
sudo apt install python3-google-auth-oauthlib python3-google-api-python-client python3-google-auth python3-google-auth-httplib2
```

### On Fedora/RHEL:
```bash
sudo dnf install python3-google-auth-oauthlib python3-google-api-python-client python3-google-auth python3-google-auth-httplib2
```

### On Arch Linux:
```bash
sudo pacman -S python-google-auth-oauthlib python-google-api-python-client python-google-auth python-google-auth-httplib2
```

**Note:** These Python packages are required for OAuth authentication. The widget will not function without them.

## Installation

Install the widget from KDE Store or manually install the `.plasmoid` file.

After installation, restart Plasma shell:
```bash
killall plasmashell && kstart plasmashell
```

## Configuration

### Step 1: Get Google Calendar API Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Google Calendar API**:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Google Calendar API"
   - Click "Enable"
4. Create OAuth 2.0 credentials:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth client ID"
   - Choose "Desktop app" as the application type
   - Download the credentials file
5. Place the credentials file:
   ```bash
   mkdir -p ~/.config/kagenda
   cp ~/Downloads/credentials.json ~/.config/kagenda/credentials.json
   ```

### Step 2: Add and Configure the Widget

1. **Add the widget to your desktop:**
   - Right-click on the desktop
   - Select "Add Widgets" (or press Alt+D)
   - Search for "KAgenda"
   - Click to add it

## Usage

Once configured, the widget will:
- Display events from your selected Google Calendar
- Show events for the next 7 days
- Automatically refresh when the access token is valid
- Allow you to change the calendar selection through the configuration dialog

## Troubleshooting

**Authentication fails:**
- Verify `credentials.json` is in `~/.config/kagenda/`
- Ensure the credentials file has an `installed` key (not `web`)
- Check that Google Calendar API is enabled in your Google Cloud project
- Verify your OAuth client is set to "Desktop app" type
- If in testing mode, ensure your Google account is added as a test user

**Calendar list is empty:**
- Click "Authenticate with Google" again in the widget configuration to refresh the token
- Check that you have calendars in your Google Calendar account
- Verify the access token is valid and not expired

**Python dependencies missing:**
- Install the required Python packages (see [Dependencies](#dependencies))
- The OAuth helper will show an error message if packages are missing

## License

GPL (see LICENSE file for details)
