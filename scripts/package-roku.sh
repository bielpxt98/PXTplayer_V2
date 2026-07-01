#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/dist"
ZIP_FILE="$OUT_DIR/pxt-player-roku.zip"

mkdir -p "$OUT_DIR"
rm -f "$ZIP_FILE"

cd "$ROOT_DIR"
zip -r "$ZIP_FILE" manifest components source -x "*.DS_Store" -x "*/.git/*"

echo "$ZIP_FILE"
