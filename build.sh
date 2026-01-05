#!/bin/bash
# Build script for KAgenda Plasma Widget

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
PLASMOID_ID="com.github.kagenda"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"

echo "=========================================="
echo "Building KAgenda Plasma Widget"
echo "=========================================="

# Check if we need to build C++ plugin
HAS_CPP_PLUGIN=false
if [ -f "$SCRIPT_DIR/src/plugin.cpp" ] || [ -f "$SCRIPT_DIR/src/GmailBackend.cpp" ]; then
    HAS_CPP_PLUGIN=true
    echo "C++ plugin source files detected - will build plugin"
else
    echo "No C++ plugin source files found - using pure QML applet"
fi

# Build C++ plugin if source files exist
if [ "$HAS_CPP_PLUGIN" = true ]; then
    echo ""
    echo "Step 1: Building C++ plugin..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Configure with CMake
    if [ ! -f "$BUILD_DIR/CMakeCache.txt" ]; then
        echo "Configuring CMake..."
        cmake "$SCRIPT_DIR" -DCMAKE_BUILD_TYPE=Release
    else
        echo "CMake already configured, skipping..."
    fi
    
    # Build
    echo "Compiling..."
    cmake --build "$BUILD_DIR" --config Release -j$(nproc)
    
    if [ -f "$BUILD_DIR/kagendaplugin.so" ] || [ -f "$BUILD_DIR/kagendaplugin.so.1.0.0" ]; then
        echo "✓ C++ plugin built successfully"
        PLUGIN_SO=$(find "$BUILD_DIR" -name "kagendaplugin.so*" -type f | head -1)
        echo "  Plugin location: $PLUGIN_SO"
    else
        echo "⚠ Warning: Plugin .so file not found, but build completed"
    fi
else
    echo "Skipping C++ plugin build (no source files)"
fi

echo ""
echo "Step 2: Installing widget files..."

# Create plasmoid directory
mkdir -p "$PLASMOID_DIR"
mkdir -p "$PLASMOID_DIR/contents/ui"
mkdir -p "$PLASMOID_DIR/contents/config"
mkdir -p "$PLASMOID_DIR/contents/code" 2>/dev/null || true

# Copy metadata files
echo "  Copying metadata files..."
cp "$SCRIPT_DIR/metadata.json" "$PLASMOID_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/metadata.desktop" "$PLASMOID_DIR/" 2>/dev/null || true

# Copy QML files
echo "  Copying QML files..."
if [ -d "$SCRIPT_DIR/ui" ]; then
    cp "$SCRIPT_DIR/ui"/*.qml "$PLASMOID_DIR/contents/ui/" 2>/dev/null || true
fi

# Copy config files
if [ -d "$SCRIPT_DIR/contents/config" ]; then
    cp "$SCRIPT_DIR/contents/config"/* "$PLASMOID_DIR/contents/config/" 2>/dev/null || true
fi

# Copy C++ plugin if it exists
if [ "$HAS_CPP_PLUGIN" = true ] && [ -n "$PLUGIN_SO" ] && [ -f "$PLUGIN_SO" ]; then
    echo "  Copying C++ plugin..."
    mkdir -p "$PLASMOID_DIR/contents/code"
    cp "$PLUGIN_SO" "$PLASMOID_DIR/contents/code/" 2>/dev/null || true
    # Also copy without version suffix if needed
    if [[ "$PLUGIN_SO" == *.so.* ]]; then
        cp "$PLUGIN_SO" "$PLASMOID_DIR/contents/code/kagendaplugin.so" 2>/dev/null || true
    fi
fi

# Copy OAuth helper script
echo "  Copying OAuth helper..."
cp "$SCRIPT_DIR/oauth-helper.py" "$PLASMOID_DIR/" 2>/dev/null || true
chmod +x "$PLASMOID_DIR/oauth-helper.py" 2>/dev/null || true

# Copy helper scripts if they exist
if [ -f "$SCRIPT_DIR/run-oauth-helper.sh" ]; then
    cp "$SCRIPT_DIR/run-oauth-helper.sh" "$PLASMOID_DIR/" 2>/dev/null || true
    chmod +x "$PLASMOID_DIR/run-oauth-helper.sh" 2>/dev/null || true
fi

echo ""
echo "=========================================="
echo "✓ Build and installation complete!"
echo "=========================================="
echo ""
echo "Widget installed to: $PLASMOID_DIR"
echo ""
echo "Next steps:"
echo "1. Restart Plasma shell to recognize the widget:"
echo "   killall plasmashell && kstart plasmashell"
echo ""
echo "2. Add the widget to your desktop:"
echo "   - Right-click desktop -> Add Widgets"
echo "   - Search for 'KAgenda'"
echo "   - OR test with: plasmoidviewer -a $PLASMOID_ID"
echo ""
echo "3. Configure the widget (see README.md for details)"

