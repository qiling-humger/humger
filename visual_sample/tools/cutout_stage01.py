"""Turn the Stage 1 magenta-screen AI renders into transparent PNGs.

This is post-processing only: no geometry is drawn. The AI image provides all
artwork; we remove the flat magenta background, trim transparent padding, and
write a checkerboard preview sheet for review.
"""
from __future__ import annotations

import os
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
STAGE = os.path.join(ROOT, "assets", "art_staging", "stage_01_base")

JOBS = [
    ("rabbit", "rabbit/original_ai/rabbit_stage01_clean_original.jpg",
     "rabbit/transparent_png/rabbit_stage01.png"),
    ("tree", "environment/original_ai/tree_stage01_original.jpg",
     "environment/transparent_png/tree_stage01.png"),
    ("bush", "environment/original_ai/bush_stage01_original.jpg",
     "environment/transparent_png/bush_stage01.png"),
    ("rock", "environment/original_ai/rock_stage01_original.jpg",
     "environment/transparent_png/rock_stage01.png"),
    ("grass", "environment/original_ai/grass_stage01_original.jpg",
     "environment/transparent_png/grass_stage01.png"),
]


def cutout(src: str, dst: str) -> tuple[int, int]:
    im = Image.open(src).convert("RGB")
    hsv = im.convert("HSV")
    pixels = hsv.load()
    w, h = im.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src_pixels = im.load()
    dst_pixels = out.load()
    for y in range(h):
        for x in range(w):
            hh, ss, vv = pixels[x, y]
            hue = hh * 360.0 / 255.0
            sat = ss / 255.0
            val = vv / 255.0
            is_magenta = (300.0 <= hue <= 350.0) and sat >= 0.35 and val >= 0.05
            if not is_magenta:
                r, g, b = src_pixels[x, y]
                dst_pixels[x, y] = (r, g, b, 255)
    bbox = out.getbbox()
    if bbox is None:
        raise RuntimeError("alpha bbox empty: " + src)
    pad = 16
    left = max(0, bbox[0] - pad)
    top = max(0, bbox[1] - pad)
    right = min(w, bbox[2] + pad)
    bottom = min(h, bbox[3] + pad)
    out = out.crop((left, top, right, bottom))
    out.save(dst)
    return out.size


def checker(size, block=18):
    img = Image.new("RGBA", size, (238, 233, 224, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, size[1], block):
        for x in range(0, size[0], block):
            if (x // block + y // block) % 2:
                d.rectangle([x, y, x + block - 1, y + block - 1], fill=(214, 208, 198, 255))
    return img


def preview(results):
    cols = 3
    cell_w, cell_h = 380, 400
    rows = (len(results) + cols - 1) // cols
    sheet = checker((cols * cell_w + 24, rows * cell_h + 28))
    d = ImageDraw.Draw(sheet)
    for i, (label, path, size) in enumerate(results):
        x = 12 + (i % cols) * cell_w
        y = 12 + (i // cols) * cell_h
        img = Image.open(path).convert("RGBA")
        img.thumbnail((cell_w - 28, cell_h - 52), Image.LANCZOS)
        sheet.alpha_composite(img, (x + (cell_w - img.width) // 2,
                                    y + 24 + (cell_h - 52 - img.height) // 2))
        d.text((x + 8, y + 4), f"{label}  {size[0]}x{size[1]}", fill=(80, 55, 42, 255))
    sheet.save(os.path.join(STAGE, "preview", "stage01_assets_transparent.png"))


def main():
    results = []
    for folder, src_name, dst_name in JOBS:
        src = os.path.join(STAGE, src_name)
        dst = os.path.join(STAGE, dst_name)
        size = cutout(src, dst)
        results.append((folder, dst, size))
        print(f"{folder}: {size[0]}x{size[1]} -> {dst}")
    preview(results)
    print("preview ->", os.path.join(STAGE, "preview", "stage01_assets_transparent.png"))


if __name__ == "__main__":
    main()
