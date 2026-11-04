from PIL import Image, ImageDraw
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ART = os.path.join(ROOT, "assets", "art_sample")


def checker(size, block=16):
    img = Image.new("RGBA", size, (236, 230, 220, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, size[1], block):
        for x in range(0, size[0], block):
            if (x // block + y // block) % 2:
                d.rectangle([x, y, x + block - 1, y + block - 1], fill=(218, 211, 200, 255))
    return img


def rabbit_review():
    names = []
    for mode in ("idle", "walk"):
        for direction in ("down", "up", "side"):
            count = 2 if mode == "idle" else 4
            for frame in range(count):
                names.append((f"{mode}_{direction}_{frame:02d}",
                              f"characters/rabbit_{mode}_{direction}_{frame:02d}.png"))
    cols = 6
    cell_w, cell_h = 190, 240
    rows = (len(names) + cols - 1) // cols
    sheet = checker((cols * cell_w + 20, rows * cell_h + 20))
    d = ImageDraw.Draw(sheet)
    for i, (label, rel) in enumerate(names):
        x = 10 + (i % cols) * cell_w
        y = 10 + (i // cols) * cell_h
        img = Image.open(os.path.join(ART, rel)).convert("RGBA")
        sheet.alpha_composite(img, (x + 10, y + 12))
        d.text((x + 8, y + 218), label, fill=(80, 55, 42, 255))
    sheet.save(os.path.join(ART, "review_rabbit.png"))


def props_review():
    items = [
        ("tree", "props/tree_01.png"), ("bush", "props/bush_01.png"),
        ("rock", "props/rock_01.png"), ("stump", "props/stump_01.png"),
        ("crate", "furniture/crate_01.png"), ("table 2x1", "furniture/table_2x1.png"),
        ("chair", "furniture/chair_01.png"),
    ]
    sheet = checker((1220, 390))
    d = ImageDraw.Draw(sheet)
    x = 18
    for label, rel in items:
        img = Image.open(os.path.join(ART, rel)).convert("RGBA")
        sheet.alpha_composite(img, (x, 64))
        d.text((x, 24), f"{label}  {img.width}x{img.height}", fill=(80, 55, 42, 255))
        x += max(img.width, 110) + 18
    tiles = [("grass", "terrain/grass_01.png"), ("sand", "terrain/sand_01.png"),
             ("water", "terrain/water_01.png")]
    x = 18
    for label, rel in tiles:
        img = Image.open(os.path.join(ART, rel)).convert("RGBA")
        sheet.alpha_composite(img, (x, 300))
        d.text((x, 280), label, fill=(80, 55, 42, 255))
        x += 230
    sheet.save(os.path.join(ART, "review_props.png"))


rabbit_review()
props_review()
print("review sheets written")
