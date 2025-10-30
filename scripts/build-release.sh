#!/usr/bin/env bash
set -euo pipefail

SCHEME="MACocr"
PROJECT="MACocr.xcodeproj"
CONFIGURATION="Release"
DERIVED_DATA_PATH="$(pwd)/.build"
ARTIFACTS_DIR="$(pwd)/artifacts"
APP_NAME="MACocr.app"
ARCHIVE_NAME="MACocr-Release.zip"

rm -rf "$DERIVED_DATA_PATH" "$ARTIFACTS_DIR"
mkdir -p "$DERIVED_DATA_PATH" "$ARTIFACTS_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -archivePath "$DERIVED_DATA_PATH/$SCHEME.xcarchive" \
  clean build

PRODUCT_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME"
if [ ! -d "$PRODUCT_PATH" ]; then
  echo "\n❌ Unable to locate built app at $PRODUCT_PATH" >&2
  exit 1
fi

cp -R "$PRODUCT_PATH" "$ARTIFACTS_DIR/"

pushd "$ARTIFACTS_DIR" >/dev/null
rm -f "$ARCHIVE_NAME"
ditto -c -k --sequesterRsrc --keepParent "$APP_NAME" "$ARCHIVE_NAME"
popd >/dev/null

echo "\n✅ Build artifacts available in $ARTIFACTS_DIR"
echo "   - App Bundle: $ARTIFACTS_DIR/$APP_NAME"
echo "   - Zip Archive: $ARTIFACTS_DIR/$ARCHIVE_NAME"
