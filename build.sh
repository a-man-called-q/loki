#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

mkdir -p bin

odin build apps/loki \
  -collection:local=packages/local \
  -collection:deps=packages/vendor \
  -out:bin/loki

echo "built bin/loki"
