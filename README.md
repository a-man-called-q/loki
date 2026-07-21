# loki

The Odin monorepo tool — scaffold apps, share local packages, and pin vendor
dependencies from one CLI.

[![CI](https://github.com/a-man-called-q/loki/actions/workflows/ci.yml/badge.svg)](https://github.com/a-man-called-q/loki/actions/workflows/ci.yml)

## What it does

loki keeps a three-part project shape in sync, so an Odin monorepo stays one
`odin build` away from working no matter how many pieces it has:

- **`apps/`** — every binary in the repo, built the same way
- **`packages/local/`** — first-party packages shared across apps, discovered
  automatically by walking the tree
- **`packages/vendor/`** — third-party dependencies, pinned as git submodules

## Install

Requires the [Odin compiler](https://odin-lang.org/docs/install/)
(`dev-2026-07` or newer) on your `PATH`.

```bash
git clone https://github.com/a-man-called-q/loki.git
cd loki
./build.sh
```

Drop the resulting `bin/loki` on your `PATH`, then run `loki doctor` to
confirm the environment checks out.

## Quick start

```bash
loki new hearth
cd hearth
loki new app cli
loki new pkg utils
loki build
```

## Commands

| Command                       | Description                                            |
| ------------------------------ | ------------------------------------------------------ |
| `loki new <name>`              | Scaffold a new monorepo project                        |
| `loki new app <name>`          | Scaffold a new app in the current project               |
| `loki new pkg <name>`          | Scaffold a new local package in the current project     |
| `loki add <git-url> [name]`    | Add a third-party package as a git submodule            |
| `loki sync`                    | Init/update all vendor submodules                       |
| `loki run <app> [-- args]`     | Run an app                                              |
| `loki build [app]`             | Build an app, or every app if omitted                   |
| `loki test [target]`           | Test a package, or every local package if omitted       |
| `loki doctor`                  | Check that the environment is set up correctly          |

## Cross-compiling

`loki new` and `loki new app` accept a `--target=` flag; leave it off and
you'll get an interactive picker instead (space to toggle, enter to
confirm — press enter without picking anything to build for the host only):

```bash
loki new app cli --target=linux_amd64,windows_amd64
```

Supported ids:

| id               | platform                    | notes                              |
| ----------------- | ---------------------------- | ----------------------------------- |
| `darwin_arm64`     | macOS (Apple Silicon)         |                                     |
| `darwin_amd64`     | macOS (Intel)                 |                                     |
| `linux_amd64`      | Linux (x86_64)                |                                     |
| `linux_arm64`      | Linux (arm64)                 |                                     |
| `windows_amd64`    | Windows (x86_64)              |                                     |
| `web`              | Web (WASM)                    |                                     |
| `ios`              | iOS (device)                  | needs Xcode's command line tools    |
| `ios_simulator`    | iOS (simulator)               | needs Xcode's command line tools    |
| `android`          | Android (arm64)               | needs `ANDROID_NDK_HOME` set        |

Chosen targets are recorded per app in `loki.json`, and `loki build` builds
each one to `bin/<app>-<target-id>` instead of overwriting a single
`bin/<app>`. `loki doctor` checks whether the toolchain for each declared
target actually looks ready (Xcode CLT for iOS, `ANDROID_NDK_HOME` for
Android).

Note that Odin's own cross-linking support varies by target — `loki build`
treats "compiled but nothing was linked" as a failure rather than the silent
success `odin build` currently reports for those combinations.

## Project layout

```
.
├── apps/               binaries, one directory per app
├── packages/
│   ├── local/           first-party packages, shared across apps
│   └── vendor/          third-party packages, as git submodules
├── loki.json            project manifest
└── build.sh              bootstraps bin/loki itself
```

## Development

`bin/loki` builds itself, so the loop is:

```bash
./build.sh          # bootstrap bin/loki
./bin/loki doctor    # environment sanity check
./bin/loki test      # test every local package
./bin/loki build     # rebuild every app, including loki itself
```

CI runs this same sequence on Linux and macOS on every push and pull request
(see `.github/workflows/ci.yml`).
