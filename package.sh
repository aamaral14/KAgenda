#!/bin/bash
# Package script to create an installable archive of KAgenda

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="1.0.0"
PACKAGE_NAME="kagenda-${VERSION}"
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TEMP_DIR/$PACKAGE_NAME"

echo "=========================================="
echo "Packaging KAgenda for distribution"
echo "=========================================="

# Create package directory structure
mkdir -p "$PACKAGE_DIR"

echo "Step 1: Copying source files..."

# Copy essential files
cp "$SCRIPT_DIR/metadata.json" "$PACKAGE_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/metadata.desktop" "$PACKAGE_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/LICENSE" "$PACKAGE_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/README.md" "$PACKAGE_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/oauth-helper.py" "$PACKAGE_DIR/" 2>/dev/null || true

# Copy QML files
if [ -d "$SCRIPT_DIR/ui" ]; then
    mkdir -p "$PACKAGE_DIR/ui"
    cp "$SCRIPT_DIR/ui"/*.qml "$PACKAGE_DIR/ui/" 2>/dev/null || true
fi

# Copy config files
if [ -d "$SCRIPT_DIR/contents/config" ]; then
    mkdir -p "$PACKAGE_DIR/contents/config"
    cp "$SCRIPT_DIR/contents/config"/* "$PACKAGE_DIR/contents/config/" 2>/dev/null || true
fi

# Copy build and install scripts
cp "$SCRIPT_DIR/build.sh" "$PACKAGE_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/install.sh" "$PACKAGE_DIR/" 2>/dev/null || true
chmod +x "$PACKAGE_DIR/build.sh" 2>/dev/null || true
chmod +x "$PACKAGE_DIR/install.sh" 2>/dev/null || true

# Copy helper scripts
cp "$SCRIPT_DIR/run-oauth-helper.sh" "$PACKAGE_DIR/" 2>/dev/null || true
chmod +x "$PACKAGE_DIR/run-oauth-helper.sh" 2>/dev/null || true

# Copy C++ source files if they exist
if [ -d "$SCRIPT_DIR/src" ] && [ -n "$(ls -A $SCRIPT_DIR/src 2>/dev/null)" ]; then
    mkdir -p "$PACKAGE_DIR/src"
    cp "$SCRIPT_DIR/src"/* "$PACKAGE_DIR/src/" 2>/dev/null || true
fi

# Copy CMakeLists.txt if it exists
if [ -f "$SCRIPT_DIR/CMakeLists.txt" ]; then
    cp "$SCRIPT_DIR/CMakeLists.txt" "$PACKAGE_DIR/" 2>/dev/null || true
fi

echo "Step 2: Creating archive..."

# Create tarball
cd "$TEMP_DIR"
tar -czf "$SCRIPT_DIR/${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"

# Also create a zip file
zip -r "$SCRIPT_DIR/${PACKAGE_NAME}.zip" "$PACKAGE_NAME" > /dev/null 2>&1 || true

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "=========================================="
echo "✓ Package created successfully!"
echo "=========================================="
echo ""
echo "Created files:"
echo "  - ${PACKAGE_NAME}.tar.gz"
if [ -f "$SCRIPT_DIR/${PACKAGE_NAME}.zip" ]; then
    echo "  - ${PACKAGE_NAME}.zip"
fi
echo ""
echo "Package location: $SCRIPT_DIR"
echo ""
echo "To install from package:"
echo "  1. Extract: tar -xzf ${PACKAGE_NAME}.tar.gz"
echo "  2. Build: cd $PACKAGE_NAME && ./build.sh"

