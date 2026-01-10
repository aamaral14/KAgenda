# KAgenda

A KDE Plasma widget that displays calendar events and manages todo tasks from Google Calendar or Nextcloud Calendar.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/N4N41RQDPR)

## Introduction

KAgenda is a modern, lightweight widget for KDE Plasma 6 that brings your calendar events and todo tasks directly to your desktop. Stay organized and never miss an important event or task with a beautiful, integrated calendar and task view that shows your upcoming events and pending tasks at a glance.

**Features:**
- Support for Google Calendar and Nextcloud Calendar
- Support for Google Tasks (todos)
- Configurable event display range - choose how many days into the future to fetch and display events (1-365 days)
- Seamless OAuth 2.0 authentication
- Support for multiple calendars and task lists
- Automatic event and task refresh on startup
- Create, edit, complete, and delete todo tasks
- All configuration through the UI (no JSON files needed)
- Clean, native Plasma 6 design
- Easy configuration through the widget's settings interface
- Tabbed interface to switch between Events and Todos

## Compatibility

**This widget is designed for KDE Plasma 6.0 and later.** It is **not compatible** with Plasma 5 or earlier versions.

## Dependencies

Before using the widget, install the required Python packages:

### For Google Calendar and Tasks (On Debian/Ubuntu):
```bash
sudo apt install python3-google-auth-oauthlib python3-google-api-python-client python3-google-auth python3-google-auth-httplib2
```

### For Google Calendar and Tasks (On Fedora/RHEL):
```bash
sudo dnf install python3-google-auth-oauthlib python3-google-api-python-client python3-google-auth python3-google-auth-httplib2
```

### For Google Calendar and Tasks (On Arch Linux):
```bash
sudo pacman -S python-google-auth-oauthlib python-google-api-python-client python-google-auth python-google-auth-httplib2
```

### For Nextcloud Calendar:
```bash
# On Debian/Ubuntu/Fedora/RHEL/Arch Linux:
sudo apt install python3-requests  # or equivalent for your distribution
```

**Note:** These Python packages are required for OAuth authentication. The widget will not function without them.

## Installation

Install the widget from KDE Store or manually install the `.plasmoid` file.

After installation, restart Plasma shell:
```bash
killall plasmashell && kstart plasmashell
```

## Configuration

### Step 1: Add the Widget

1. **Add the widget to your desktop:**
   - Right-click on the desktop
   - Select "Add Widgets" (or press Alt+D)
   - Search for "KAgenda"
   - Click to add it

### Step 2: Configure Authentication

The widget supports two calendar providers: **Google Calendar** and **Nextcloud Calendar**. All configuration is done through the widget's settings interface - no JSON files needed!

#### Option A: Google Calendar

1. **Get Google Calendar API Credentials:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable the **Google Calendar API**:
     - Navigate to "APIs & Services" > "Library"
     - Search for "Google Calendar API"
     - Click "Enable"
   - Create OAuth 2.0 credentials:
     - Go to "APIs & Services" > "Credentials"
     - Click "Create Credentials" > "OAuth client ID"
     - Choose "Desktop app" as the application type
     - Copy the **Client ID** and **Client Secret**

2. **Configure in the Widget:**
   - Click on the widget to open the configuration modal
   - Click "Authenticate with Google"
   - Enter your **Client ID** and **Client Secret** in the fields
   - Copy the **Redirect URI** shown and add it to your Google OAuth app settings in Google Cloud Console
   - Click "Save" to start the authentication process
   - Your browser will open for OAuth authentication
   - After authentication, select your calendar from the list
   - Click "Save" to complete the setup

#### Option B: Nextcloud Calendar

1. **Get Nextcloud OAuth Credentials:**
   - Log in to your Nextcloud instance
   - Go to Settings > Security > OAuth
   - Create a new OAuth app
   - Copy the **Client ID** and **Client Secret**
   - Note your Nextcloud server URL

2. **Configure in the Widget:**
   - Click on the widget to open the configuration modal
   - Click "Authenticate with Nextcloud"
   - Enter your **Authorization Endpoint** (usually: `https://your-nextcloud.com/index.php/apps/oauth2/authorize`)
   - Enter your **Token Endpoint** (usually: `https://your-nextcloud.com/index.php/apps/oauth2/api/v1/token`)
   - Enter your **Client ID** and **Client Secret**
   - Copy the **Redirect URI** shown and add it to your Nextcloud OAuth app settings
   - Click "Save" to start the authentication process
   - Your browser will open for OAuth authentication
   - After authentication, select your calendar from the list
   - Click "Save" to complete the setup

### Step 3: Configure Event Display Range

- After authentication, you can configure how many days into the future events are fetched and displayed
- In the configuration dialog, you'll see the **Event display interval (days)** setting
- Adjust this value (1-365 days) to control how far ahead the widget looks for upcoming events
- For example, set it to 7 to see events for the next week, or 30 to see events for the next month
- The configuration is saved automatically when you click "Save" and persists across reboots

## Todo Tasks

KAgenda now includes full support for managing todo tasks alongside calendar events.

### Features:
- **View Tasks:** Switch to the "Todos" tab to see your task lists and tasks
- **Task Lists:** Select different task lists from the dropdown
- **Create Tasks:** Click "Add Todo" to create a new task
- **Complete Tasks:** Check/uncheck the checkbox to mark tasks as completed
- **Edit Tasks:** Click "Edit" to modify task details (currently toggles completion)
- **Delete Tasks:** Click "Delete" to remove tasks
- **Automatic Sync:** Tasks sync automatically with Google Tasks

### Notes:
- Todo functionality is currently only available for Google Calendar users
- Tasks are organized in task lists (similar to calendars)
- Completed tasks are visually dimmed but remain visible
- All task operations sync immediately with Google Tasks

## Troubleshooting

**Authentication fails (Google):**
- Verify your Client ID and Client Secret are correctly entered in the widget configuration
- Check that Google Calendar API is enabled in your Google Cloud project
- Verify your OAuth client is set to "Desktop app" type
- Ensure the Redirect URI shown in the widget is added to your Google OAuth app settings
- If in testing mode, ensure your Google account is added as a test user

**Authentication fails (Nextcloud):**
- Verify your Authorization and Token endpoints are correct
- Check that your Client ID and Client Secret are correctly entered
- Ensure the Redirect URI shown in the widget is added to your Nextcloud OAuth app settings
- Verify your Nextcloud server URL is accessible

**Calendar list is empty:**
- Click "Authenticate" again in the widget configuration to refresh the token
- Check that you have calendars in your calendar account
- Verify the access token is valid and not expired
- For Nextcloud, ensure the calendar app is installed and enabled

**Python dependencies missing:**
- Install the required Python packages (see [Dependencies](#dependencies))
- The OAuth helper will show an error message if packages are missing

**Configuration not persisting:**
- All configuration is saved automatically when you click "Save"
- Credentials, calendar selection, and event interval persist across reboots
- If settings are lost, re-enter them in the configuration dialog

## License

GPL (see LICENSE file for details)
