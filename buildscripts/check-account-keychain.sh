#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
PRODUCTS="$PROJECT_ROOT/../build/Build/Products/Debug"
MODULE_MAPS="$PROJECT_ROOT/../build/Build/Intermediates.noindex/GeneratedModuleMaps"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/nnw-keychain.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
TEST_APP="$TEST_ROOT/KeychainCheck.app"
mkdir -p "$TEST_APP/Contents/MacOS"
cat > "$TEST_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.edmond.keychain-regression</string>
<key>CFBundleExecutable</key><string>probe</string>
<key>AppGroup</key><string>group.local.edmond.NetNewsWire-Evergreen-DEBUG</string>
<key>AppIdentifierPrefix</key><string></string>
<key>NNWCustomBuild</key><true/>
</dict></plist>
PLIST
swiftc buildscripts/check-account-keychain.swift -I "$PRODUCTS" -F "$PRODUCTS/PackageFrameworks" \
  -framework Secrets -Xcc "-fmodule-map-file=$MODULE_MAPS/RSDatabaseObjC.modulemap" \
  -Xcc "-fmodule-map-file=$MODULE_MAPS/RSCoreObjC.modulemap" \
  -Xlinker -rpath -Xlinker "$PRODUCTS/PackageFrameworks" -o "$TEST_APP/Contents/MacOS/probe"
codesign --force --sign - "$TEST_APP"
"$TEST_APP/Contents/MacOS/probe"
