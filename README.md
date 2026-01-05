# KAgenda

A KDE Plasma widget that displays Google Calendar events for the next 7 days.

## Compatibility

**This widget is designed for KDE Plasma 6.0 and later.** It uses:
- Qt6 libraries
- Plasma 6 APIs (`X-Plasma-API-Minimum-Version: 6.0`)
- Modern QML modules compatible with Plasma 6

The widget is **not compatible** with Plasma 5 or earlier versions.

## Table of Contents

- [Build Dependencies](#build-dependencies)
- [Installing Dependencies](#installing-dependencies)
- [Building the Project](#building-the-project)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)

## Build Dependencies

> **Note:** This project requires **KDE Plasma 6.0+** and **Qt6**. All dependencies listed below are for Plasma 6 / Qt6.

### Required System Packages

#### Build Tools
- **CMake** (3.31 or later)
- **C++ Compiler** (GCC with C++17 support)
- **Make** or **Ninja** (build system)

#### Qt6 Libraries
- **Qt6 Core** (`qt6-base-dev` or `libqt6core6-dev`)
- **Qt6 Qml** (`qt6-declarative-dev` or `libqt6qml6-dev`)
  - Includes Qt6 QmlIntegration (used for QML-C++ integration)
- **Qt6 Network** (`qt6-base-dev` includes this)
- **Qt6 NetworkAuth** (`qt6-networkauth-dev` or `libqt6networkauth6-dev`)

#### KDE Plasma Development Libraries
- **Plasma Framework** (`plasma-framework-dev` or `libplasma-dev`)
  - Provides: `org.kde.plasma.core`, `org.kde.plasma.components`, `org.kde.plasma.plasmoid`, `org.kde.plasma.plasma5support`, `org.kde.plasma.configuration`
  - **Required for Plasma 6.0+**
- **Kirigami** (`kirigami6-dev` or `kirigami2-dev`)
  - Provides: `org.kde.kirigami` (used for UI components)
  - **For Plasma 6:** Use `kirigami6-dev` if available in your distribution, otherwise `kirigami2-dev` may work
- **KCM Utils** (`kcmutils6-dev` or `kcmutils-dev`)
  - Provides: `org.kde.kcmutils` (used in config.qml)
  - **For Plasma 6:** Use `kcmutils6-dev` if available in your distribution, otherwise `kcmutils-dev` may work
- **Extra CMake Modules** (`extra-cmake-modules`)

#### Python Dependencies
- **Python 3** (3.6 or later)
- **python3-google-auth-oauthlib** (provides `google_auth_oauthlib`)
- **python3-google-api-python-client** (provides `googleapiclient`)
- **python3-google-auth** (provides `google.oauth2`, `google.auth.transport`)
- **python3-google-auth-httplib2** (transitive dependency, but recommended to install explicitly)

## Installing Dependencies

### On Debian/Ubuntu-based systems:

```bash
# Update package list
sudo apt update

# Install build tools
sudo apt install build-essential cmake

# Install Qt6 development packages
sudo apt install qt6-base-dev qt6-declarative-dev qt6-networkauth-dev

# Install KDE Plasma 6 development packages
# Note: Package names may vary by distribution - use Plasma 6 packages if available
sudo apt install plasma-framework-dev kirigami6-dev kcmutils6-dev extra-cmake-modules
# If Plasma 6-specific packages aren't available, try:
# sudo apt install plasma-framework-dev kirigami2-dev kcmutils-dev extra-cmake-modules

# Install Python dependencies
sudo apt install python3-google-auth-oauthlib python3-google-api-python-client python3-google-auth python3-google-auth-httplib2
```

### On Fedora/RHEL-based systems:

```bash
# Install build tools
sudo dnf install gcc-c++ cmake make

# Install Qt6 development packages
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtnetworkauth-devel

# Install KDE Plasma 6 development packages
# Note: Package names may vary by distribution - use Plasma 6 packages if available
sudo dnf install plasma-framework-devel kirigami6-devel kcmutils6-devel extra-cmake-modules
# If Plasma 6-specific packages aren't available, try:
# sudo dnf install plasma-framework-devel kirigami2-devel kcmutils-devel extra-cmake-modules

# Install Python dependencies
sudo dnf install python3-google-auth-oauthlib python3-google-api-python-client python3-google-auth python3-google-auth-httplib2
```

### On Arch Linux:

```bash
# Install build tools
sudo pacman -S base-devel cmake

# Install Qt6 development packages
sudo pacman -S qt6-base qt6-declarative qt6-networkauth

# Install KDE Plasma 6 development packages
# Note: Arch Linux typically uses unified package names for Plasma 6
sudo pacman -S plasma-framework kirigami2 kcmutils extra-cmake-modules

# Install Python dependencies
sudo pacman -S python-google-auth-oauthlib python-google-api-python-client python-google-auth python-google-auth-httplib2
```

## Building the Project

1. **Create a build directory:**
   ```bash
   mkdir build
   cd build
   ```

2. **Configure the project with CMake:**
   ```bash
   cmake ..
   ```
   
   Or for a specific build type:
   ```bash
   cmake -DCMAKE_BUILD_TYPE=Release ..
   ```

3. **Build the project:**
   ```bash
   make
   ```
   
   Or using multiple cores for faster compilation:
   ```bash
   make -j$(nproc)
   ```

4. **Install the plugin:**
   ```bash
   sudo make install
   ```
   
   Or use the provided install script:
   ```bash
   cd ..
   ./install.sh
   ```

## Installation

After building, you can install the widget using the provided script:

```bash
./install.sh
```

This will:
- Copy the widget files to `~/.local/share/plasma/plasmoids/com.github.gmailcalendar/`
- Make the OAuth helper script executable
- Set up the necessary directory structure

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

### Step 2: Authenticate with Google

You can authenticate in two ways:

#### Option A: Through the Widget UI (Recommended)

1. After adding the widget, click the **"Authenticate with Google"** button in the configuration dialog
2. The widget will automatically:
   - Execute the OAuth helper script
   - Open your browser for Google authentication
   - Save the access token automatically
   - Load your calendar list

#### Option B: Manual Authentication via Terminal

If you prefer to authenticate manually, run the OAuth helper script:

```bash
python3 ~/.local/share/plasma/plasmoids/com.github.gmailcalendar/oauth-helper.py
```

Or use the provided helper script from the project directory:

```bash
./run-oauth-helper.sh
```

This will:
- Open your browser for Google authentication
- Save the access token to `~/.config/kagenda/token.json`
- Display your available calendars as JSON output

### Step 3: Configure the Widget

1. **Restart Plasma shell** to recognize the widget:
   ```bash
   killall plasmashell && kstart plasmashell
   ```

2. **Add the widget to your desktop:**
   - Right-click on the desktop
   - Select "Add Widgets" (or press Alt+D)
   - Search for "KAgenda"
   - Click to add it
   
   Or test it with plasmoidviewer:
   ```bash
   plasmoidviewer -a com.github.gmailcalendar
   ```

3. **Configure the widget:**
   - Click the configure button on the widget (or right-click > Configure)
   - In the configuration dialog:
     - **Step 1:** Click "Authenticate with Google" button (this will open your browser and handle authentication automatically)
     - **Step 2:** After authentication completes, select your calendar from the dropdown
     - The access token is automatically saved - no manual copying needed!

### Configuration Files

The widget stores configuration in:
- **OAuth credentials:** `~/.config/kagenda/credentials.json`
- **Access token:** `~/.config/kagenda/token.json`
- **Widget config:** `~/.config/kagenda/config.json`
- **Plasma widget config:** Managed by Plasma (stored in Plasma's config system)

### How OAuth Authentication Works

The widget uses a Python-based OAuth helper (`oauth-helper.py`) that:

1. **When called from the widget UI:**
   - The QML code executes the Python script directly using Plasma's executable engine
   - The script path is: `~/.local/share/plasma/plasmoids/com.github.gmailcalendar/oauth-helper.py`
   - The script automatically opens your browser for authentication
   - After authentication, it saves the token and outputs calendar list JSON

2. **When called manually:**
   - You can run `./run-oauth-helper.sh` from the project directory
   - Or run the Python script directly: `python3 ~/.local/share/plasma/plasmoids/com.github.gmailcalendar/oauth-helper.py`
   - Both methods perform the same authentication flow

The authentication token is automatically saved to both:
- `~/.config/kagenda/token.json` (for the Python script to refresh tokens)
- `~/.config/kagenda/config.json` (for the widget to read the access token)
- Plasma's configuration system (for persistent storage)

## Usage

Once configured, the widget will:
- Display events from your selected Google Calendar
- Show events for the next 7 days
- Automatically refresh when the access token is valid
- Allow you to change the calendar selection through the configuration dialog

### Troubleshooting

**Widget doesn't appear:**
- Make sure you've restarted the Plasma shell
- Check that the widget is installed in `~/.local/share/plasma/plasmoids/com.github.gmailcalendar/`

**Authentication fails:**
- Verify `credentials.json` is in `~/.config/kagenda/`
- Ensure the credentials file has an `installed` key (not `web`)
- Check that Google Calendar API is enabled in your Google Cloud project
- Verify your OAuth client is set to "Desktop app" type
- If in testing mode, ensure your Google account is added as a test user

**Calendar list is empty:**
- Click "Authenticate with Google" again in the widget configuration to refresh the token
- Or manually run: `python3 ~/.local/share/plasma/plasmoids/com.github.gmailcalendar/oauth-helper.py`
- Check that you have calendars in your Google Calendar account
- Verify the access token is valid and not expired

**Build errors:**
- Ensure all dependencies are installed (see [Installing Dependencies](#installing-dependencies))
- Check that CMake can find Qt6 and KDE libraries
- Verify your compiler supports C++17

## License

GPL (see LICENSE file for details)
