class_name Painter
extends RefCounted
## 统一的手绘卡通风绘制工具。
## 全部图元都是矢量曲线/多边形，不使用像素贴图，保证 45° 斜俯视的统一观感。

const INK := Color(0.290, 0.231, 0.208)
const INK_SOFT := Color(0.420, 0.345, 0.302)
const CREAM := Color(1.0, 0.965, 0.910)
const PAPER := Color(1.0, 0.992, 0.972)
const PEACH := Color(0.965, 0.725, 0.541)
const CORAL := Color(0.914, 0.510, 0.408)
const CORAL_DARK := Color(0.760, 0.365, 0.300)
const MINT := Color(0.620, 0.851, 0.753)
const MINT_LIGHT := Color(0.820, 0.925, 0.866)
const TEAL := Color(0.310, 0.659, 0.557)
const BROWN := Color(0.545, 0.369, 0.275)
const BROWN_DARK := Color(0.365, 0.243, 0.190)
const BUTTER := Color(0.965, 0.824, 0.467)
const TOMATO := Color(0.851, 0.325, 0.310)
const MUSTARD := Color(0.890, 0.698, 0.235)
const LETTUCE := Color(0.569, 0.769, 0.424)
const GRAY := Color(0.789, 0.757, 0.722)
const LIGHT_GRAY := Color(0.910, 0.882, 0.839)
const WHITE := Color(1.0, 1.0, 1.0)
const PINK := Color(0.949, 0.686, 0.655)
const GLASS := Color(0.690, 0.878, 0.902, 0.34)

const FONT_PATH := "res://assets/fonts/NotoSansSC-Regular.otf"

static var _font: Font
static var _bold_font: Font


static func font() -> Font:
	if _font == null:
		_font = load(FONT_PATH) as Font
	return _font


static func bold_font() -> Font:
	if _bold_font == null:
		var base := font()
		if base:
			var variation := FontVariation.new()
			variation.base_font = base
			variation.variation_embolden = 0.65
			_bold_font = variation
		else:
			_bold_font = base
	return _bold_font


static func draw_text(ci: CanvasItem, text: String, pos: Vector2, size: int, color: Color = INK,
		bold := false, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var used_font := bold_font() if bold else font()
	if used_font == null:
		return
	ci.draw_string(used_font, pos, text, align, width, size, color)


static func draw_centered(ci: CanvasItem, text: String, center: Vector2, size: int,
		color: Color = INK, bold := false) -> void:
	var used_font := bold_font() if bold else font()
	if used_font == null:
		return
	var width := used_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(used_font, Vector2(center.x - width * 0.5, center.y), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func draw_text_outline(ci: CanvasItem, text: String, pos: Vector2, size: int, color: Color,
		outline: Color, outline_size: int = 3, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT,
		width := -1.0) -> void:
	var used_font := bold_font() if bold else font()
	if used_font == null:
		return
	ci.draw_string_outline(used_font, pos, text, align, width, size, outline_size, outline)
	ci.draw_string(used_font, pos, text, align, width, size, color)


static func ellipse_points(center: Vector2, rx: float, ry: float, segments: int = 28) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


static func rounded_points(rect: Rect2, radius: float, segments: int = 6) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	if r <= 0.1:
		points.append(rect.position)
		points.append(Vector2(rect.end.x, rect.position.y))
		points.append(rect.end)
		points.append(Vector2(rect.position.x, rect.end.y))
		return points
	var centers := [
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.position.y + r),
	]
	var starts := [-PI * 0.5, 0.0, PI * 0.5, PI]
	for corner in range(4):
		for j in range(segments + 1):
			var angle: float = starts[corner] + (PI * 0.5) * (float(j) / float(segments))
			points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * r)
	return points


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result


static func shadow(ci: CanvasItem, center: Vector2, rx: float, ry: float,
		color: Color = Color(0.25, 0.18, 0.14, 0.16)) -> void:
	ci.draw_colored_polygon(ellipse_points(center, rx, ry, 28), color)


static func panel(ci: CanvasItem, rect: Rect2, radius: float, fill: Color, border: Color = INK,
		border_width: float = 2.0, drop_shadow := true) -> void:
	if drop_shadow:
		var shadow_rect := Rect2(rect.position + Vector2(0, 5), rect.size)
		ci.draw_colored_polygon(rounded_points(shadow_rect, radius), Color(0.23, 0.16, 0.12, 0.13))
	var points := rounded_points(rect, radius)
	ci.draw_colored_polygon(points, fill)
	if border_width > 0.0:
		ci.draw_polyline(_closed(points), border, border_width, true)


static func outline_polygon(ci: CanvasItem, points: PackedVector2Array, fill: Color,
		border: Color = INK, border_width: float = 2.0) -> void:
	if points.size() < 3:
		return
	ci.draw_colored_polygon(points, fill)
	ci.draw_polyline(_closed(points), border, border_width, true)


static func line(ci: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float,
		with_outline := true, outline_width := 3.0) -> void:
	if with_outline:
		ci.draw_line(from, to, INK, width + outline_width, true)
	ci.draw_line(from, to, color, width, true)


static func capsule(ci: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float,
		with_outline := true) -> void:
	var outline_width := 3.0 if with_outline else 0.0
	if with_outline:
		ci.draw_line(from, to, INK, width + outline_width, true)
		ci.draw_circle(from, (width + outline_width) * 0.5, INK)
		ci.draw_circle(to, (width + outline_width) * 0.5, INK)
	ci.draw_line(from, to, color, width, true)
	ci.draw_circle(from, width * 0.5, color)
	ci.draw_circle(to, width * 0.5, color)


static func circle_outline(ci: CanvasItem, center: Vector2, radius: float, fill: Color,
		border: Color = INK, border_width: float = 2.0) -> void:
	ci.draw_circle(center, radius, fill)
	ci.draw_arc(center, radius, 0.0, TAU, 36, border, border_width, true)


static func iso_box(ci: CanvasItem, base: Vector2, width: float, height: float, depth: float,
		top_color: Color, front_color: Color, side_color: Color, border: Color = INK,
		border_width: float = 2.2, draw_shadow := true) -> void:
	if draw_shadow:
		shadow(ci, base + Vector2(0, height * 0.16), width * 0.47, height * 0.30)
	var top_center := base - Vector2(0, depth)
	var top_point := top_center + Vector2(0, -height * 0.5)
	var right_point := top_center + Vector2(width * 0.5, 0)
	var bottom_point := top_center + Vector2(0, height * 0.5)
	var left_point := top_center + Vector2(-width * 0.5, 0)
	var left_face := PackedVector2Array([
		left_point, bottom_point, bottom_point + Vector2(0, depth), left_point + Vector2(0, depth)
	])
	var right_face := PackedVector2Array([
		bottom_point, right_point, right_point + Vector2(0, depth), bottom_point + Vector2(0, depth)
	])
	ci.draw_colored_polygon(left_face, front_color)
	ci.draw_polyline(_closed(left_face), border, border_width, true)
	ci.draw_colored_polygon(right_face, side_color)
	ci.draw_polyline(_closed(right_face), border, border_width, true)
	var top_face := PackedVector2Array([top_point, right_point, bottom_point, left_point])
	ci.draw_colored_polygon(top_face, top_color)
	ci.draw_polyline(_closed(top_face), border, border_width, true)
	# 柔和边缘高光，让大色块不那么死。
	var inset := PackedVector2Array([
		top_point + Vector2(0, 8),
		right_point + Vector2(-10, 0),
		bottom_point + Vector2(0, -6),
		left_point + Vector2(10, 0),
	])
	ci.draw_polyline(_closed(inset), Color(1, 1, 1, 0.22), 2.0, true)


static func diamond(ci: CanvasItem, center: Vector2, width: float, height: float, color: Color,
		border: Color = Color.TRANSPARENT, border_width: float = 0.0) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -height * 0.5),
		center + Vector2(width * 0.5, 0),
		center + Vector2(0, height * 0.5),
		center + Vector2(-width * 0.5, 0),
	])
	ci.draw_colored_polygon(points, color)
	if border_width > 0.0:
		ci.draw_polyline(_closed(points), border, border_width, true)


static func keycap(ci: CanvasItem, center: Vector2, letter: String, size: float = 30.0) -> void:
	var rect := Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size))
	panel(ci, rect, 8.0, CORAL, INK, 2.0, true)
	draw_centered(ci, letter, Vector2(center.x, center.y + size * 0.20), int(size * 0.52), WHITE, true)


static func star(ci: CanvasItem, center: Vector2, radius: float, color: Color,
		border := INK) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var angle := -PI * 0.5 + TAU * float(i) / 10.0
		var r := radius if i % 2 == 0 else radius * 0.46
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	ci.draw_colored_polygon(points, color)
	ci.draw_polyline(_closed(points), border, 1.6, true)


static func heart(ci: CanvasItem, center: Vector2, size: float, color: Color,
		border := INK) -> void:
	var points := PackedVector2Array()
	var steps := 26
	for i in range(steps):
		var t := TAU * float(i) / float(steps)
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(center + Vector2(x, y) * (size / 32.0))
	ci.draw_colored_polygon(points, color)
	ci.draw_polyline(_closed(points), border, 1.5, true)


static func coin(ci: CanvasItem, center: Vector2, radius: float) -> void:
	ci.draw_circle(center, radius, BUTTER)
	ci.draw_arc(center, radius, 0.0, TAU, 28, INK, 2.0, true)
	ci.draw_arc(center, radius * 0.68, 0.0, TAU, 24, Color(0.66, 0.47, 0.16, 0.7), 1.4, true)
	ci.draw_line(center + Vector2(0, -radius * 0.38), center + Vector2(0, radius * 0.38),
		Color(0.66, 0.47, 0.16, 0.8), 1.8, true)


static func draw_food_icon(ci: CanvasItem, kind: String, center: Vector2, scale: float = 1.0,
		quality: String = "perfect", sauces: Dictionary = {}) -> void:
	ci.draw_set_transform(center, 0.0, Vector2(scale, scale))
	match kind:
		"raw_sausage":
			shadow(ci, Vector2(0, 5), 24, 7, Color(0.2, 0.14, 0.1, 0.13))
			capsule(ci, Vector2(-18, 0), Vector2(18, 0), PINK, 15.0, true)
			ci.draw_line(Vector2(-10, -3), Vector2(8, -3), Color(1, 1, 1, 0.45), 2.4, true)
			ci.draw_arc(Vector2(15, 0), 3.0, 0.0, TAU, 12, Color(0.85, 0.53, 0.50, 0.8), 1.4, true)
		"bun":
			shadow(ci, Vector2(0, 6), 25, 7, Color(0.2, 0.14, 0.1, 0.13))
			ci.draw_colored_polygon(ellipse_points(Vector2(0, 2), 25, 13), Color(0.75, 0.45, 0.22))
			ci.draw_polyline(_closed(ellipse_points(Vector2(0, 2), 25, 13)), INK, 2.0, true)
			ci.draw_colored_polygon(ellipse_points(Vector2(0, -2), 23, 12), Color(0.95, 0.66, 0.34))
			ci.draw_polyline(_closed(ellipse_points(Vector2(0, -2), 23, 12)), INK, 2.0, true)
			ci.draw_arc(Vector2(0, -2), 17, 0.25, PI - 0.25, 12, Color(0.98, 0.81, 0.55), 2.2, true)
			ci.draw_line(Vector2(-13, -8), Vector2(-4, -9), Color(1, 1, 1, 0.45), 2.0, true)
		"cooked_sausage":
			shadow(ci, Vector2(0, 5), 24, 7, Color(0.2, 0.14, 0.1, 0.13))
			var sausage_color := _cook_state_color(quality)
			var outline_color := INK if quality != "burnt" else Color(0.16, 0.12, 0.11)
			capsule(ci, Vector2(-18, 0), Vector2(18, 0), sausage_color, 15.0, false)
			ci.draw_line(Vector2(-18, 0), Vector2(18, 0), outline_color, 18.0, true)
			ci.draw_line(Vector2(-18, 0), Vector2(18, 0), sausage_color, 15.0, true)
			ci.draw_circle(Vector2(-18, 0), 7.5, sausage_color)
			ci.draw_circle(Vector2(18, 0), 7.5, sausage_color)
			ci.draw_line(Vector2(-10, -3), Vector2(8, -3), Color(1, 0.94, 0.82, 0.42), 2.4, true)
			if quality in ["perfect", "overcooked", "burnt"]:
				ci.draw_line(Vector2(-7, 4), Vector2(2, -5), Color(0.36, 0.20, 0.12, 0.65), 2.0, true)
				ci.draw_line(Vector2(5, 4), Vector2(13, -4), Color(0.36, 0.20, 0.12, 0.65), 2.0, true)
		"hotdog":
			shadow(ci, Vector2(0, 8), 30, 8, Color(0.2, 0.14, 0.1, 0.14))
			ci.draw_colored_polygon(ellipse_points(Vector2(0, 3), 30, 14), Color(0.73, 0.43, 0.21))
			ci.draw_polyline(_closed(ellipse_points(Vector2(0, 3), 30, 14)), INK, 2.2, true)
			ci.draw_colored_polygon(ellipse_points(Vector2(0, -1), 28, 13), Color(0.96, 0.68, 0.36))
			ci.draw_polyline(_closed(ellipse_points(Vector2(0, -1), 28, 13)), INK, 2.2, true)
			var sausage_color := _cook_state_color(quality)
			capsule(ci, Vector2(-22, -5), Vector2(22, -5), sausage_color, 13.0, true)
			ci.draw_line(Vector2(-14, -8), Vector2(8, -8), Color(1, 1, 1, 0.32), 2.0, true)
			if bool(sauces.get("ketchup", false)):
				_draw_sauce_wave(ci, TOMATO, -3.0)
			if bool(sauces.get("mustard", false)):
				_draw_sauce_wave(ci, MUSTARD, 3.0)
		"bun_basket":
			draw_food_icon(ci, "bun", Vector2(-10, 0), 0.8, quality, sauces)
		_:
			ci.draw_circle(Vector2.ZERO, 12, LIGHT_GRAY)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _cook_state_color(id: String) -> Color:
	match id:
		"raw":
			return PINK
		"heating":
			return Color(0.82, 0.55, 0.42)
		"just_right":
			return Color(0.78, 0.48, 0.28)
		"perfect":
			return Color(0.68, 0.36, 0.18)
		"overcooked":
			return Color(0.45, 0.25, 0.13)
		"burnt":
			return Color(0.20, 0.14, 0.11)
		_:
			return Color(0.66, 0.40, 0.24)


static func _draw_sauce_wave(ci: CanvasItem, color: Color, y_offset: float) -> void:
	var points := PackedVector2Array()
	for i in range(11):
		var t := float(i) / 10.0
		points.append(Vector2(-20.0 + 40.0 * t, -5.0 + y_offset + sin(t * PI * 3.0) * 2.6))
	ci.draw_polyline(points, color, 3.2, true)


static func draw_item_icon(ci: CanvasItem, item: Dictionary, center: Vector2, scale: float = 1.0) -> void:
	if item.is_empty():
		return
	match str(item.get("type", "")):
		"raw_sausage":
			draw_food_icon(ci, "raw_sausage", center, scale)
		"cooked_sausage":
			draw_food_icon(ci, "cooked_sausage", center, scale, str(item.get("quality", "perfect")))
		"bun":
			draw_food_icon(ci, "bun", center, scale)
		"hotdog":
			draw_food_icon(ci, "hotdog", center, scale, str(item.get("quality", "perfect")),
				item.get("sauces", {}))


static func draw_sauce_bottle(ci: CanvasItem, center: Vector2, color: Color, scale: float = 1.0) -> void:
	ci.draw_set_transform(center, 0.0, Vector2(scale, scale))
	shadow(ci, Vector2(0, 20), 14, 5, Color(0.2, 0.14, 0.1, 0.16))
	panel(ci, Rect2(-12, -12, 24, 34), 8, color, INK, 2.0, false)
	ci.draw_rect(Rect2(-6, -21, 12, 10), color)
	ci.draw_rect(Rect2(-6, -21, 12, 10), INK, false, 2.0)
	ci.draw_rect(Rect2(-3, -28, 6, 7), INK)
	ci.draw_line(Vector2(-6, -4), Vector2(6, -4), Color(1, 1, 1, 0.55), 3.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_avatar(ci: CanvasItem, center: Vector2, species: String, fur: Color, accent: Color,
		shirt: Color, scale: float = 1.0) -> void:
	ci.draw_set_transform(center, 0.0, Vector2(scale, scale))
	# 身体
	panel(ci, Rect2(-17, -2, 34, 26), 10, shirt, INK, 2.0, false)
	# 耳朵先画，露在头后
	_draw_animal_ears(ci, species, fur, accent, false)
	# 头
	ci.draw_circle(Vector2(0, -22), 23, fur)
	ci.draw_arc(Vector2(0, -22), 23, 0.0, TAU, 32, INK, 2.2, true)
	_draw_animal_ears(ci, species, fur, accent, true)
	# 脸
	match species:
		"panda":
			ci.draw_circle(Vector2(-9, -24), 7.5, accent)
			ci.draw_circle(Vector2(9, -24), 7.5, accent)
		"frog":
			ci.draw_circle(Vector2(-10, -40), 7, fur)
			ci.draw_circle(Vector2(10, -40), 7, fur)
	ci.draw_circle(Vector2(-8, -24), 2.4, INK)
	ci.draw_circle(Vector2(8, -24), 2.4, INK)
	ci.draw_circle(Vector2(-7.2, -24.8), 0.8, WHITE)
	ci.draw_circle(Vector2(8.8, -24.8), 0.8, WHITE)
	ci.draw_arc(Vector2(0, -15), 5.0, 0.2, PI - 0.2, 10, INK, 1.8, true)
	ci.draw_circle(Vector2(-15, -17), 3.5, Color(0.95, 0.55, 0.55, 0.45))
	ci.draw_circle(Vector2(15, -17), 3.5, Color(0.95, 0.55, 0.55, 0.45))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_animal_ears(ci: CanvasItem, species: String, fur: Color, accent: Color,
		front_layer: bool) -> void:
	match species:
		"cat":
			if front_layer:
				return
			for side in [-1.0, 1.0]:
				var points := PackedVector2Array([
					Vector2(side * 8, -40), Vector2(side * 22, -53), Vector2(side * 22, -33)
				])
				ci.draw_colored_polygon(points, fur)
				ci.draw_polyline(_closed(points), INK, 2.0, true)
				ci.draw_colored_polygon(PackedVector2Array([
					Vector2(side * 14, -42), Vector2(side * 19, -48), Vector2(side * 18, -38)
				]), accent)
		"rabbit":
			if not front_layer:
				return
			for side in [-1.0, 1.0]:
				var rect := Rect2(Vector2(side * 14 - 7 if side > 0 else side * 14 - 7, -67), Vector2(14, 30))
				panel(ci, rect, 7, fur, INK, 2.0, false)
				ci.draw_line(Vector2(side * 14, -60), Vector2(side * 14, -41), accent, 5.0, true)
		"bear", "panda":
			if not front_layer:
				return
			ci.draw_circle(Vector2(-18, -41), 8, accent if species == "panda" else fur)
			ci.draw_arc(Vector2(-18, -41), 8, 0.0, TAU, 20, INK, 2.0, true)
			ci.draw_circle(Vector2(18, -41), 8, accent if species == "panda" else fur)
			ci.draw_arc(Vector2(18, -41), 8, 0.0, TAU, 20, INK, 2.0, true)
		"dog":
			if not front_layer:
				return
			for side in [-1.0, 1.0]:
				ci.draw_colored_polygon(ellipse_points(Vector2(side * 22, -27), 9, 16), accent)
				ci.draw_polyline(_closed(ellipse_points(Vector2(side * 22, -27), 9, 16)), INK, 2.0, true)
		"frog":
			if not front_layer:
				return
			ci.draw_arc(Vector2(0, -29), 25, PI + 0.18, TAU - 0.18, 24, accent, 3.0, true)
