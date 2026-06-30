#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
ZIP_PATH="$BUILD_DIR/pxtplayer.zip"

fail() { echo "ERRO: $*" >&2; exit 1; }

cd "$ROOT_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

[[ -f manifest ]] || fail "manifest não encontrado"
[[ -d source ]] || fail "source/ não encontrado"
[[ -d components ]] || fail "components/ não encontrado"
[[ -d images ]] || fail "images/ não encontrado"

python3 - <<'PY'
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET
root = Path('.')
for xml in sorted((root / 'components').glob('*.xml')):
    try:
        ET.parse(xml)
    except ET.ParseError as exc:
        raise SystemExit(f'XML inválido em {xml}: {exc}')

existing = {str(p).replace('\\', '/') for p in root.rglob('*') if p.is_file()}
for path in sorted(root.glob('components/*')) + sorted(root.glob('source/*')):
    if path.is_file():
        text = path.read_text(encoding='utf-8')
        for ref in re.findall(r'pkg:/([^"\'\s<>]+)', text):
            if ref not in existing:
                raise SystemExit(f'Referência pkg:/ ausente: pkg:/{ref} em {path}')
PY

(
  cd "$ROOT_DIR"
  zip -q -r "$ZIP_PATH" manifest source components images \
    -x '*.DS_Store' -x '*/.DS_Store' -x '*.zip' -x 'build/*' -x '.git/*'
)

[[ -f "$ZIP_PATH" ]] || fail "ZIP não foi criado"
zipinfo -1 "$ZIP_PATH" | grep -qx 'manifest' || fail "manifest não está na raiz do ZIP"
zipinfo -1 "$ZIP_PATH" | grep -q '^source/' || fail "source/ não está no ZIP"
zipinfo -1 "$ZIP_PATH" | grep -q '^components/' || fail "components/ não está no ZIP"
zipinfo -1 "$ZIP_PATH" | grep -q '^images/' || fail "images/ não está no ZIP"
if zipinfo -1 "$ZIP_PATH" | grep -Eq '^(PXTplayer/|\.git/|build/)|\.zip$'; then
  fail "ZIP contém caminhos proibidos"
fi

echo "Sucesso: pacote Roku criado em $ZIP_PATH"
echo "Manifest validado na raiz do ZIP."
