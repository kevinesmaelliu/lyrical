#!/usr/bin/env bash
# Builds a Release .app via Xcode (proper icon, Info.plist, no Debug dylib).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Lyrics Anywhere"
DERIVED="$ROOT/build/DerivedData"
APP_DIR="$ROOT/$APP_NAME.app"

cd "$ROOT"

if [[ ! -f Config/Secrets.xcconfig ]]; then
  echo "error: Config/Secrets.xcconfig missing." >&2
  echo "  cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig" >&2
  echo "  Then set SPOTIFY_CLIENT_ID for release builds." >&2
  exit 1
fi

ICON_SOURCE="$ROOT/Resources/AppIconSource.png"
ICON_DIR="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset"
if [[ ! -f "$ICON_SOURCE" ]]; then
  echo "error: App icon source missing at $ICON_SOURCE" >&2
  exit 1
fi
if [[ ! -f "$ICON_DIR/icon_512.png" ]] || [[ "$ICON_SOURCE" -nt "$ICON_DIR/icon_512.png" ]]; then
  echo "Generating app icon…"
  swift "$ROOT/scripts/render-app-icon.swift" "$ICON_DIR"
fi

xcodebuild \
  -project Lyrical.xcodeproj \
  -scheme Lyrical \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  build

RELEASE_APP="$DERIVED/Build/Products/Release/$APP_NAME.app"
if [[ ! -d "$RELEASE_APP" ]]; then
  echo "error: Release build not found at $RELEASE_APP" >&2
  exit 1
fi

rm -rf "$APP_DIR"
cp -R "$RELEASE_APP" "$APP_DIR"

if [[ -f "$APP_DIR/Contents/MacOS/$APP_NAME.debug.dylib" ]]; then
  echo "error: Debug build artifact detected — use -configuration Release only." >&2
  exit 1
fi

echo "Built $APP_DIR (Release)"
echo "Open with: open \"$APP_DIR\""
