#!/bin/bash
# Build, sign, and install the custom build into /Applications. Never overwrites the official app.
#
# Signing: the keychain remembers “Always Allow” per code signature. An ad-hoc
# signature changes with every build, so macOS asks again after each rebuild.
# Create a self-signed code signing certificate once (Keychain Access →
# Certificate Assistant → Create a Certificate…, type “Code Signing”) named
# “NetNewsWire Local Signing”, or set NNW_SIGN_IDENTITY to another name.
#
# Only the installed copy stays registered with Launch Services; Xcode's
# unsigned build product carries the same extension identifiers.
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_ROOT="$(dirname "$PROJECT_ROOT")"
SIGN_IDENTITY="${NNW_SIGN_IDENTITY:-NetNewsWire Local Signing}"
APP_NAME="NetNewsWire 汉化版.app"
INSTALL_PATH="/Applications/$APP_NAME"
PRODUCT="$OUTPUT_ROOT/build/Build/Products/Debug/NetNewsWire.app"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

cd "$PROJECT_ROOT"
bash buildscripts/updateSecrets.sh
xcodebuild -project NetNewsWire.xcodeproj -scheme NetNewsWire \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath "$OUTPUT_ROOT/build" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM= \
  ORGANIZATION_IDENTIFIER=local.edmond DEVELOPER_ENTITLEMENTS=-dev build
"$LSREGISTER" -u "$PRODUCT" 2>/dev/null || true

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT
STAGED="$STAGING_DIR/$APP_NAME"
ditto "$PRODUCT" "$STAGED"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string NetNewsWire 汉化版' "$STAGED/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :NNWCustomBuild bool true' "$STAGED/Contents/Info.plist"
if security find-certificate -c "$SIGN_IDENTITY" >/dev/null 2>&1; then
  codesign --force --deep --sign "$SIGN_IDENTITY" "$STAGED"
else
  echo "warning: signing identity “$SIGN_IDENTITY” not found; using an ad-hoc signature." >&2
  echo "warning: macOS will ask for keychain access again after every rebuild." >&2
  codesign --force --deep --sign - "$STAGED"
fi
codesign --verify --deep --strict "$STAGED"
codesign -dr - "$STAGED" 2>&1 | tail -1

if pgrep -f "$INSTALL_PATH/Contents/MacOS/NetNewsWire" >/dev/null; then
  echo "NetNewsWire is running. Quit it to finish installing (waiting up to 10 minutes)."
  for _ in $(seq 1 300); do
    pgrep -f "$INSTALL_PATH/Contents/MacOS/NetNewsWire" >/dev/null || break
    sleep 2
  done
fi
if pgrep -f "$INSTALL_PATH/Contents/MacOS/NetNewsWire" >/dev/null; then
  echo "error: NetNewsWire is still running; the new build was not installed." >&2
  exit 1
fi

rm -rf "$INSTALL_PATH"
ditto "$STAGED" "$INSTALL_PATH"
"$LSREGISTER" -u "$STAGED" 2>/dev/null || true
"$LSREGISTER" -f "$INSTALL_PATH"
echo "Installed $INSTALL_PATH"
