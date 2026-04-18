# CLAUDE.md

Project conventions and guidelines for AI-assisted development.

## Repository Overview

ESPHome firmware for a wall-mounted touch-screen alarm keypad
(Guition ESP32-S3-4848S040) wired to a Home Assistant `alarm_control_panel`.

## Key Files

- `esp32-hass-panel.yaml` — Main ESPHome configuration (reusable component)
- `secrets.yaml` — Secrets file (not committed, see README for format)

## Substitutions

The device `name` and `friendly_name` are ESPHome substitutions with sensible
defaults. Override them for each physical keypad deployment (see README).

## Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/).
All commit messages **must** follow the format:

```
<type>[optional scope]: <description>
```

Common types:

| Type | Purpose |
|------|---------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only changes |
| `chore` | Maintenance tasks, CI, tooling |
| `refactor` | Code change that neither fixes a bug nor adds a feature |

Examples:

```
feat: add night-arm button to keypad UI
fix: correct backlight fade during OTA
docs: update secrets.yaml format in README
chore: add yamllint CI workflow
```

## Release Process

Releases are managed automatically by
[release-please](https://github.com/googleapis/release-please).

- **release-please** watches the `main` branch for Conventional Commits.
- It opens (and keeps updated) a "Release PR" that bumps the version and
  updates the changelog.
- Merging the Release PR creates a GitHub Release and tag.
- Release type: `simple` (version tracked in a top-level `version.txt` if
  present, otherwise via tags).

**Do not** manually create tags or releases — let release-please handle it.

## CI

- **YAML Lint** (`ci.yaml`) — runs `yamllint -d relaxed` on every push and PR
  to `main`.
- **Release Please** (`release-please.yaml`) — runs on push to `main` to
  manage release PRs and tags.
