#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$SCRIPT_DIR/LightingModels/LightingModels.xcodeproj"
BUILD_DIR="$SCRIPT_DIR/LightingModels/build"
INSTALL_DIR="$HOME/Library/Application Support/Plug-ins/ProPlug"

# Pass --debug to build a Debug (unoptimized) binary that preserves NSLog calls.
# Release uses -O -whole-module-optimization which strips NSLog from non-exported methods.
CONFIG=Release
if [[ "${1:-}" == "--debug" ]]; then
  CONFIG=Debug
  echo "=== Building DEBUG configuration (NSLog preserved) ==="
fi

echo "=== LightingModels FxPlug Build ($CONFIG) ==="
echo "Project: $PROJECT"
echo "Output:  $BUILD_DIR"
echo ""

COMMON_FLAGS=(
  -project  "$PROJECT"
  -configuration "$CONFIG"
  ARCHS=arm64
  CONFIGURATION_BUILD_DIR="$BUILD_DIR/$CONFIG"
  CODE_SIGN_IDENTITY="-"
  CODE_SIGNING_REQUIRED=NO
  CODE_SIGNING_ALLOWED=NO
)

echo "--- Building XPC service ---"
xcodebuild "${COMMON_FLAGS[@]}" -target LightingModelsXPC build

echo ""
echo "--- Building wrapper app ---"
xcodebuild "${COMMON_FLAGS[@]}" -target LightingModels build

XPC="$BUILD_DIR/$CONFIG/LightingModelsXPC.xpc"
APP="$BUILD_DIR/$CONFIG/LightingModels.app"

if [ ! -d "$APP" ]; then
  echo "=== Build FAILED — app bundle not found ==="
  exit 1
fi

# Embed the XPC bundle inside the wrapper app
XPC_DEST="$APP/Contents/XPCServices"
mkdir -p "$XPC_DEST"
if [ -d "$XPC" ]; then
  cp -R "$XPC" "$XPC_DEST/"
  echo "Embedded XPC: $XPC_DEST/LightingModelsXPC.xpc"
else
  echo "WARNING: XPC bundle not found at $XPC — skipping embed"
fi

echo ""
echo "=== Build succeeded ==="
echo "App bundle: $APP"
echo ""
echo "Installing to: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -R "$APP" "$INSTALL_DIR/"

# Register with PlugInKit so Motion/FCP can discover it.
# Must register the app AND the XPC — app registration alone sometimes misses it,
# and the XPC path is what pluginkit -m actually shows.
INSTALLED_APP="$INSTALL_DIR/LightingModels.app"
INSTALLED_XPC="$INSTALLED_APP/Contents/XPCServices/LightingModelsXPC.xpc"
pluginkit -a "$INSTALLED_APP" 2>/dev/null || true
pluginkit -a "$INSTALLED_XPC" 2>/dev/null && echo "Registered with PlugInKit" || echo "WARNING: pluginkit registration failed"
echo "Installed. Restart Motion or FCP to pick up the plugin."
