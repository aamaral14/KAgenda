#!/bin/bash
# Installation script for Gmail Calendar Widget

set -e

PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/com.github.kagenda"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing KAgenda..."

# Create plasmoid directory
mkdir -p "$PLASMOID_DIR"

# Copy files
echo "Copying files..."
cp "$SCRIPT_DIR/metadata.json" "$PLASMOID_DIR/"
mkdir -p "$PLASMOID_DIR/contents/ui"
mkdir -p "$PLASMOID_DIR/contents/config"
cp -r "$SCRIPT_DIR/ui"/*.qml "$PLASMOID_DIR/contents/ui/"
cp "$SCRIPT_DIR/contents/config/main.xml" "$PLASMOID_DIR/contents/config/" 2>/dev/null || echo "Note: main.xml not found, using direct cfg_ properties"
cp "$SCRIPT_DIR/oauth-helper.py" "$PLASMOID_DIR/"

# Make OAuth helper executable
chmod +x "$PLASMOID_DIR/oauth-helper.py"

echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Install all dependencies (all available via apt):"
echo "   sudo apt install python3-pyqt6 python3-pyqt6.qtqml python3-google-auth python3-google-auth-oauthlib python3-google-auth-httplib2 python3-googleapi"
echo "   (or python3-pyqt5 python3-pyqt5.qtquick for Plasma 5)"
echo ""
echo "   Note: All packages are available via apt - no pip needed!"
echo ""
echo "2. Get Google Calendar API credentials:"
echo "   - Go to https://console.cloud.google.com/"
echo "   - Create a new project or select existing"
echo "   - Enable Google Calendar API"
echo "   - Create OAuth 2.0 credentials (Desktop app)"
echo "   - Download credentials.json"
echo "   - Place it in: ~/.config/kagenda/credentials.json"
echo ""
echo "3. Restart Plasma shell to recognize the widget:"
echo "   killall plasmashell && kstart plasmashell"
echo ""
echo "4. Add the widget to your desktop:"
echo "   - Press Alt+D or right-click desktop -> Add Widgets"
echo "   - Search for 'KAgenda'"
echo "   - OR use: plasmoidviewer -a com.github.kagenda"
echo ""
echo "5. Configure the widget:"
echo "   - Click the configure button"
echo "   - Authenticate with Google"
echo "   - Select your calendar"

