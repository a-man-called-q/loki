#!/usr/bin/env bash
# Tags a release from the newest changelog entry's `version:` frontmatter and
# pushes the tag, which triggers .github/workflows/release.yml to publish the
# GitHub Release (notes pulled from that same changelog entry).
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

changelog_dir="site/src/content/changelog"
latest=$(ls "$changelog_dir"/*.md | sort | tail -n1)
version=$(grep -m1 '^version:' "$latest" | sed -E 's/^version: *"?([^"]*)"?$/\1/')

if [ -z "$version" ]; then
  echo "error: $latest has no version field in its frontmatter" >&2
  exit 1
fi

tag="v$version"

if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree not clean — commit or stash first" >&2
  exit 1
fi

if git rev-parse "$tag" >/dev/null 2>&1; then
  echo "error: tag $tag already exists" >&2
  exit 1
fi

echo "==> tagging $tag (from $latest)"
git tag -a "$tag" -m "Release $tag"
git push origin "$tag"

echo "==> pushed $tag — release.yml will publish the GitHub Release"
