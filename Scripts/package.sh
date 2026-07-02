#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-guard-package.XXXXXX")"
APP_BUNDLE="$STAGING_DIR/Codex 防误发.app"
ZIP_PATH="$DIST_DIR/Codex防误发.app.zip"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$DIST_DIR"

swift build -c release --disable-sandbox --package-path "$ROOT_DIR"

cp "$ROOT_DIR/Packaging/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$ROOT_DIR/.build/release/CodexSendGuard" "$APP_BUNDLE/Contents/MacOS/CodexSendGuard"
chmod 755 "$APP_BUNDLE/Contents/MacOS/CodexSendGuard"
strip -x "$APP_BUNDLE/Contents/MacOS/CodexSendGuard"

plutil -lint "$APP_BUNDLE/Contents/Info.plist"
codesign --force --sign - "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

COPYFILE_DISABLE=1 ditto -c -k --keepParent --norsrc --noextattr "$APP_BUNDLE" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

echo "Created $ZIP_PATH"
cat "$ZIP_PATH.sha256"
