#!/usr/bin/env python3
"""Generate original humanoid virtual-pet adventure GIF sprites for AgentDock.

The designs intentionally avoid copying any existing franchise character. They use
broad genre cues only: tiny digital-pet proportions, monster-adventure energy,
heroic outfits, goggles, jackets, boots, tails, ears, small wings, and gadgets.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "workspace-characters-v2"
SHEET = ROOT / "assets" / "workspace-characters-v2-contact-sheet.png"
SIZE = 64
CANVAS = 32
SCALE = SIZE // CANVAS

SKIN = ["#ffd7a8", "#f2b887", "#e7a06b", "#d08a5b", "#c8e6ff", "#f6b4d8", "#b8f7d0", "#dac8ff", "#ffe58a", "#cdd7e6"]
HAIR = ["#182033", "#5b341f", "#f59e0b", "#e11d48", "#7c3aed", "#0891b2", "#16a34a", "#f8fafc", "#fb7185", "#111827"]
OUTFITS = [
    ("#2563eb", "#93c5fd", "#f97316"),
    ("#7c3aed", "#c4b5fd", "#22d3ee"),
    ("#dc2626", "#fca5a5", "#fde047"),
    ("#059669", "#86efac", "#60a5fa"),
    ("#d97706", "#fed7aa", "#a855f7"),
    ("#0f766e", "#5eead4", "#fb7185"),
    ("#475569", "#cbd5e1", "#f59e0b"),
    ("#be185d", "#f9a8d4", "#67e8f9"),
    ("#4338ca", "#a5b4fc", "#84cc16"),
    ("#164e63", "#67e8f9", "#facc15"),
]
INK = "#101827"
WHITE = "#f8fafc"
SHADOW = (0, 0, 0, 80)
ARCHETYPES = ["goggle-runner", "hood-scout", "wing-tech", "tail-rider", "horn-cadet", "lab-tamer", "mecha-kid", "star-caper", "bug-visor", "moon-hacker"]


def rect(d: ImageDraw.ImageDraw, xy, fill, outline=None):
    d.rectangle(xy, fill=fill, outline=outline)


def rounded(d: ImageDraw.ImageDraw, xy, r, fill, outline=None):
    d.rounded_rectangle(xy, radius=r, fill=fill, outline=outline)


def draw_sprite(index: int, frame: int) -> Image.Image:
    i = index - 1
    skin = SKIN[i % len(SKIN)]
    hair = HAIR[(i * 3) % len(HAIR)]
    suit, light, accent = OUTFITS[i % len(OUTFITS)]
    archetype = ARCHETYPES[i % len(ARCHETYPES)]
    variant = i // len(ARCHETYPES)
    bob = 1 if frame in (1, 2) else 0
    blink = frame == 2
    step = -1 if frame % 2 == 0 else 1
    glow = frame in (1, 3)

    img = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # grounding shadow
    d.ellipse((8, 27, 24, 30), fill=SHADOW)

    # creature/adventure appendages, all original silhouettes
    if archetype in {"tail-rider", "moon-hacker"}:
        d.line((22, 20 + bob, 28, 17 + bob + step, 29, 14 + bob), fill=INK, width=2)
        d.point((29, 13 + bob), fill=accent)
    if archetype in {"wing-tech", "star-caper"}:
        d.polygon([(8, 15 + bob), (2, 11 + bob + step), (6, 20 + bob)], fill=light, outline=INK)
        d.polygon([(24, 15 + bob), (30, 11 + bob - step), (26, 20 + bob)], fill=light, outline=INK)
    if archetype == "horn-cadet":
        d.polygon([(10, 7 + bob), (8, 2 + bob), (13, 7 + bob)], fill=accent, outline=INK)
        d.polygon([(22, 7 + bob), (24, 2 + bob), (19, 7 + bob)], fill=accent, outline=INK)
    if archetype == "bug-visor":
        d.line((13, 6 + bob, 10, 2 + bob), fill=INK, width=1)
        d.line((19, 6 + bob, 22, 2 + bob), fill=INK, width=1)
        d.point((10, 2 + bob), fill=accent)
        d.point((22, 2 + bob), fill=accent)

    # legs and boots
    rect(d, (11, 22 + bob, 14, 28 + bob), suit, INK)
    rect(d, (18, 22 + bob, 21, 28 + bob), suit, INK)
    rect(d, (9 + step, 27 + bob, 14, 30 + bob), accent, INK)
    rect(d, (18, 27 + bob, 23 - step, 30 + bob), accent, INK)

    # torso/jacket silhouette
    if archetype == "hood-scout":
        rounded(d, (9, 12 + bob, 23, 24 + bob), 4, suit, INK)
        rounded(d, (11, 14 + bob, 21, 24 + bob), 2, light, None)
    elif archetype == "lab-tamer":
        rounded(d, (9, 13 + bob, 23, 25 + bob), 2, WHITE, INK)
        rect(d, (12, 14 + bob, 20, 24 + bob), suit, None)
    elif archetype == "mecha-kid":
        rounded(d, (9, 13 + bob, 23, 24 + bob), 2, "#334155", INK)
        rect(d, (12, 15 + bob, 20, 20 + bob), light, INK)
        d.point((16, 17 + bob), fill=accent if glow else INK)
    else:
        rounded(d, (9, 13 + bob, 23, 25 + bob), 3, suit, INK)
        rect(d, (14, 13 + bob, 18, 24 + bob), light, None)

    # arms with animated pose
    rect(d, (6, 15 + bob, 10, 22 + bob + step), skin, INK)
    rect(d, (22, 15 + bob, 26, 22 + bob - step), skin, INK)
    rect(d, (5, 21 + bob + step, 9, 24 + bob + step), accent, INK)
    rect(d, (23, 21 + bob - step, 27, 24 + bob - step), accent, INK)

    # neck and head
    rect(d, (14, 11 + bob, 18, 14 + bob), skin, None)
    if archetype == "hood-scout":
        rounded(d, (8, 5 + bob, 24, 18 + bob), 6, suit, INK)
        rounded(d, (10, 7 + bob, 22, 18 + bob), 5, skin, None)
    elif archetype == "mecha-kid":
        rounded(d, (9, 5 + bob, 23, 18 + bob), 3, "#94a3b8", INK)
        rect(d, (11, 8 + bob, 21, 14 + bob), skin, INK)
    else:
        rounded(d, (9, 5 + bob, 23, 18 + bob), 5, skin, INK)

    # hair/hat variations
    if archetype == "goggle-runner":
        d.polygon([(9, 8 + bob), (12, 3 + bob), (21, 5 + bob), (24, 9 + bob), (20, 7 + bob), (16, 9 + bob), (12, 7 + bob)], fill=hair, outline=INK)
        rect(d, (10, 6 + bob, 14, 9 + bob), "#7dd3fc", INK)
        rect(d, (18, 6 + bob, 22, 9 + bob), "#7dd3fc", INK)
        rect(d, (14, 7 + bob, 18, 8 + bob), accent, None)
    elif archetype == "star-caper":
        d.polygon([(8, 8 + bob), (16, 2 + bob), (24, 8 + bob), (20, 7 + bob), (18, 10 + bob), (12, 8 + bob)], fill=hair, outline=INK)
        d.point((25, 5 + bob), fill=accent if glow else light)
    elif archetype == "moon-hacker":
        d.arc((7, 2 + bob, 23, 14 + bob), 190, 350, fill=accent, width=2)
        rect(d, (10, 6 + bob, 23, 10 + bob), hair, INK)
    elif archetype == "lab-tamer":
        rect(d, (9, 5 + bob, 23, 8 + bob), hair, INK)
        rect(d, (20, 4 + bob, 25, 7 + bob), accent, INK)
    else:
        d.polygon([(9, 8 + bob), (12, 4 + bob), (18, 3 + bob), (23, 8 + bob), (19, 7 + bob), (16, 9 + bob), (12, 8 + bob)], fill=hair, outline=INK)

    # ears / digital companion cues
    if archetype in {"tail-rider", "wing-tech"}:
        d.polygon([(9, 8 + bob), (6, 5 + bob), (8, 12 + bob)], fill=skin, outline=INK)
        d.polygon([(23, 8 + bob), (26, 5 + bob), (24, 12 + bob)], fill=skin, outline=INK)

    # eyes and face
    eye_y = 12 + bob
    if blink:
        d.line((13, eye_y, 14, eye_y), fill=INK)
        d.line((19, eye_y, 20, eye_y), fill=INK)
    else:
        rect(d, (13, eye_y - 1, 14, eye_y), INK)
        rect(d, (19, eye_y - 1, 20, eye_y), INK)
        d.point((14, eye_y - 1), fill=WHITE)
        d.point((20, eye_y - 1), fill=WHITE)
    if variant % 2 == 0:
        d.line((15, 16 + bob, 18, 16 + bob), fill=INK)
    else:
        d.arc((14, 14 + bob, 19, 18 + bob), 20, 160, fill=INK)

    # accessories to make the 50 silhouettes distinct
    if variant == 1:
        rect(d, (4, 10 + bob, 7, 17 + bob), accent, INK)  # side badge
    elif variant == 2:
        d.line((7, 25 + bob, 25, 12 + bob), fill=accent, width=1)  # diagonal strap
    elif variant == 3:
        rect(d, (24, 13 + bob, 29, 18 + bob), light, INK)  # shoulder gadget
        d.point((27, 15 + bob), fill=accent if glow else INK)
    elif variant == 4:
        d.arc((6, 4 + bob, 26, 18 + bob), 210, 330, fill=accent, width=1)  # headset band
        rect(d, (5, 11 + bob, 8, 15 + bob), accent, INK)
        rect(d, (24, 11 + bob, 27, 15 + bob), accent, INK)

    # digital sparkles, not franchise-specific
    d.point((4 + step, 8), fill=accent)
    d.point((27 - step, 7), fill=light)
    if glow:
        d.point((29, 20), fill=accent)
        d.point((3, 22), fill=light)

    return img.resize((SIZE, SIZE), Image.Resampling.NEAREST)


def make_contact_sheet(paths: list[Path]) -> None:
    cols = 10
    cell = 80
    rows = (len(paths) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * cell), "#071321")
    d = ImageDraw.Draw(sheet)
    for idx, path in enumerate(paths):
        gif = Image.open(path)
        gif.seek(0)
        x = (idx % cols) * cell
        y = (idx // cols) * cell
        sheet.alpha_composite(gif.convert("RGBA"), (x + 8, y + 4))
        d.text((x + 18, y + 66), f"{idx+1:02d}", fill="#c6d6e8")
    SHEET.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(SHEET)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    paths: list[Path] = []
    manifest: list[str] = []
    for idx in range(1, 51):
        frames = [draw_sprite(idx, frame) for frame in range(4)]
        path = OUT / f"character-{idx:02d}.gif"
        frames[0].save(
            path,
            save_all=True,
            append_images=frames[1:],
            duration=[190, 170, 160, 210],
            loop=0,
            disposal=2,
            transparency=0,
        )
        paths.append(path)
        manifest.append(path.name)
    (OUT / "manifest.txt").write_text("\n".join(manifest) + "\n", encoding="utf-8")
    make_contact_sheet(paths)
    print(f"generated {len(paths)} original humanoid virtual-pet GIFs in {OUT}")
    print(f"contact sheet: {SHEET}")


if __name__ == "__main__":
    main()
