"""Stage 02 asset post-processing.

Converts AI magenta-screen frames into game-ready transparent PNGs and
normalizes rabbit frames onto one canvas so the feet stay aligned.

This script only removes the background and aligns existing AI artwork; it does
not draw characters or props.
"""
from __future__ import annotations

import json
import os
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
STAGE = os.path.join(ROOT, "assets", "art_staging", "stage_02")


def cut_magenta(path: str) -> Image.Image:
    im = Image.open(path).convert("RGB")
    hsv = im.convert("HSV")
    src = im.load()
    hp = hsv.load()
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    dst = out.load()
    for y in range(im.height):
        for x in range(im.width):
            h, s, v = hp[x, y]
            hue = h * 360.0 / 255.0
            sat = s / 255.0
            val = v / 255.0
            if not (300.0 <= hue <= 350.0 and sat >= 0.35 and val >= 0.05):
                r, g, b = src[x, y]
                dst[x, y] = (r, g, b, 255)
    return out


def normalize_frame(src: str, dst: str, canvas=(360, 420), max_h=350) -> None:
    im = cut_magenta(src)
    bbox = im.getbbox()
    if bbox is None:
        raise RuntimeError("empty foreground: " + src)
    im = im.crop(bbox)
    scale = min(1.0, float(max_h) / im.height)
    nw, nh = max(1, round(im.width * scale)), max(1, round(im.height * scale))
    im = im.resize((nw, nh), Image.LANCZOS)
    out = Image.new("RGBA", canvas, (0, 0, 0, 0))
    x = (canvas[0] - nw) // 2
    y = canvas[1] - 12 - nh
    out.alpha_composite(im, (x, y))
    out.save(dst)


def normalize_prop(src: str, dst: str, max_side: int = 900, pad: int = 16) -> None:
    im = cut_magenta(src)
    bbox = im.getbbox()
    if bbox is None:
        raise RuntimeError("empty foreground: " + src)
    im = im.crop(bbox)
    scale = min(1.0, float(max_side) / max(im.width, im.height))
    if scale < 1.0:
        im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
    out = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    out.alpha_composite(im, (pad, pad))
    out.save(dst)


def resolve_input(relative_path: str) -> str:
    path = os.path.join(STAGE, relative_path)
    if os.path.exists(path):
        return path
    if relative_path.lower().endswith(".png"):
        jpg = os.path.join(STAGE, relative_path[:-4] + ".jpg")
        if os.path.exists(jpg):
            return jpg
    return ""


def main() -> None:
    plan_path = os.path.join(STAGE, "records", "asset_plan.json")
    if not os.path.exists(plan_path):
        raise SystemExit("missing " + plan_path)
    plan = json.load(open(plan_path, encoding="utf-8"))
    for item in plan.get("rabbit_frames", []):
        src = resolve_input(item["input"])
        if src:
            dst = os.path.join(STAGE, item["output"])
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            normalize_frame(src, dst)
            print("frame", os.path.basename(dst))
    for item in plan.get("props", []):
        src = resolve_input(item["input"])
        if src:
            dst = os.path.join(STAGE, item["output"])
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            normalize_prop(src, dst)
            print("prop", os.path.basename(dst))


if __name__ == "__main__":
    main()
