"""Generate the visual-sample art set from scratch.

All assets are transparent PNGs. The reference board is used only as a style
target; nothing is cropped from it. Re-run this script to reproduce the set.
"""
from __future__ import annotations

import json
import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter

S = 4  # supersampling
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "art_sample")

INK = (86, 58, 46, 255)
INK_SOFT = (116, 82, 65, 220)
CREAM = (255, 249, 238, 255)
CREAM_DARK = (238, 224, 208, 255)
PINK = (243, 169, 165, 255)
PINK_DARK = (222, 133, 132, 255)
CORAL = (230, 118, 96, 255)
CORAL_DARK = (190, 85, 70, 255)
MINT = (128, 199, 180, 255)
MINT_DARK = (91, 158, 143, 255)
BUTTER = (246, 205, 112, 255)
BROWN = (174, 112, 66, 255)
BROWN_DARK = (127, 77, 45, 255)
WOOD = (190, 126, 79, 255)
WOOD_LIGHT = (221, 161, 107, 255)
WOOD_DARK = (145, 87, 52, 255)
LEAF = (111, 176, 83, 255)
LEAF_DARK = (73, 132, 65, 255)
LEAF_LIGHT = (157, 207, 99, 255)
STONE = (150, 153, 144, 255)
STONE_DARK = (112, 117, 109, 255)
STONE_LIGHT = (187, 189, 176, 255)
SAND = (236, 210, 157, 255)
SAND_LIGHT = (247, 226, 177, 255)
SAND_DARK = (210, 176, 126, 255)
WATER = (98, 190, 192, 255)
WATER_LIGHT = (139, 218, 211, 255)
WHITE = (255, 255, 255, 255)


def rgba(color, alpha):
    return (color[0], color[1], color[2], max(0, min(255, int(alpha))))


def mix(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(4))


class Canvas:
    def __init__(self, width, height):
        self.w = width
        self.h = height
        self.img = Image.new("RGBA", (width * S, height * S), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def p(self, point):
        return (float(point[0]) * S, float(point[1]) * S)

    def box(self, center, rx, ry):
        x, y = center
        return [(x - rx) * S, (y - ry) * S, (x + rx) * S, (y + ry) * S]

    def blend(self, layer):
        self.img = Image.alpha_composite(self.img, layer)
        self.d = ImageDraw.Draw(self.img)

    def shadow(self, center, rx, ry, alpha=52, blur=7):
        layer = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        d.ellipse(self.box(center, rx, ry), fill=(64, 45, 34, alpha))
        layer = layer.filter(ImageFilter.GaussianBlur(blur * S))
        self.blend(layer)

    def soft_ellipse(self, center, rx, ry, color, blur=2):
        layer = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        d.ellipse(self.box(center, rx, ry), fill=color)
        if blur:
            layer = layer.filter(ImageFilter.GaussianBlur(blur * S))
        self.blend(layer)

    def soft_polygon(self, points, color):
        layer = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        d.polygon([self.p(p) for p in points], fill=color)
        self.blend(layer)

    def ellipse(self, center, rx, ry, fill, outline=None, width=3):
        self.d.ellipse(self.box(center, rx, ry), fill=fill,
                       outline=outline, width=int(width * S))

    def polygon(self, points, fill, outline=None, width=3):
        p = [self.p(point) for point in points]
        if fill is not None:
            self.d.polygon(p, fill=fill)
        if outline is not None:
            self.d.line(p + [p[0]], fill=outline, width=int(width * S), joint="curve")

    def line(self, points, color, width=3):
        p = [self.p(point) for point in points]
        self.d.line(p, fill=color, width=int(width * S), joint="curve")
        r = width * S * 0.5
        for point in (p[0], p[-1]):
            self.d.ellipse([point[0] - r, point[1] - r, point[0] + r, point[1] + r], fill=color)

    def capsule(self, a, b, width, fill, outline=None, outline_width=3):
        if outline is not None:
            self.line([a, b], outline, width + outline_width * 2)
        self.line([a, b], fill, width)

    def arc(self, center, rx, ry, start, end, color, width=3):
        self.d.arc(self.box(center, rx, ry), start=start, end=end, fill=color,
                   width=int(width * S))

    def save(self, relative_path):
        path = os.path.join(OUT, relative_path)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        self.img.resize((self.w, self.h), Image.LANCZOS).save(path)
        return path


# ---------------------------------------------------------------------------
# Rabbit animation frames
# ---------------------------------------------------------------------------

def draw_rabbit(direction: str, mode: str, frame: int) -> Canvas:
    c = Canvas(160, 220)
    idle = mode == "idle"
    bob = (0, -1)[frame % 2] if idle else (0, -2, 0, 1)[frame % 4]
    swing = 0 if idle else (9, 0, -9, 0)[frame % 4]
    ear_sway = (0, 1.0)[frame % 2] if idle else (0, 2, 0, -2)[frame % 4]
    blink = idle and frame % 2 == 1 and direction != "up"
    head_x = 80 + (8 if direction == "side" else 0)
    head_y = 104 + bob
    body_x = 80 + (3 if direction == "side" else 0)
    body_y = 159 + bob
    c.shadow((80, 207), 34, 9, alpha=48, blur=6)

    # Tail behind the body for side/back views.
    if direction == "side":
        c.ellipse((body_x - 38, 174 + bob), 12, 12, CREAM, INK, 3)
    elif direction == "up":
        c.ellipse((body_x + 34, 178 + bob), 12, 12, CREAM, INK, 3)

    # Feet
    if direction == "side":
        c.ellipse((body_x + 22 + swing * 0.55, 201), 13, 7, CREAM, INK, 3)
        c.ellipse((body_x + 4 - swing * 0.55, 202), 13, 7, CREAM_DARK, INK, 3)
    else:
        c.ellipse((body_x - 17 - swing * 0.55, 202), 13, 7, CREAM, INK, 3)
        c.ellipse((body_x + 17 + swing * 0.55, 202), 13, 7, CREAM, INK, 3)

    # Body
    c.ellipse((body_x, body_y), 36, 38, CREAM, INK, 3)
    c.soft_ellipse((body_x + 9, body_y + 10), 22, 23,
                   rgba((221, 205, 189), 70), blur=5)

    # Apron / overalls
    apron = [(body_x - 22, body_y - 16), (body_x + 22, body_y - 16),
             (body_x + 26, body_y + 35), (body_x - 26, body_y + 35)]
    if direction != "up":
        c.polygon(apron, (255, 243, 225, 255), INK, 2)
        c.line([(body_x - 13, body_y - 15), (body_x - 13, body_y + 12)], rgba(INK, 140), 1.5)
        c.line([(body_x + 13, body_y - 15), (body_x + 13, body_y + 12)], rgba(INK, 140), 1.5)
        # Carrot emblem
        carrot = [(body_x, body_y + 4), (body_x + 8, body_y + 12),
                  (body_x - 3, body_y + 16), (body_x - 6, body_y + 10)]
        c.polygon(carrot, CORAL, None)
        c.line([(body_x + 1, body_y + 6), (body_x + 8, body_y + 2)], LEAF_DARK, 2)
        c.line([(body_x + 1, body_y + 6), (body_x + 10, body_y + 6)], LEAF_DARK, 2)
    else:
        # Back straps make the back view readable.
        c.line([(body_x - 18, body_y - 12), (body_x - 12, body_y + 24)], rgba(INK, 85), 2)
        c.line([(body_x + 18, body_y - 12), (body_x + 12, body_y + 24)], rgba(INK, 85), 2)
        c.line([(body_x - 20, body_y + 4), (body_x + 20, body_y + 4)], rgba(INK, 55), 1.5)

    # Arms
    arm_y = body_y - 6 + (swing * 0.3)
    c.capsule((body_x - 30, arm_y), (body_x - 43, arm_y + 20), 11, CREAM, INK, 2.5)
    c.capsule((body_x + 30, arm_y), (body_x + 43, arm_y + 20 - swing * 0.4), 11, CREAM, INK, 2.5)
    c.ellipse((body_x - 43, arm_y + 22), 6, 6, CREAM, INK, 2)
    c.ellipse((body_x + 43, arm_y + 22 - swing * 0.4), 6, 6, CREAM, INK, 2)

    # Neck scarf
    c.ellipse((head_x, 135 + bob), 32, 11, CORAL, INK, 2.5)
    c.polygon([(head_x - 28, 136 + bob), (head_x - 40, 149 + bob),
               (head_x - 30, 153 + bob), (head_x - 22, 141 + bob)], CORAL, INK, 2)
    c.soft_ellipse((head_x - 29, 139 + bob), 8, 4, rgba(BUTTER, 90), blur=2)

    # Ears behind the head
    if direction == "side":
        c.capsule((head_x - 17, head_y - 26), (head_x - 34, head_y - 82 + ear_sway * 2),
                  18, (245, 232, 218, 255), INK, 3)
        c.capsule((head_x + 6, head_y - 28), (head_x + 18, head_y - 88 - ear_sway),
                  20, CREAM, INK, 3)
        c.capsule((head_x + 7, head_y - 37), (head_x + 16, head_y - 78 - ear_sway),
                  8, PINK, None)
    else:
        c.capsule((head_x - 16, head_y - 25), (head_x - 28 + ear_sway, head_y - 84),
                  19, CREAM, INK, 3)
        c.capsule((head_x + 16, head_y - 25), (head_x + 30 - ear_sway, head_y - 88),
                  19, CREAM, INK, 3)
        c.capsule((head_x - 16, head_y - 34), (head_x - 25 + ear_sway * 0.6, head_y - 76),
                  9, PINK, None)
        c.capsule((head_x + 16, head_y - 34), (head_x + 26 - ear_sway * 0.6, head_y - 80),
                  9, PINK, None)

    # Head
    c.ellipse((head_x, head_y), 44, 43, CREAM, INK, 3)
    c.soft_ellipse((head_x - 16, head_y - 13), 16, 11, rgba(WHITE, 110), blur=3)
    c.soft_ellipse((head_x + 21, head_y + 13), 16, 17, rgba((228, 211, 196), 65), blur=4)

    if direction == "down":
        if blink:
            c.arc((head_x - 16, head_y - 1), 8, 5, 0.1, math.pi - 0.1, INK, 2.2)
            c.arc((head_x + 16, head_y - 1), 8, 5, 0.1, math.pi - 0.1, INK, 2.2)
        else:
            c.ellipse((head_x - 16, head_y), 4.3, 6.2, INK)
            c.ellipse((head_x + 16, head_y), 4.3, 6.2, INK)
            c.ellipse((head_x - 17.5, head_y - 2.2), 1.4, 2.0, WHITE)
            c.ellipse((head_x + 14.5, head_y - 2.2), 1.4, 2.0, WHITE)
        c.polygon([(head_x - 3, head_y + 8), (head_x + 3, head_y + 8),
                   (head_x, head_y + 12)], PINK_DARK, None)
        c.arc((head_x, head_y + 13), 5, 4, 0.2, math.pi - 0.2, INK, 1.8)
        c.soft_ellipse((head_x - 27, head_y + 12), 8, 4, rgba(PINK, 105), blur=2)
        c.soft_ellipse((head_x + 27, head_y + 12), 8, 4, rgba(PINK, 105), blur=2)
    elif direction == "side":
        if blink:
            c.arc((head_x + 15, head_y - 1), 7, 5, 0.1, math.pi - 0.1, INK, 2.2)
        else:
            c.ellipse((head_x + 15, head_y), 4.3, 6.2, INK)
            c.ellipse((head_x + 13.5, head_y - 2.2), 1.4, 2.0, WHITE)
        c.ellipse((head_x + 39, head_y + 15), 15, 11, CREAM, INK, 2.2)
        c.polygon([(head_x + 50, head_y + 12), (head_x + 57, head_y + 15),
                   (head_x + 50, head_y + 18)], PINK_DARK, None)
        c.arc((head_x + 45, head_y + 21), 6, 4, 0.2, math.pi - 0.2, INK, 1.8)
        c.soft_ellipse((head_x + 33, head_y + 23), 8, 4, rgba(PINK, 95), blur=2)
    else:
        # Back of the head: fluff and a tiny bow.
        c.ellipse((head_x, head_y + 18), 18, 8, CREAM_DARK, None)
        c.polygon([(head_x - 18, 133 + bob), (head_x - 4, 139 + bob),
                   (head_x - 14, 147 + bob)], CORAL, INK, 1.5)
        c.ellipse((head_x - 19, 139 + bob), 4, 4, CORAL, INK, 1.2)

    return c


def generate_rabbit():
    animations = {}
    for direction in ("down", "up", "side"):
        for mode in ("idle", "walk"):
            count = 2 if mode == "idle" else 4
            paths = []
            for frame in range(count):
                c = draw_rabbit(direction, mode, frame)
                rel = f"characters/rabbit_{mode}_{direction}_{frame:02d}.png"
                c.save(rel)
                paths.append("res://assets/art_sample/" + rel)
            animations[f"{mode}_{direction}"] = paths
    return {
        "frame_size": [160, 220],
        "base_pad": 12,
        "display_scale": 0.68,
        "animations": animations,
    }


# ---------------------------------------------------------------------------
# Props / furniture / terrain
# ---------------------------------------------------------------------------

def draw_tree():
    c = Canvas(190, 250)
    c.shadow((95, 237), 56, 17, alpha=48, blur=7)
    # Trunk
    c.polygon([(86, 235), (104, 235), (101, 168), (90, 168)], BROWN, INK, 3)
    c.line([(95, 231), (95, 171)], WOOD_DARK, 2)
    c.polygon([(88, 232), (78, 245), (85, 244), (94, 233)], BROWN_DARK, INK, 2)
    c.polygon([(101, 232), (111, 245), (104, 244), (96, 233)], BROWN_DARK, INK, 2)
    # Canopy puffs, back to front.
    puffs = [
        ((60, 112), 38, LEAF_DARK), ((126, 108), 35, LEAF_DARK),
        ((94, 82), 45, LEAF), ((48, 78), 29, LEAF),
        ((137, 75), 27, LEAF), ((79, 61), 29, LEAF_LIGHT),
        ((112, 55), 24, LEAF_LIGHT),
    ]
    for center, radius, color in puffs:
        c.ellipse(center, radius, radius * 0.92, color, INK, 3)
    c.soft_ellipse((77, 61), 14, 9, rgba((211, 235, 153), 120), blur=2)
    # Fruits and tiny flowers
    for x, y in ((45, 83), (77, 82), (128, 76), (145, 96), (46, 118)):
        c.ellipse((x, y), 4, 4, CORAL, INK, 1.2)
    c.ellipse((72, 102), 3, 3, BUTTER, None)
    c.ellipse((116, 92), 3, 3, BUTTER, None)
    return c


def draw_bush():
    c = Canvas(150, 120)
    c.shadow((75, 108), 44, 12, alpha=45, blur=6)
    puffs = [((44, 80), 24, LEAF_DARK), ((102, 78), 23, LEAF_DARK),
             ((75, 59), 31, LEAF), ((56, 52), 19, LEAF_LIGHT),
             ((96, 54), 18, LEAF_LIGHT)]
    for center, radius, color in puffs:
        c.ellipse(center, radius, radius * 0.82, color, INK, 2.5)
    for x in (35, 72, 110):
        c.line([(x, 98), (x - 4, 78)], LEAF_DARK, 3)
    c.ellipse((56, 54), 3, 3, BUTTER, None)
    c.ellipse((95, 62), 2.8, 2.8, CREAM, None)
    return c


def draw_rock():
    c = Canvas(130, 100)
    c.shadow((65, 91), 42, 11, alpha=45, blur=6)
    body = [(18, 82), (12, 60), (27, 33), (59, 19), (93, 26),
            (116, 53), (113, 78), (91, 91), (43, 91)]
    c.polygon(body, STONE, INK, 3)
    c.polygon([(27, 33), (59, 19), (78, 47), (52, 67), (26, 58)], STONE_LIGHT, INK, 2)
    c.polygon([(78, 47), (93, 26), (116, 53), (113, 78), (83, 88), (78, 47)],
              STONE_DARK, INK, 2)
    c.soft_ellipse((47, 40), 13, 7, rgba(WHITE, 80), blur=2)
    c.arc((57, 74), 13, 6, 0.2, 2.8, rgba(INK, 100), 1.5)
    return c


def draw_crate():
    c = Canvas(110, 120)
    c.shadow((55, 111), 39, 11, alpha=45, blur=5)
    top = [(55, 37), (99, 56), (55, 77), (11, 56)]
    c.polygon(top, WOOD_LIGHT, INK, 2.5)
    c.polygon([(11, 56), (55, 77), (55, 105), (11, 84)], WOOD, INK, 2.5)
    c.polygon([(55, 77), (99, 56), (99, 84), (55, 105)], WOOD_DARK, INK, 2.5)
    for a, b in [((25, 62), (41, 69)), ((41, 69), (41, 96)),
                 ((68, 82), (85, 74)), ((85, 74), (85, 97))]:
        c.line([a, b], rgba(INK, 150), 2)
    c.ellipse((55, 56), 2, 2, BUTTER)
    return c


def draw_table():
    c = Canvas(220, 150)
    c.shadow((110, 139), 89, 18, alpha=43, blur=7)
    # Four legs
    for x, y in ((46, 113), (174, 113), (74, 132), (148, 132)):
        c.line([(x, y), (x, y + 15)], WOOD_DARK, 5)
        c.ellipse((x, y + 15), 3, 2, WOOD_DARK)
    # Tabletop is a wide isometric diamond.
    top = [(110, 43), (197, 78), (110, 113), (23, 78)]
    c.polygon(top, WOOD_LIGHT, INK, 3)
    c.polygon([(23, 78), (110, 113), (110, 129), (23, 94)], WOOD, INK, 2)
    c.polygon([(110, 113), (197, 78), (197, 94), (110, 129)], WOOD_DARK, INK, 2)
    # Planks
    c.line([(43, 74), (110, 102)], rgba(WOOD_DARK, 150), 1.5)
    c.line([(110, 58), (180, 85)], rgba(WOOD_DARK, 100), 1.2)
    # A small cup
    c.ellipse((154, 58), 8, 5, CREAM, INK, 1.5)
    c.arc((154, 55), 8, 5, 0, math.pi, INK, 1.5)
    return c


def draw_chair():
    c = Canvas(100, 150)
    c.shadow((50, 140), 33, 9, alpha=42, blur=5)
    # Four sturdy legs.
    c.line([(28, 108), (26, 137)], WOOD_DARK, 5)
    c.line([(72, 108), (74, 137)], WOOD_DARK, 5)
    c.line([(40, 102), (39, 130)], rgba(WOOD_DARK, 170), 4)
    c.line([(62, 102), (63, 130)], rgba(WOOD_DARK, 170), 4)
    # Seat with thickness.
    c.polygon([(50, 91), (80, 103), (50, 116), (20, 103)], WOOD_LIGHT, INK, 2.2)
    c.polygon([(20, 103), (50, 116), (50, 127), (20, 114)], WOOD, INK, 2)
    c.polygon([(50, 116), (80, 103), (80, 114), (50, 127)], WOOD_DARK, INK, 2)
    # Solid backrest.
    c.polygon([(31, 47), (66, 57), (68, 87), (31, 78)], WOOD, INK, 2.4)
    c.polygon([(35, 53), (61, 61), (62, 78), (35, 71)], WOOD_LIGHT, None)
    c.line([(31, 47), (66, 57)], WOOD_DARK, 4)
    c.line([(31, 64), (66, 74)], rgba(WOOD_DARK, 150), 2)
    c.line([(31, 78), (68, 87)], rgba(WOOD_DARK, 150), 2)
    return c


def draw_stump():
    c = Canvas(90, 74)
    c.shadow((45, 67), 29, 8, alpha=40, blur=4)
    c.polygon([(22, 61), (22, 39), (68, 39), (68, 61)], BROWN_DARK, INK, 2)
    c.ellipse((45, 38), 24, 9, WOOD, INK, 2)
    c.arc((45, 38), 14, 5, 0, math.pi * 2, WOOD_DARK, 1.2)
    c.line([(31, 57), (31, 46)], (35, 30, 24, 130), 1.2)
    return c


def draw_grass_tile():
    c = Canvas(192, 96)
    diamond = [(96, 1), (191, 48), (96, 95), (1, 48)]
    c.polygon(diamond, LEAF, None)
    # natural color patches clipped roughly inside diamond
    rnd = random.Random(12)
    for i in range(30):
        x = 24 + rnd.random() * 144
        y = 15 + rnd.random() * 66
        if abs(x - 96) / 90 + abs(y - 48) / 45 < 0.86:
            c.soft_ellipse((x, y), rnd.uniform(5, 16), rnd.uniform(2, 7),
                           rgba((73, 132, 65), 36), blur=4)
    for x, y in ((48, 42), (68, 56), (113, 35), (139, 54), (86, 68), (121, 63)):
        c.line([(x, y + 4), (x - 2, y - 3)], rgba(LEAF_DARK, 170), 1.2)
        c.line([(x + 3, y + 4), (x + 4, y - 2)], rgba(LEAF_DARK, 140), 1.0)
    for x, y in ((56, 32), (103, 57), (145, 43)):
        c.ellipse((x, y), 2.5, 2.5, BUTTER)
        c.ellipse((x, y), 1.1, 1.1, CREAM)
    return c


def draw_sand_tile():
    c = Canvas(192, 96)
    diamond = [(96, 1), (191, 48), (96, 95), (1, 48)]
    c.polygon(diamond, SAND, None)
    rnd = random.Random(7)
    for i in range(28):
        x = 24 + rnd.random() * 144
        y = 15 + rnd.random() * 66
        if abs(x - 96) / 90 + abs(y - 48) / 45 < 0.86:
            c.soft_ellipse((x, y), rnd.uniform(4, 13), rnd.uniform(2, 5),
                           rgba(SAND_DARK, 30), blur=3)
    for x, y in ((48, 38), (87, 54), (131, 60), (152, 39), (68, 68)):
        c.ellipse((x, y), 2, 1.5, rgba(SAND_DARK, 150))
    return c


def draw_water_tile():
    c = Canvas(192, 96)
    diamond = [(96, 1), (191, 48), (96, 95), (1, 48)]
    c.polygon(diamond, WATER, None)
    for i in range(4):
        y = 27 + i * 14
        c.arc((70, y), 34, 8, 0.2, 2.9, rgba(WATER_LIGHT, 110), 2)
        c.arc((126, y + 5), 27, 7, 0.1, 2.8, rgba(WHITE, 75), 1.5)
    return c


def generate_props():
    prop_defs = {
        "tree": (draw_tree, "props/tree_01.png", [1, 1], 10, 0.72),
        "bush": (draw_bush, "props/bush_01.png", [1, 1], 10, 0.72),
        "rock": (draw_rock, "props/rock_01.png", [1, 1], 8, 0.74),
        "crate": (draw_crate, "furniture/crate_01.png", [1, 1], 12, 0.68),
        "table": (draw_table, "furniture/table_2x1.png", [2, 1], 11, 0.72),
        "chair": (draw_chair, "furniture/chair_01.png", [1, 1], 12, 0.72),
        "stump": (draw_stump, "props/stump_01.png", [1, 1], 7, 0.72),
    }
    meta = {}
    for key, (fn, rel, grid, pad, scale) in prop_defs.items():
        canvas = fn()
        canvas.save(rel)
        meta[key] = {"texture": "res://assets/art_sample/" + rel,
                     "grid_size": grid, "base_pad": pad, "display_scale": scale}
    terrain = {}
    for key, fn, rel in (
        ("grass", draw_grass_tile, "terrain/grass_01.png"),
        ("sand", draw_sand_tile, "terrain/sand_01.png"),
        ("water", draw_water_tile, "terrain/water_01.png"),
    ):
        canvas = fn()
        canvas.save(rel)
        terrain[key] = "res://assets/art_sample/" + rel
    return meta, terrain


# ---------------------------------------------------------------------------
# Contact sheets
# ---------------------------------------------------------------------------

def contact_sheet():
    bg = (246, 237, 226, 255)
    sheet = Image.new("RGBA", (1180, 900), bg)
    d = ImageDraw.Draw(sheet)
    x, y = 24, 20
    # Rabbit frames
    for mode in ("idle", "walk"):
        for direction in ("down", "up", "side"):
            count = 2 if mode == "idle" else 4
            for frame in range(count):
                path = os.path.join(OUT, f"characters/rabbit_{mode}_{direction}_{frame:02d}.png")
                if not os.path.exists(path):
                    continue
                img = Image.open(path).convert("RGBA")
                sheet.alpha_composite(img, (x, y + 16))
                d.text((x, y), f"{mode} {direction} {frame}", fill=(90, 65, 50))
                x += 174
                if x > 1000:
                    x = 24
                    y += 238
    y = 500
    x = 24
    for rel in ("props/tree_01.png", "props/bush_01.png", "props/rock_01.png",
                "props/stump_01.png", "furniture/crate_01.png",
                "furniture/table_2x1.png", "furniture/chair_01.png"):
        path = os.path.join(OUT, rel)
        if os.path.exists(path):
            img = Image.open(path).convert("RGBA")
            sheet.alpha_composite(img, (x, y + 24))
            d.text((x, y), os.path.basename(rel), fill=(90, 65, 50))
            x += 164
    y = 760
    x = 24
    for rel in ("terrain/grass_01.png", "terrain/sand_01.png", "terrain/water_01.png"):
        path = os.path.join(OUT, rel)
        if os.path.exists(path):
            img = Image.open(path).convert("RGBA")
            sheet.alpha_composite(img, (x, y + 12))
            d.text((x, y), os.path.basename(rel), fill=(90, 65, 50))
            x += 210
    sheet.save(os.path.join(OUT, "contact_sheet.png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    rabbit = generate_rabbit()
    props, terrain = generate_props()
    meta = {
        "style": "2D hand-painted cartoon isometric, soft ink outline, upper-left light",
        "palette": {
            "ink": "#563A2E", "cream": "#FFF9EE", "coral": "#E67660",
            "mint": "#80C7B4", "leaf": "#6FB053", "wood": "#BE7E4F",
            "sand": "#ECD29D", "water": "#62BEC0", "stone": "#969990",
        },
        "rabbit": rabbit,
        "props": props,
        "terrain": terrain,
    }
    with open(os.path.join(ROOT, "visual_sample", "data", "asset_catalog.json"),
              "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
    print("Generated visual sample assets into", OUT)
    print("Rabbit animations:", len(rabbit["animations"]))
    print("Props:", len(props), "Terrain:", len(terrain))


if __name__ == "__main__":
    main()
