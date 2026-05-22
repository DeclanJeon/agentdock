#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / 'src-ui' / 'assets' / 'source-tiles'
OUT_DIR = ROOT / 'src-ui' / 'assets' / 'room-maps'
OFFICE = Image.open(SOURCE_DIR / 'opengameart-office-space-tileset.png').convert('RGBA')
SMALL = Image.open(SOURCE_DIR / 'opengameart-office-8x8-tileset.png').convert('RGBA')
OUT_DIR.mkdir(parents=True, exist_ok=True)

SCALE = 2
W, H = 160, 90

# CC0 source crops from the downloaded OpenGameArt office tilesets.
CROPS = {
    'door': OFFICE.crop((80, 4, 114, 78)),
    'wide_window': OFFICE.crop((136, 6, 240, 58)),
    'cabinet': OFFICE.crop((372, 20, 434, 82)),
    'desk': OFFICE.crop((36, 82, 80, 111)),
    'cubicle': OFFICE.crop((0, 115, 42, 170)),
    'plant': SMALL.crop((88, 0, 120, 40)),
    'chair': SMALL.crop((0, 0, 40, 40)),
}

THEMES = {
    'command-office-map': {
        'wall': '#503321', 'floor1': '#3b251a', 'floor2': '#4a2e20', 'accent': '#f7d484',
        'props': [('wide_window', 34, 9, .72), ('cabinet', 105, 15, .7), ('desk', 55, 50, .9), ('plant', 128, 42, .8)],
        'rug': (48, 54, 112, 78), 'table': (55, 47, 107, 61), 'lines': 'vertical',
    },
    'mission-board-map': {
        'wall': '#244555', 'floor1': '#172a34', 'floor2': '#1d3540', 'accent': '#7ee7f2',
        'props': [('wide_window', 18, 8, .6), ('cabinet', 116, 10, .55), ('cubicle', 20, 46, .56), ('plant', 134, 46, .75)],
        'rug': (44, 48, 122, 74), 'table': (48, 28, 118, 42), 'lines': 'grid',
    },
    'product-bay-map': {
        'wall': '#4c2d54', 'floor1': '#2f1b37', 'floor2': '#3c2443', 'accent': '#f0abfc',
        'props': [('wide_window', 20, 9, .55), ('desk', 102, 49, .78), ('plant', 15, 46, .8), ('chair', 64, 48, .6)],
        'rug': (35, 50, 132, 79), 'table': (52, 24, 126, 39), 'lines': 'diagonal',
    },
    'engineering-bay-map': {
        'wall': '#213f5d', 'floor1': '#152b40', 'floor2': '#1b3650', 'accent': '#60a5fa',
        'props': [('wide_window', 11, 9, .5), ('cabinet', 121, 18, .55), ('desk', 22, 49, .78), ('desk', 88, 51, .78)],
        'rug': (22, 61, 139, 80), 'table': (18, 32, 144, 43), 'lines': 'tech',
    },
    'quality-bay-map': {
        'wall': '#285044', 'floor1': '#18352e', 'floor2': '#1f4338', 'accent': '#86efac',
        'props': [('wide_window', 22, 8, .5), ('cabinet', 112, 14, .55), ('desk', 36, 49, .7), ('plant', 128, 47, .78)],
        'rug': (32, 57, 128, 79), 'table': (34, 28, 132, 42), 'lines': 'checks',
    },
    'delivery-bay-map': {
        'wall': '#553a28', 'floor1': '#31241d', 'floor2': '#423024', 'accent': '#ffd166',
        'props': [('door', 111, 11, .52), ('cabinet', 14, 14, .5), ('desk', 63, 50, .75), ('plant', 126, 49, .7)],
        'rug': (42, 58, 119, 80), 'table': (36, 31, 123, 43), 'lines': 'route',
    },
}


def paste_fit(base: Image.Image, crop: Image.Image, x: int, y: int, scale: float) -> None:
    w = max(1, int(crop.width * scale))
    h = max(1, int(crop.height * scale))
    sprite = crop.resize((w, h), Image.Resampling.NEAREST)
    base.alpha_composite(sprite, (x, y))


def draw_floor(draw: ImageDraw.ImageDraw, theme: dict) -> None:
    draw.rectangle((0, 0, W, 22), fill=theme['wall'])
    draw.rectangle((0, 22, W, H), fill=theme['floor1'])
    for x in range(0, W, 8):
        draw.rectangle((x, 22, x + 4, H), fill=theme['floor2'])
    for y in range(28, H, 12):
        draw.line((0, y, W, y), fill=(0, 0, 0, 35), width=1)
    draw.rectangle((0, 21, W, 23), fill=(0, 0, 0, 70))
    rx1, ry1, rx2, ry2 = theme['rug']
    draw.rounded_rectangle((rx1, ry1, rx2, ry2), radius=3, fill=theme['floor2'], outline=theme['accent'], width=1)
    tx1, ty1, tx2, ty2 = theme['table']
    draw.rounded_rectangle((tx1, ty1, tx2, ty2), radius=2, fill=(6, 13, 20, 130), outline=theme['accent'], width=1)


def draw_theme_marks(draw: ImageDraw.ImageDraw, theme: dict) -> None:
    accent = theme['accent']
    mode = theme['lines']
    if mode == 'grid':
        for x in range(44, 121, 12): draw.line((x, 27, x, 43), fill=accent)
        for y in range(27, 44, 5): draw.line((44, y, 121, y), fill=accent)
    elif mode == 'diagonal':
        for x in range(45, 122, 9): draw.line((x, 38, x + 10, 25), fill=accent)
    elif mode == 'tech':
        for x in range(22, 142, 14):
            draw.rectangle((x, 33, x + 6, 39), outline=accent)
            draw.line((x + 6, 36, min(145, x + 13), 36), fill=accent)
    elif mode == 'checks':
        for x in range(42, 122, 16):
            draw.line((x, 34, x + 4, 39), fill=accent, width=1)
            draw.line((x + 4, 39, x + 12, 28), fill=accent, width=1)
    elif mode == 'route':
        points = [(40, 37), (61, 29), (84, 39), (109, 28), (124, 38)]
        draw.line(points, fill=accent, width=1)
        for x, y in points: draw.ellipse((x - 2, y - 2, x + 2, y + 2), fill=accent)
    else:
        for x in range(48, 112, 10): draw.line((x, 48, x, 61), fill=accent)


def make_room(name: str, theme: dict) -> None:
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, 'RGBA')
    draw_floor(draw, theme)
    draw_theme_marks(draw, theme)
    for key, x, y, scale in theme['props']:
        paste_fit(img, CROPS[key], x, y, scale)
    # subtle vignette and scan grid for consistent Visual Office integration.
    overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay, 'RGBA')
    od.rectangle((0, 0, W - 1, H - 1), outline=(255, 255, 255, 24))
    for x in range(0, W, 16): od.line((x, 0, x, H), fill=(255, 255, 255, 10))
    for y in range(0, H, 16): od.line((0, y, W, y), fill=(0, 0, 0, 16))
    img = Image.alpha_composite(img, overlay)
    # upscale with nearest to keep pixel art crisp.
    out = img.resize((W * SCALE, H * SCALE), Image.Resampling.NEAREST)
    out.save(OUT_DIR / f'{name}.png')

for name, theme in THEMES.items():
    make_room(name, theme)

print(f'generated {len(THEMES)} room maps in {OUT_DIR}')
