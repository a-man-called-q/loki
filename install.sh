#!/usr/bin/env bash
# Installs loki by cloning the repo, building it with build.sh, and copying
# the resulting binary onto your PATH. Run directly:
#
#   curl -fsSL https://raw.githubusercontent.com/a-man-called-q/loki/main/install.sh | sh
#
set -euo pipefail

REPO_URL="https://github.com/a-man-called-q/loki.git"
SRC_DIR="${LOKI_SRC_DIR:-$HOME/.loki/src}"
BIN_DIR="${LOKI_BIN_DIR:-$HOME/.local/bin}"

info() { printf '\033[1;32m==>\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; exit 1; }

command -v git >/dev/null 2>&1 || fail "git not found on PATH — install it from https://git-scm.com/downloads (e.g. \`brew install git\` on macOS, \`apt install git\` on Debian/Ubuntu)"
command -v odin >/dev/null 2>&1 || fail "odin not found on PATH — install it from https://odin-lang.org/docs/install/"

# Piped through `curl | sh`, stdin is the script itself, not the keyboard —
# /dev/tty is the actual terminal, and still readable even then. Skip the
# prompt entirely if there's no tty (CI, non-interactive shells) or if
# LOKI_BIN_DIR was already set explicitly.
if [ -z "${LOKI_BIN_DIR:-}" ] && [ -r /dev/tty ]; then
  printf 'Install loki to [%s]: ' "$BIN_DIR" > /dev/tty
  if IFS= read -r reply < /dev/tty; then
    case "$reply" in
      "") ;;
      "~"|"~/"*) BIN_DIR="$HOME${reply#\~}" ;;
      *) BIN_DIR="$reply" ;;
    esac
  fi
fi

if [ -d "$SRC_DIR/.git" ]; then
  info "updating existing checkout in $SRC_DIR"
  git -C "$SRC_DIR" pull --ff-only
else
  info "cloning loki into $SRC_DIR"
  git clone --depth 1 "$REPO_URL" "$SRC_DIR"
fi

info "building loki"
(cd "$SRC_DIR" && ./build.sh)

mkdir -p "$BIN_DIR"
cp "$SRC_DIR/bin/loki" "$BIN_DIR/loki"
chmod +x "$BIN_DIR/loki"

info "installed to $BIN_DIR/loki"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    printf '\n\033[1;33mheads up:\033[0m %s is not on your PATH.\n' "$BIN_DIR"
    printf 'Add this to your shell profile:\n\n  export PATH="%s:$PATH"\n\n' "$BIN_DIR"
    ;;
esac

info "run 'loki doctor' to confirm the environment checks out"
