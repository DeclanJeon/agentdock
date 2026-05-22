#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

INPUT_DIR="${1:-}"
OUTPUT_FILE="${2:-}"
if [[ -z "$INPUT_DIR" || -z "$OUTPUT_FILE" ]]; then
  echo "usage: $0 <native-screenshot-dir> <output-contact-sheet.png>" >&2
  exit 2
fi

python3 - "$INPUT_DIR" "$OUTPUT_FILE" <<'PY'
from pathlib import Path
import sys
try:
    from PIL import Image, ImageDraw
except Exception as exc:
    raise SystemExit(f'Pillow required for contact sheet generation: {exc}')

input_dir = Path(sys.argv[1])
output_file = Path(sys.argv[2])
required = ['live-normal', 'final-ready', 'dense-50-search-filter', 'live-click-filled']
images = []
for state in required:
    matches = sorted(input_dir.glob(f'{state}*.png'))
    if not matches:
        continue
    img = Image.open(matches[0]).convert('RGB')
    width, height = img.size
    # Review contact sheets crop common Linux desktop chrome while preserving
    # the native Tauri window contents. Raw evidence files remain untouched.
    left = 74 if width >= 1200 else 0
    top = 40 if height >= 800 else 0
    if left or top:
        img = img.crop((left, top, width, height))
    img.thumbnail((520, 320))
    images.append((state, img.copy()))
if not images:
    raise SystemExit(f'no review PNGs found in {input_dir}')

label_h = 28
pad = 12
cell_w = max(img.width for _, img in images) + pad * 2
cell_h = max(img.height for _, img in images) + label_h + pad * 2
cols = min(2, len(images))
rows = (len(images) + cols - 1) // cols
sheet = Image.new('RGB', (cell_w * cols, cell_h * rows), '#07101b')
draw = ImageDraw.Draw(sheet)
for index, (state, img) in enumerate(images):
    x = (index % cols) * cell_w + pad
    y = (index // cols) * cell_h + pad
    draw.text((x, y), state, fill='#d8e4f2')
    sheet.paste(img, (x, y + label_h))
output_file.parent.mkdir(parents=True, exist_ok=True)
sheet.save(output_file)
print(f'workspace native contact sheet ok: {output_file}')
PY
