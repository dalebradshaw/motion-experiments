#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$SCRIPT_DIR/LightingModels/LightingModels.xcodeproj"
BUILD_DIR="$SCRIPT_DIR/LightingModels/build"
INSTALL_DIR="$HOME/Library/Application Support/Plug-ins/ProPlug"

echo "=== LightingModels FxPlug Build ==="
echo "Project: $PROJECT"
echo "Output:  $BUILD_DIR"
echo ""

COMMON_FLAGS=(
  -project  "$PROJECT"
  -configuration Release
  ARCHS=arm64
  CONFIGURATION_BUILD_DIR="$BUILD_DIR/Release"
  CODE_SIGN_IDENTITY="-"
  CODE_SIGNING_REQUIRED=NO
  CODE_SIGNING_ALLOWED=NO
)

echo "--- Building XPC service ---"
xcodebuild "${COMMON_FLAGS[@]}" -target LightingModelsXPC build

echo ""
echo "--- Building wrapper app ---"
xcodebuild "${COMMON_FLAGS[@]}" -target LightingModels build

XPC="$BUILD_DIR/Release/LightingModelsXPC.xpc"
APP="$BUILD_DIR/Release/LightingModels.app"

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

# Register XPC service with PlugInKit so Motion/FCP can discover it
INSTALLED_XPC="$INSTALL_DIR/LightingModels.app/Contents/XPCServices/LightingModelsXPC.xpc"
pluginkit -a "$INSTALLED_XPC" 2>/dev/null && echo "Registered with PlugInKit" || echo "WARNING: pluginkit registration failed"
echo "Installed. Restart Motion or FCP to pick up the plugin."
