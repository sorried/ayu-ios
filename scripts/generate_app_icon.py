#!/usr/bin/env python3
"""Generate the app icon set from a single source PNG.

Reads docs/assets/icon-1024.png, flattens any transparency onto the image's
dominant background colour (iOS renders transparent app-icon pixels as black,
so a source with rounded transparent corners must be flattened), then writes
every required size into Telegram/Telegram-iOS/DefaultAppIcon.xcassets/
AppIconLLC.appiconset/ and rewrites its Contents.json.

Run from the repo root:

    python3 scripts/generate_app_icon.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "assets" / "icon-1024.png"
OUT_DIR = ROOT / "Telegram" / "Telegram-iOS" / "DefaultAppIcon.xcassets" / "AppIconLLC.appiconset"

# Slot -> (idiom, points, scale) -> pixel size. Reused pixel sizes share one file.
SLOTS = {
    "20":    [("iphone", 20, 2), ("iphone", 20, 3), ("ipad", 20, 1), ("ipad", 20, 2)],
    "29":    [("iphone", 29, 2), ("iphone", 29, 3), ("ipad", 29, 1), ("ipad", 29, 2)],
    "40":    [("iphone", 40, 2), ("iphone", 40, 3), ("ipad", 40, 1), ("ipad", 40, 2)],
    "60":    [("iphone", 60, 2), ("iphone", 60, 3)],
    "76":    [("ipad", 76, 2)],
    "83.5":  [("ipad", 83.5, 2)],
    "1024":  [("ios-marketing", 1024, 1)],
}

# pixel size per point/scale key used above
def pixel_size(name: str, scale: int) -> int:
    return int(round(float(name) * scale))


def flatten_alpha(im: Image.Image) -> Image.Image:
    """Composite onto the dominant opaque colour so the result has no alpha.

    The average of all opaque pixels is wrong for an icon that is a logo on a
    solid background (it bleeds the logo colour into the corners). The most
    common quantised opaque colour is the background, so the rounded corners are
    filled with the same colour they are already surrounded by and the seam is
    invisible.
    """
    from collections import Counter

    rgba = im.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()
    counts: Counter = Counter()
    for y in range(0, h, 4):
        for x in range(0, w, 4):
            r, g, b, a = px[x, y]
            if a == 255:
                counts[(r // 16 * 16, g // 16 * 16, b // 16 * 16)] += 1
    if not counts:
        background = (255, 255, 255)
    else:
        quantised = counts.most_common(1)[0][0]
        background = (min(quantised[0] + 8, 255), min(quantised[1] + 8, 255), min(quantised[2] + 8, 255))
    print(f"flattening onto dominant opaque colour {background}")
    bg = Image.new("RGB", rgba.size, background)
    bg.paste(rgba, (0, 0), rgba)
    return bg


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    src = Image.open(SOURCE).convert("RGBA")
    flat = flatten_alpha(src)

    images = []
    written: dict[int, str] = {}
    for name, slots in SLOTS.items():
        for idiom, points, scale in slots:
            px = pixel_size(name, scale)
            if px not in written:
                filename = f"AppIcon-{px}.png"
                flat.resize((px, px), Image.LANCZOS).save(OUT_DIR / filename)
                written[px] = filename
                print(f"wrote {filename} ({px}x{px})")
            images.append(
                {
                    "filename": written[px],
                    "idiom": idiom,
                    "scale": f"{scale}x",
                    "size": f"{points}x{points}",
                }
            )

    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    import json

    (OUT_DIR / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    print(f"wrote Contents.json ({len(images)} entries, {len(written)} files)")
    print(f"source: {SOURCE} ({src.size[0]}x{src.size[1]}, {src.mode})")


if __name__ == "__main__":
    main()
