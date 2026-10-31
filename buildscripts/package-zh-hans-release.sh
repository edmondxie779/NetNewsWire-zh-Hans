#!/bin/bash
# Build, sign and package a zh-Hans release: NetNewsWire 汉化版.zip plus a Sparkle appcast.xml.
# Used by .github/workflows/release-zh-hans.yml; can also run locally.
#
# Environment:
#   RELEASE_NUMBER          Increasing release counter, appended to the upstream build number (required).
#   SIGN_IDENTITY           Code signing identity (name or SHA-1). Default: NetNewsWire zh-Hans Signing.
#   SIGN_KEYCHAIN           Keychain holding the identity. Optional.
#   SPARKLE_ED_PRIVATE_KEY  EdDSA private key for update signing. Optional locally: falls back to the
#                           Keychain account netnewswire-zh-hans.
#   OUTPUT_DIR              Where the zip and appcast go. Default: ../release next to the repo.
set -euo pipefail

: "${RELEASE_NUMBER:?Set RELEASE_NUMBER}"
REPO_URL="https://github.com/edmondxie779/NetNewsWire-zh-Hans"
FEED_URL="$REPO_URL/releases/latest/download/appcast.xml"
SPARKLE_PUBLIC_KEY="WWJaNOCdzKLyYfWJzlLnv5+8ob0LIP4NCqYrvb5p21E="
APP_NAME="NetNewsWire 汉化版"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_ROOT="$(dirname "$PROJECT_ROOT")"
DERIVED_DATA="$OUTPUT_ROOT/build"
OUTPUT_DIR="${OUTPUT_DIR:-$OUTPUT_ROOT/release}"
SIGN_IDENTITY="${SIGN_IDENTITY:-NetNewsWire zh-Hans Signing}"
PRODUCT="$DERIVED_DATA/Build/Products/Debug/NetNewsWire.app"
SIGN_UPDATE="$DERIVED_DATA/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"

cd "$PROJECT_ROOT"
UPSTREAM_BUILD="$(sed -n 's/^CURRENT_PROJECT_VERSION = //p' xcconfig/common/NetNewsWire_version.xcconfig)"
MARKETING_VERSION="$(sed -n 's/^MARKETING_VERSION = //p' xcconfig/common/NetNewsWire_mac_target_common.xcconfig)"
BUILD_VERSION="$UPSTREAM_BUILD.$RELEASE_NUMBER"
MINIMUM_SYSTEM="$(sed -n 's/^MACOSX_DEPLOYMENT_TARGET = //p' xcconfig/NetNewsWire_project.xcconfig | head -1)"

# Debug configuration keeps the local identifiers and skips app group prompts that a
# non-Apple-signed build would trigger; optimization is turned on for speed.
bash buildscripts/updateSecrets.sh
xcodebuild -project NetNewsWire.xcodeproj -scheme NetNewsWire \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM= \
  ORGANIZATION_IDENTIFIER=local.edmond DEVELOPER_ENTITLEMENTS=-dev \
  SWIFT_OPTIMIZATION_LEVEL=-O SWIFT_COMPILATION_MODE=wholemodule GCC_OPTIMIZATION_LEVEL=s \
  build

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT
STAGED="$STAGING_DIR/$APP_NAME.app"
ditto "$PRODUCT" "$STAGED"

PLIST="$STAGED/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $APP_NAME" "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :NNWCustomBuild bool true' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :NNWCustomUpdates bool true' "$PLIST"
/usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $SPARKLE_PUBLIC_KEY" "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :SUEnableAutomaticChecks bool true' "$PLIST"
/usr/libexec/PlistBuddy -c "Set :SUFeedURL $FEED_URL" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :FeedURLForTestBuilds $FEED_URL" "$PLIST"
for extensionPlist in "$STAGED"/Contents/PlugIns/*.appex/Contents/Info.plist; do
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_VERSION" "$extensionPlist"
done
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_VERSION" "$PLIST"

KEYCHAIN_ARGS=()
if [ -n "${SIGN_KEYCHAIN:-}" ]; then
  KEYCHAIN_ARGS=(--keychain "$SIGN_KEYCHAIN")
fi
codesign --force --deep --preserve-metadata=entitlements "${KEYCHAIN_ARGS[@]}" --sign "$SIGN_IDENTITY" "$STAGED"
codesign --verify --deep --strict "$STAGED"

mkdir -p "$OUTPUT_DIR"
ZIP_NAME="NetNewsWire-zh-Hans-$MARKETING_VERSION-$BUILD_VERSION.zip"
ZIP="$OUTPUT_DIR/$ZIP_NAME"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$STAGED" "$ZIP"

if [ -n "${SPARKLE_ED_PRIVATE_KEY:-}" ]; then
  SIGNATURE_ATTRIBUTES="$(printf '%s' "$SPARKLE_ED_PRIVATE_KEY" | "$SIGN_UPDATE" --ed-key-file - "$ZIP")"
else
  SIGNATURE_ATTRIBUTES="$("$SIGN_UPDATE" --account netnewswire-zh-hans "$ZIP")"
fi

TAG="v$MARKETING_VERSION-zh.$RELEASE_NUMBER"
cat > "$OUTPUT_DIR/appcast.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>$APP_NAME</title>
    <link>$REPO_URL</link>
    <item>
      <title>$MARKETING_VERSION ($BUILD_VERSION)</title>
      <pubDate>$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')</pubDate>
      <sparkle:version>$BUILD_VERSION</sparkle:version>
      <sparkle:shortVersionString>$MARKETING_VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MINIMUM_SYSTEM</sparkle:minimumSystemVersion>
      <sparkle:fullReleaseNotesLink>$REPO_URL/releases/tag/$TAG</sparkle:fullReleaseNotesLink>
      <description><![CDATA[<p>同步上游 NetNewsWire $MARKETING_VERSION（构建 $UPSTREAM_BUILD）。完整说明见 <a href="$REPO_URL/releases/tag/$TAG">发布页面</a>。</p>]]></description>
      <enclosure url="$REPO_URL/releases/download/$TAG/$ZIP_NAME" type="application/octet-stream" $SIGNATURE_ATTRIBUTES />
    </item>
  </channel>
</rss>
EOF

echo "tag=$TAG"
echo "version=$MARKETING_VERSION ($BUILD_VERSION)"
echo "zip=$ZIP"
echo "appcast=$OUTPUT_DIR/appcast.xml"
