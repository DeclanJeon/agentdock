#!/usr/bin/env python3
"""Generate deterministic Tamagotchi-style GIF pets for AgentDock Visual Workspace."""
from __future__ import annotations

from pathlib import Path
import math

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "workspace-characters"
SIZE = 64
SCALE = 4
CANVAS = SIZE // SCALE

PALETTES = [
    ("mint", "#9ff3c4", "#2f855a", "#0f3b2e"),
    ("sky", "#93c5fd", "#2563eb", "#172554"),
    ("peach", "#fdba74", "#ea580c", "#431407"),
    ("rose", "#f9a8d4", "#db2777", "#500724"),
    ("violet", "#c4b5fd", "#7c3aed", "#2e1065"),
    ("lime", "#bef264", "#65a30d", "#1a2e05"),
    ("amber", "#fde68a", "#d97706", "#451a03"),
    ("cyan", "#67e8f9", "#0891b2", "#164e63"),
    ("slate", "#cbd5e1", "#475569", "#0f172a"),
    ("coral", "#fca5a5", "#dc2626", "#450a0a"),
]

SHAPES = ["round", "cat", "blob", "bunny", "robot"]


def px(draw: ImageDraw.ImageDraw, xy, fill: str) -> None:
    x0, y0, x1, y1 = xy
    draw.rectangle((x0, y0, x1, y1), fill=fill)


def draw_pet(index: int, frame: int) -> Image.Image:
    palette = PALETTES[(index - 1) % len(PALETTES)]
    shape = SHAPES[((index - 1) // len(PALETTES)) % len(SHAPES)]
    base, shade, ink = palette[1], palette[2], palette[3]
    img = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    bob = 1 if frame in (1, 2) else 0
    blink = frame == 2
    wag = -1 if frame % 2 == 0 else 1

    # soft shadow
    d.ellipse((4, 13, 12, 15), fill=(0, 0, 0, 55))

    # ears / accessories
    if shape == "cat":
        d.polygon([(4, 5 + bob), (6, 1 + bob), (8, 6 + bob)], fill=base, outline=ink)
        d.polygon([(10, 6 + bob), (12, 1 + bob), (13, 5 + bob)], fill=base, outline=ink)
    elif shape == "bunny":
        d.rounded_rectangle((4, 0 + bob, 6, 6 + bob), radius=1, fill=base, outline=ink)
        d.rounded_rectangle((10, 0 + bob, 12, 6 + bob), radius=1, fill=base, outline=ink)
    elif shape == "robot":
        d.line((8, 3 + bob, 8, 1 + bob), fill=ink)
        d.point((8, 0 + bob), fill="#fef08a")

    # body
    if shape == "robot":
        d.rounded_rectangle((4, 4 + bob, 12, 13 + bob), radius=2, fill=base, outline=ink)
        d.rectangle((6, 2 + bob, 10, 5 + bob), fill=shade, outline=ink)
    elif shape == "blob":
        d.ellipse((3, 3 + bob, 13, 14 + bob), fill=base, outline=ink)
        d.rectangle((4, 9 + bob, 12, 14 + bob), fill=base)
    else:
        d.rounded_rectangle((3, 4 + bob, 13, 14 + bob), radius=4, fill=base, outline=ink)

    # face
    eye_y = 8 + bob
    if blink:
        d.line((6, eye_y, 7, eye_y), fill=ink)
        d.line((10, eye_y, 11, eye_y), fill=ink)
    else:
        d.point((6, eye_y), fill=ink)
        d.point((10, eye_y), fill=ink)
    d.point((8, 10 + bob), fill=ink)
    if frame == 3:
        d.arc((6, 9 + bob, 10, 13 + bob), 10, 170, fill=ink)
    else:
        d.line((7, 11 + bob, 9, 11 + bob), fill=ink)

    # status/motion flourish
    d.point((13 + wag, 5), fill="#fef08a")
    d.point((2 - wag, 7), fill="#fef08a")
    d.line((12, 11 + bob, 15, 10 + wag + bob), fill=ink)  # tail/antenna motion

    return img.resize((SIZE, SIZE), Image.Resampling.NEAREST)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = []
    for idx in range(1, 51):
        frames = [draw_pet(idx, f) for f in range(4)]
        path = OUT / f"character-{idx:02d}.gif"
        frames[0].save(
            path,
            save_all=True,
            append_images=frames[1:],
            duration=[220, 180, 160, 240],
            loop=0,
            disposal=2,
            transparency=0,
        )
        manifest.append(f"character-{idx:02d}.gif")
    (OUT / "manifest.txt").write_text("\n".join(manifest) + "\n", encoding="utf-8")
    print(f"generated {len(manifest)} workspace character GIFs in {OUT}")


if __name__ == "__main__":
    main()
