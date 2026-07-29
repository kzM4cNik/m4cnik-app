#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

SCHEME="M4cNikApp"
CONFIG="Release"
BUILD_DIR="$ROOT/build"
APP_PATH="$BUILD_DIR/Build/Products/Release-iphoneos/$SCHEME.app"
IPA_PATH="$ROOT/M4cNikApp.ipa"

echo "==> Xcode:"
xcodebuild -version

echo "==> Building $SCHEME (unsigned)..."
set +e
BUILD_LOG="$ROOT/xcodebuild.log"
xcodebuild \
  -project "$ROOT/M4cNikApp.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="-" \
  DEVELOPMENT_TEAM="" \
  clean build 2>&1 | tee "$BUILD_LOG"
BUILD_STATUS=${PIPESTATUS[0]}
set -e

if [[ "$BUILD_STATUS" -ne 0 ]]; then
  echo "==> xcodebuild failed. Last 40 lines:"
  tail -40 "$BUILD_LOG"
  exit "$BUILD_STATUS"
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: .app not found at $APP_PATH"
  find "$BUILD_DIR" -name "*.app" -maxdepth 10 || true
  exit 1
fi

echo "==> Packing IPA..."
rm -rf "$ROOT/Payload" "$IPA_PATH"
mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -qr "$IPA_PATH" Payload
rm -rf Payload

echo "Done: $IPA_PATH"
