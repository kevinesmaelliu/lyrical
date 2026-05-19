# Lyrical

A minimal macOS menu bar app that shows **synced Spotify lyrics** in a clean floating window — inspired by [Lyricly](https://lyricly-website.vercel.app/).

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)

## Features

- Synced lyrics via [LRCLIB](https://lrclib.net/) (timed LRC when available)
- Spotify playback position polling (~400ms) for line highlighting
- Floating lyrics window with vibrancy blur
- Menu bar control: show/hide window, connect/disconnect, current line preview
- Adjustable font size and window opacity

## Setup

### 1. Spotify Developer App

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and create an app.
2. Copy the **Client ID**.
3. Under **Redirect URIs**, add:
   ```
   lyrical://spotify-callback
   ```

### 2. Configure Client ID

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# Edit Config/Secrets.xcconfig and set SPOTIFY_CLIENT_ID
```

`Secrets.xcconfig` is gitignored. The Xcode project reads it via `Config/Shared.xcconfig`.

### 3. Build & run (Xcode)

**Requirements:** Xcode 15+ on macOS 13+.

```bash
open Lyrical.xcodeproj
```

Press **⌘R** to run. The menu bar icon appears; the lyrics window opens automatically.

**Alternative (Swift Package Manager):**

```bash
swift build && swift run
```

### 4. Connect

1. Open **Settings** from the menu bar.
2. Click **Connect Spotify** and approve access (Client ID is pre-filled from `Secrets.xcconfig` when using Xcode).
3. Play a song in Spotify — lyrics appear in the floating window.

## Notes

- Spotify must be playing on your account (desktop or another device with active session).
- Lyrics come from LRCLIB community data — not every track has synced lines.
- This app uses the Spotify Web API; it does not modify the Spotify app.

## Project structure

```
Sources/Lyrical/
  LyricalApp.swift          # Menu bar + settings entry
  Services/                 # Spotify auth/player, LRCLIB, keychain
  Views/                    # Lyrics window, menu bar, settings
  ViewModels/               # Playback + sync state
```

## License

MIT
