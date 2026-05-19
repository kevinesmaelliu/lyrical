#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Lyrical"
BUILD_DIR="$ROOT/.build/release"
APP_DIR="$ROOT/$APP_NAME.app"

cd "$ROOT"
swift build -c release

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Info.plist" "$APP_DIR/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP_NAME" "$APP_DIR/Contents/Info.plist" 2>/dev/null || true

echo "Built $APP_DIR"
echo "Open with: open \"$APP_DIR\""
