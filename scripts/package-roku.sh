#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$root_dir/build"
zip_path="$build_dir/pxtplayer.zip"

if [[ ! -f "$root_dir/manifest" ]]; then
  echo "manifest not found at repository root" >&2
  exit 1
fi

mkdir -p "$build_dir"
rm -f "$zip_path"
(
  cd "$root_dir"
  zip -qr "$zip_path" manifest source components images
)

echo "Created $zip_path"
