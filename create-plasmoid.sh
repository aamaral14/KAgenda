#!/bin/bash
# Script to create a .plasmoid package for KDE Store submission

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLASMOID_NAME="kagenda"
TEMP_DIR=$(mktemp -d)
PLASMOID_DIR="$TEMP_DIR/$PLASMOID_NAME"

echo "=========================================="
echo "Creating .plasmoid package for KDE Store"
echo "=========================================="

# Create package directory
mkdir -p "$PLASMOID_DIR"

echo "Step 1: Copying metadata files..."

# Copy metadata files (both formats for compatibility)
cp "$SCRIPT_DIR/metadata.json" "$PLASMOID_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/metadata.desktop" "$PLASMOID_DIR/" 2>/dev/null || true

echo "Step 2: Copying widget contents..."

# Create contents directory structure
mkdir -p "$PLASMOID_DIR/contents/ui"
mkdir -p "$PLASMOID_DIR/contents/config"
mkdir -p "$PLASMOID_DIR/contents/code" 2>/dev/null || true

# Copy QML files
if [ -d "$SCRIPT_DIR/ui" ]; then
    echo "  Copying QML files..."
    cp "$SCRIPT_DIR/ui"/*.qml "$PLASMOID_DIR/contents/ui/" 2>/dev/null || true
fi

# Copy config files
if [ -d "$SCRIPT_DIR/contents/config" ]; then
    echo "  Copying config files..."
    cp "$SCRIPT_DIR/contents/config"/* "$PLASMOID_DIR/contents/config/" 2>/dev/null || true
fi

# Copy C++ plugin if it exists (from build directory)
if [ -f "$SCRIPT_DIR/build/kagendaplugin.so" ] || [ -f "$SCRIPT_DIR/build/kagendaplugin.so.1.0.0" ]; then
    echo "  Copying C++ plugin..."
    PLUGIN_SO=$(find "$SCRIPT_DIR/build" -name "kagendaplugin.so*" -type f | head -1)
    if [ -n "$PLUGIN_SO" ] && [ -f "$PLUGIN_SO" ]; then
        cp "$PLUGIN_SO" "$PLASMOID_DIR/contents/code/" 2>/dev/null || true
        # Also copy without version suffix
        if [[ "$PLUGIN_SO" == *.so.* ]]; then
            cp "$PLUGIN_SO" "$PLASMOID_DIR/contents/code/kagendaplugin.so" 2>/dev/null || true
        fi
    fi
fi

echo "Step 3: Copying required scripts..."

# Copy OAuth helper script (required for widget functionality)
if [ -f "$SCRIPT_DIR/oauth-helper.py" ]; then
    echo "  Copying OAuth helper..."
    cp "$SCRIPT_DIR/oauth-helper.py" "$PLASMOID_DIR/" 2>/dev/null || true
    chmod +x "$PLASMOID_DIR/oauth-helper.py" 2>/dev/null || true
fi

# Copy README for reference (optional, but helpful)
if [ -f "$SCRIPT_DIR/README.md" ]; then
    echo "  Copying README..."
    cp "$SCRIPT_DIR/README.md" "$PLASMOID_DIR/" 2>/dev/null || true
fi

echo "Step 4: Verifying package structure..."

# Verify essential files exist
if [ ! -f "$PLASMOID_DIR/metadata.json" ] && [ ! -f "$PLASMOID_DIR/metadata.desktop" ]; then
    echo "ERROR: Missing metadata files!"
    exit 1
fi

if [ ! -d "$PLASMOID_DIR/contents/ui" ] || [ -z "$(ls -A $PLASMOID_DIR/contents/ui 2>/dev/null)" ]; then
    echo "ERROR: Missing QML files in contents/ui!"
    exit 1
fi

echo "  ✓ Package structure verified"

echo "Step 5: Creating .plasmoid archive..."

# Create .plasmoid file (it's just a zip file with .plasmoid extension)
cd "$TEMP_DIR"
zip -r "$SCRIPT_DIR/${PLASMOID_NAME}.plasmoid" "$PLASMOID_NAME" > /dev/null 2>&1

# Verify the archive was created
if [ ! -f "$SCRIPT_DIR/${PLASMOID_NAME}.plasmoid" ]; then
    echo "ERROR: Failed to create .plasmoid file!"
    exit 1
fi

# Get file size
FILE_SIZE=$(du -h "$SCRIPT_DIR/${PLASMOID_NAME}.plasmoid" | cut -f1)

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "=========================================="
echo "✓ .plasmoid package created successfully!"
echo "=========================================="
echo ""
echo "Package: ${PLASMOID_NAME}.plasmoid"
echo "Size: $FILE_SIZE"
echo "Location: $SCRIPT_DIR"
echo ""
echo "Package contents:"
echo "  - metadata.json/desktop"
echo "  - contents/ui/*.qml"
echo "  - contents/config/*"
if [ -f "$SCRIPT_DIR/build/kagendaplugin.so" ] || [ -f "$SCRIPT_DIR/build/kagendaplugin.so.1.0.0" ]; then
    echo "  - contents/code/kagendaplugin.so"
fi
echo "  - oauth-helper.py"
echo ""
echo "Next steps:"
echo "1. Review the package structure"
echo "2. Test the package locally (optional)"
echo "3. Prepare screenshots"
echo "4. Submit to KDE Store (see SUBMIT_TO_STORE.md)"
echo ""
echo "To test the package:"
echo "  unzip -l ${PLASMOID_NAME}.plasmoid"

