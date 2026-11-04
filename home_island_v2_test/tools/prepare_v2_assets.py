"""V2 style-test asset cleanup: magenta key, crop, transparent PNG, preview."""
from __future__ import annotations

import os
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ASSETS = os.path.join(ROOT, "assets", "art_style_v2_test")

ITEMS = [
    ("grass", "terrain/source/grass.jpg", "terrain/transparent/grass.png", 16),
    ("tree", "props/source/tree.jpg", "props/transparent/tree.png", 16),
    ("rock", "props/source/rock.jpg", "props/transparent/rock.png", 16),
    ("table", "furniture/source/table.jpg", "furniture/transparent/table.png", 16),
    ("table_rotated", "furniture/source/table_rotated.jpg", "furniture/transparent/table_rotated.png", 16),
]


def cutout(path: str) -> Image.Image:
    im = Image.open(path).convert("RGB")
    hsv = im.convert("HSV")
    src, hp = im.load(), hsv.load()
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    dst = out.load()
    for y in range(im.height):
        for x in range(im.width):
            h, s, v = hp[x, y]
            hue, sat, val = h * 360.0 / 255.0, s / 255.0, v / 255.0
            if not (300.0 <= hue <= 350.0 and sat >= 0.35 and val >= 0.05):
                r, g, b = src[x, y]
                dst[x, y] = (r, g, b, 255)
    bbox = out.getbbox()
    if bbox is None:
        raise RuntimeError("empty: " + path)
    return out.crop(bbox)


def save(img: Image.Image, path: str, pad: int) -> None:
    out = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    out.alpha_composite(img, (pad, pad))
    out.save(path)


def main() -> None:
    results = []
    for name, src_rel, dst_rel, pad in ITEMS:
        src = os.path.join(ASSETS, src_rel)
        dst = os.path.join(ASSETS, dst_rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        img = cutout(src)
        save(img, dst, pad)
        results.append((name, dst, img.size))
        print(name, img.size, "->", dst)

    cells = []
    for name, path, size in results:
        im = Image.open(path).convert("RGBA")
        im.thumbnail((300, 260))
        cells.append((name, im))
    sheet = Image.new("RGBA", (1000, 340), (236, 236, 236, 255))
    d = ImageDraw.Draw(sheet)
    for i, (name, im) in enumerate(cells):
        x = 10 + i * 250
        sheet.alpha_composite(im, (x + (240 - im.width) // 2, 40 + (250 - im.height) // 2))
        d.text((x + 6, 10), name, fill=(0, 0, 0, 255))
    sheet.convert("RGB").save(os.path.join(ASSETS, "preview", "v2_assets_contact.jpg"))


if __name__ == "__main__":
    main()
