# mini-play

Flutter 小游戏合集项目。

## Tech Stack

- Flutter 3.41.5 (pinned in `.fvmrc`)
- FVM for version management
- GitHub Actions for CI/CD

## Commands

```bash
# Local development
fvm flutter pub get          # Install dependencies
fvm flutter run -d chrome    # Run web locally
fvm flutter run              # Run on connected device
fvm flutter build web --release --base-href "/mini-play/"  # Build web
fvm flutter build apk --debug  # Build Android APK

# Release
git tag v<version>           # e.g. v0.1.0
git push origin v<version>   # Triggers full CI/CD pipeline
```

## CI/CD

Single workflow at `.github/workflows/ci.yml`:

| Trigger | Web (GitHub Pages) | Android APK (GitHub Release) |
|---------|-------------------|------------------------------|
| Push tag `v*` | Yes | Yes |
| Manual `workflow_dispatch` | Yes | No |

- Web: https://cecil-su.github.io/mini-play/
- Releases: https://github.com/cecil-su/mini-play/releases

## Project Structure

All games live in one app. Home page is a game list, tap to enter each game.

## Conventions

- Commit messages: conventional commits (`feat:`, `fix:`, `ci:`, `docs:`)
- Flutter version: always use `fvm flutter` locally, CI reads from `.fvmrc`
- Specs: `docs/superpowers/specs/`
- Plans: `docs/superpowers/plans/`
