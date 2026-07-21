---
title: "Cross-compile targets, CI/CD, and a real website"
date: 2026-07-21
version: "0.2.0"
description: "loki new/new app can target other platforms now, GitHub Actions builds and tests every push, and this site replaced a bare README."
---

## Cross-compile targets

`loki new` and `loki new app` now take a `--target=` flag, or fall into an
interactive picker (arrow keys and space, the same prompt style used
elsewhere in the CLI) when you leave it off inside a terminal. Chosen
targets land in `loki.json` per app, and `loki build` builds each one to
`bin/<app>-<target-id>` instead of overwriting a single binary.

Supported targets span desktop (macOS, Linux, Windows), `web` (WASM), and
iOS/Android — the latter two ride on Odin's `-subtarget:` flag rather than
being real `-target:` values of their own.

`loki doctor` was extended to match: it checks whether the toolchain for
each declared target actually looks ready — Xcode's command line tools for
iOS, `ANDROID_NDK_HOME` for Android — and flags builds that Odin otherwise
silently no-ops on for unsupported cross-target links.

## CI/CD

Every push and pull request now runs through GitHub Actions on Linux and
macOS: `build.sh` bootstraps `bin/loki`, then `loki doctor`, `loki build`,
and `loki test` run for real, using loki to build and test itself.

## This site

Replaced the bare README with an actual landing page, and moved it onto
Astro so a changelog could exist as more than a wall of commit messages.
