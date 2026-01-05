#!/bin/bash
# Installation script for KAgenda (legacy - use build.sh instead)
# This script is kept for backward compatibility
# For building and installing, use: ./build.sh

echo "Note: This script is for manual installation only."
echo "For a complete build and install, use: ./build.sh"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/com.github.kagenda"

echo "Installing KAgenda (manual installation)..."

# Create plasmoid directory
mkdir -p "$PLASMOID_DIR"
mkdir -p "$PLASMOID_DIR/contents/ui"
mkdir -p "$PLASMOID_DIR/contents/config"

# Copy files
echo "Copying files..."
cp "$SCRIPT_DIR/metadata.json" "$PLASMOID_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/metadata.desktop" "$PLASMOID_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/ui"/*.qml "$PLASMOID_DIR/contents/ui/" 2>/dev/null || true
cp "$SCRIPT_DIR/contents/config"/* "$PLASMOID_DIR/contents/config/" 2>/dev/null || true
cp "$SCRIPT_DIR/oauth-helper.py" "$PLASMOID_DIR/" 2>/dev/null || true

# Make OAuth helper executable
chmod +x "$PLASMOID_DIR/oauth-helper.py" 2>/dev/null || true

echo "Installation complete!"
echo ""
echo "Note: If you have a C++ plugin, use ./build.sh instead for a complete build."

