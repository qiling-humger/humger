class_name IslandPlaceable
extends Node2D
## 玩家可建造/搬动的多格物件。逻辑占格由 origin + size 决定，
## 视觉挂点放在最前排格子，保证与小白兔的 Y 排序正确。

var object_id := ""
var def: Dictionary = {}
var origin := Vector2i.ZERO
var base_size := Vector2i.ONE
var size := Vector2i.ONE
var rotation_quarters := 0
var blocking := true
var grid: IslandGrid
var game: Node

var _dragging := false
var _time := 0.0


static func rotated_size(base: Vector2i, quarters: int) -> Vector2i:
	return base if posmod(quarters, 4) % 2 == 0 else Vector2i(base.y, base.x)


func setup(id_value: String, definition: Dictionary, origin_value: Vector2i,
		grid_ref: IslandGrid, game_ref: Node, rotation_value := 0) -> void:
	object_id = id_value
	def = definition.duplicate(true)
	origin = origin_value
	base_size = Vector2i(int(def.get("width", 1)), int(def.get("height", 1)))
	rotation_quarters = posmod(rotation_value, 4)
	size = rotated_size(base_size, rotation_quarters)
	blocking = bool(def.get("blocking", true))
	grid = grid_ref
	game = game_ref
	_place_node()
	queue_redraw()


func set_origin(new_origin: Vector2i) -> void:
	origin = new_origin
	_place_node()
	_visual_transform_changed()
	queue_redraw()


func set_rotation_quarters(value: int) -> void:
	var next_rotation := posmod(value, 4)
	if next_rotation == rotation_quarters:
		return
	rotation_quarters = next_rotation
	size = rotated_size(base_size, rotation_quarters)
	_place_node()
	_visual_transform_changed()
	queue_redraw()


func _visual_transform_changed() -> void:
	pass


func get_cells() -> Array[Vector2i]:
	return grid.footprint_cells(origin, size)


func get_footprint_center() -> Vector2:
	var center_cell := Vector2(
		float(origin.x) + (float(size.x) - 1.0) * 0.5,
		float(origin.y) + (float(size.y) - 1.0) * 0.5
	)
	return grid.world_from_float(center_cell)


func contains_cell(cell: Vector2i) -> bool:
	return cell.x >= origin.x and cell.y >= origin.y \
		and cell.x < origin.x + size.x and cell.y < origin.y + size.y


func set_dragging(value: bool) -> void:
	_dragging = value
	modulate = Color(1, 1, 1, 0.32) if value else Color.WHITE
	queue_redraw()


func _place_node() -> void:
	var front := grid.front_cell(origin, size)
	position = grid.cell_to_world(front)


func _process(delta: float) -> void:
	_time += delta
	if _dragging:
		queue_redraw()


func _draw() -> void:
	var center := get_footprint_center() - position
	_draw_footprint_pads()
	match str(def.get("draw", "")):
		"crate":
			_draw_crate(center)
		"table":
			_draw_table(center)
		"picnic":
			_draw_picnic(center)
		"restaurant":
			_draw_restaurant(center)
		_:
			_draw_fallback(center)


func _draw_footprint_pads() -> void:
	for cell in get_cells():
		var rel := grid.cell_to_world(cell) - position
		var points := PackedVector2Array([
			rel + Vector2(0, -15),
			rel + Vector2(30, 0),
			rel + Vector2(0, 15),
			rel + Vector2(-30, 0),
		])
		draw_colored_polygon(points, Color(1.0, 0.92, 0.70, 0.10))
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, Color(0.48, 0.36, 0.24, 0.16), 1.0, true)


func _draw_crate(center: Vector2) -> void:
	var base := center + Vector2(0, 9)
	Painter.iso_box(self, base, 48, 24, 31,
		Color(0.847, 0.635, 0.400), Color(0.690, 0.463, 0.282),
		Color(0.573, 0.369, 0.235), Painter.INK, 2.0)
	# 木箱板条
	var top := base - Vector2(0, 31)
	draw_line(top + Vector2(-13, 6), top + Vector2(0, 12), Color(0.45, 0.28, 0.18, 0.55), 1.5, true)
	draw_line(top + Vector2(13, 6), top + Vector2(0, 12), Color(0.45, 0.28, 0.18, 0.55), 1.5, true)
	draw_line(base + Vector2(-18, 2), base + Vector2(-5, 8), Color(0.45, 0.28, 0.18, 0.45), 1.4, true)


func _draw_table(center: Vector2) -> void:
	var base := center + Vector2(0, 8)
	Painter.iso_box(self, base, 90, 44, 27,
		Color(0.929, 0.714, 0.490), Color(0.780, 0.529, 0.337),
		Color(0.655, 0.420, 0.259), Painter.INK, 2.2)
	# 桌腿
	var leg_color := Color(0.420, 0.271, 0.188)
	draw_line(base + Vector2(-27, 12), base + Vector2(-27, 32), leg_color, 3.5, true)
	draw_line(base + Vector2(27, 12), base + Vector2(27, 32), leg_color, 3.5, true)
	# 小杯子
	var cup := base + Vector2(-10, -15)
	draw_circle(cup, 6.0, Painter.CREAM)
	draw_arc(cup, 6.0, 0, TAU, 18, Painter.INK, 1.4, true)
	draw_line(cup + Vector2(6, -3), cup + Vector2(12, -5), Painter.INK, 1.6, true)
	Painter.shadow(self, base + Vector2(0, 10), 42, 12, Color(0, 0, 0, 0.08))


func _draw_picnic(center: Vector2) -> void:
	# 野餐垫
	var mat_center := center + Vector2(0, 9)
	var mat := PackedVector2Array([
		mat_center + Vector2(0, -30), mat_center + Vector2(58, 0),
		mat_center + Vector2(0, 30), mat_center + Vector2(-58, 0)
	])
	Painter.outline_polygon(self, mat, Color(0.902, 0.541, 0.478), Color(0.65, 0.34, 0.29), 2.0)
	# 格纹
	for i in range(3):
		var t := float(i + 1) / 4.0
		var a1: Vector2 = mat[0].lerp(mat[1], t)
		var b1: Vector2 = mat[3].lerp(mat[2], t)
		var a2: Vector2 = mat[0].lerp(mat[3], t)
		var b2: Vector2 = mat[1].lerp(mat[2], t)
		draw_line(a1, b1, Color(1.0, 0.89, 0.78, 0.32), 1.3, true)
		draw_line(a2, b2, Color(1.0, 0.89, 0.78, 0.32), 1.3, true)
	# 低矮野餐桌
	var table_center := center + Vector2(-2, -6)
	Painter.iso_box(self, table_center + Vector2(0, 10), 55, 27, 25,
		Color(0.929, 0.733, 0.506), Color(0.761, 0.490, 0.322),
		Color(0.627, 0.384, 0.243), Painter.INK, 2.0)
	# 两个靠垫
	draw_circle(center + Vector2(-42, -2), 8.0, Color(0.447, 0.690, 0.620))
	draw_arc(center + Vector2(-42, -2), 8.0, 0, TAU, 18, Painter.INK, 1.4, true)
	draw_circle(center + Vector2(39, 8), 7.5, Color(0.973, 0.831, 0.463))
	draw_arc(center + Vector2(39, 8), 7.5, 0, TAU, 18, Painter.INK, 1.4, true)
	# 小遮阳伞
	draw_line(center + Vector2(38, 4), center + Vector2(38, -52), Color(0.58, 0.38, 0.24), 2.5, true)
	var canopy := PackedVector2Array([
		center + Vector2(38, -54), center + Vector2(69, -42),
		center + Vector2(38, -31), center + Vector2(7, -42)
	])
	Painter.outline_polygon(self, canopy, Color(0.953, 0.812, 0.451), Painter.INK, 1.8)
	draw_line(center + Vector2(38, -54), center + Vector2(38, -31), Color(0.58, 0.38, 0.24, 0.55), 1.3, true)


func _draw_restaurant(center: Vector2) -> void:
	# 3×3 目标建筑，视觉上仍保持小体量，方便看清占格。
	var base := center + Vector2(0, 18)
	Painter.shadow(self, base + Vector2(0, 12), 92, 22, Color(0.16, 0.20, 0.14, 0.18))
	Painter.iso_box(self, base, 142, 70, 58,
		Color(0.973, 0.886, 0.694), Color(0.941, 0.737, 0.549),
		Color(0.780, 0.541, 0.365), Painter.INK, 2.4)
	# 屋顶
	var roof_base := base - Vector2(0, 58)
	var roof := PackedVector2Array([
		roof_base + Vector2(0, -40), roof_base + Vector2(92, -4),
		roof_base + Vector2(0, 32), roof_base + Vector2(-92, -4)
	])
	Painter.outline_polygon(self, roof, Color(0.396, 0.694, 0.596), Painter.INK, 2.4)
	draw_line(roof_base + Vector2(0, -40), roof_base + Vector2(0, 32),
		Color(1, 1, 1, 0.24), 2.0, true)
	# 前檐彩色条纹
	var awning := PackedVector2Array([
		roof_base + Vector2(-62, 4), roof_base + Vector2(0, 34),
		roof_base + Vector2(62, 4), roof_base + Vector2(0, 20)
	])
	Painter.outline_polygon(self, awning, Color(0.961, 0.780, 0.525), Painter.INK, 1.8)
	for i in range(4):
		var x := -45.0 + float(i) * 30.0
		draw_line(roof_base + Vector2(x, 8), roof_base + Vector2(x + 14, 13),
			Painter.CORAL if i % 2 == 0 else Painter.CREAM, 4.0, true)
	# 门和窗
	var door := Rect2(base + Vector2(-20, -32), Vector2(28, 43))
	Painter.panel(self, door, 4, Color(0.694, 0.435, 0.290), Painter.INK, 1.7, false)
	draw_circle(door.position + Vector2(20, 23), 2.0, Painter.BUTTER)
	var window := Rect2(base + Vector2(19, -28), Vector2(26, 23))
	Painter.panel(self, window, 4, Color(0.690, 0.878, 0.902), Painter.INK, 1.6, false)
	draw_line(window.position + Vector2(13, 0), window.position + Vector2(13, 23),
		Painter.INK, 1.3, true)
	draw_line(window.position + Vector2(0, 11), window.position + Vector2(26, 11),
		Painter.INK, 1.3, true)
	# 招牌
	var sign_rect := Rect2(roof_base + Vector2(-45, -88), Vector2(90, 30))
	Painter.panel(self, sign_rect, 9, Painter.CREAM, Painter.INK, 1.8, true)
	Painter.draw_centered(self, "小餐厅", sign_rect.position + Vector2(45, 21), 15,
		Painter.BROWN_DARK, true)
	draw_line(sign_rect.position + Vector2(18, -4), sign_rect.position + Vector2(18, -12),
		Color(0.42, 0.28, 0.18), 2.0, true)
	draw_line(sign_rect.position + Vector2(72, -4), sign_rect.position + Vector2(72, -12),
		Color(0.42, 0.28, 0.18), 2.0, true)


func _draw_fallback(center: Vector2) -> void:
	Painter.iso_box(self, center + Vector2(0, 8), 52, 26, 28,
		Color(0.8, 0.7, 0.5), Color(0.7, 0.55, 0.4),
		Color(0.55, 0.4, 0.3), Painter.INK, 2.0)
