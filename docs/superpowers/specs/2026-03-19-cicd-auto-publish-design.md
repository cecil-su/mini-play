# CI/CD Auto-Publish Design

## Overview

Validate the GitHub Actions auto-publish pipeline for the `mini-play` Flutter project before developing actual games. Uses the Flutter default Counter App as the test payload.

## Goals

- Verify Web deployment to GitHub Pages works end-to-end
- Verify Android debug APK build and upload to GitHub Releases
- Establish CI/CD infrastructure that supports future game development
- Keep it simple — minimal config, easy to extend later

## Target Platforms

| Platform | Output | Destination |
|----------|--------|-------------|
| Web | Static site | GitHub Pages (`https://cecil-su.github.io/mini-play/`) |
| Android | Debug APK | GitHub Releases (tag-triggered only) |

## Project Structure

```
mini-play/
├── .github/
│   └── workflows/
│       └── ci.yml              # Single CI/CD workflow
├── .fvmrc                      # Flutter version lock
├── lib/
│   └── main.dart               # Flutter default Counter App
├── web/                        # Flutter web files
├── android/                    # Flutter android files
├── pubspec.yaml
└── README.md
```

Single Flutter project. All future games will live within this app (game list on the home page, tap to enter each game).

## Flutter Version Management

- `.fvmrc` in project root pins the Flutter version (e.g., `3.27.4`)
- CI uses `subosito/flutter-action` with the same version
- Locally, the user uses `fvm` (installed via scoop)

## CI/CD Workflow Design

### Trigger Conditions

- **Push tag `v*`** (e.g., `v0.1.0`) — full build + deploy + release
- **`workflow_dispatch`** (manual) — full build + deploy Web only (no GitHub Release)

### Job Structure

```
┌─────────────┐    ┌───────────────┐
│  build-web  │    │ build-android │    ← Run in parallel
│  (ubuntu)   │    │   (ubuntu)    │
└──────┬──────┘    └───────┬───────┘
       │                   │
       └─────────┬─────────┘
                 │
          ┌──────▼──────┐
          │   deploy    │    ← Waits for both builds
          │  (ubuntu)   │
          └─────────────┘
```

### build-web Job

1. Checkout code
2. Install Flutter via `subosito/flutter-action` (version matching `.fvmrc`)
3. Run `flutter build web --release --base-href "/mini-play/"`
4. Upload `build/web` as artifact

### build-android Job

1. Checkout code
2. Install Java 17 (`actions/setup-java`)
3. Install Flutter via `subosito/flutter-action`
4. Run `flutter build apk --debug`
5. Upload APK as artifact

### deploy Job

1. Download both artifacts
2. **Web**: Deploy to GitHub Pages via `peaceiris/actions-gh-pages` (publishes to `gh-pages` branch)
3. **APK** (tag-triggered only): Create GitHub Release with the APK attached
   - Release title matches tag name (e.g., `v0.1.0`)
   - Release body auto-generated from git log

## Release Strategy

| Trigger | Web Deploy | GitHub Release (APK) |
|---------|-----------|---------------------|
| Push tag `v*` | Yes | Yes |
| Manual `workflow_dispatch` | Yes | No |

## GitHub Pages Configuration

- Published from `gh-pages` branch
- `base-href` set to `/mini-play/` to match repository name
- Access URL: `https://cecil-su.github.io/mini-play/`

## Future Extension: Release Signing

When ready to switch from debug to release APK:

1. Generate a keystore file
2. Add GitHub Secrets: `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`
3. In `build-android` job: decode keystore from secret, configure `key.properties`
4. Change `flutter build apk --debug` to `flutter build apk --release`

No structural changes needed — just parameter updates in the existing workflow.
