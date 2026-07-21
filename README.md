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
