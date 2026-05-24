#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Lyrics Anywhere"
DMG_NAME="Lyrics Anywhere.dmg"
STAGING="$ROOT/build/dmg-staging"

"$ROOT/scripts/build-app.sh"

APP_DIR="$ROOT/$APP_NAME.app"
rm -rf "$STAGING" "$ROOT/$DMG_NAME"
mkdir -p "$STAGING"
cp -R "$APP_DIR" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$ROOT/$DMG_NAME"
rm -rf "$STAGING"

echo "Created $ROOT/$DMG_NAME"
