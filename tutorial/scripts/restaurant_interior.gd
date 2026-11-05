class_name RestaurantInterior
extends Node2D
## Restaurant interior map with draggable, grid-snapped kitchen furniture.
## Placeholder shapes only; the V2 outdoor art is untouched.

const COLS := 10
const ROWS := 7
const CELL_W := 96.0
const CELL_H := 48.0
const CENTER := Vector2(640, 360)
const Y_OFFSET := 140.0
const DOOR_CELL := Vector2i(4, 6)

var furniture: Array[RestaurantFurniture] = []
var dragging: RestaurantFurniture = null
var cell_owner: Dictionary = {}


func _ready() -> void:
	_build_layout()
	_add_actor("cat_customer", "顾客", Color(0.94, 0.66, 0.38), Vector2i(2, 4))
	_add_actor("rabbit_customer", "你", Color(0.96, 0.92, 0.84), DOOR_CELL)
	queue_redraw()


func _build_layout() -> void:
	var defs := [
		["mixer", "搅", Vector2i(1, 1), Vector2i(1, 1)],
		["knife", "刀", Vector2i(2, 1), Vector2i(1, 1)],
		["cutting_board", "板", Vector2i(3, 1), Vector2i(1, 1)],
		["plate", "盘", Vector2i(4, 1), Vector2i(1, 1)],
		["shelf", "架", Vector2i(5, 1), Vector2i(2, 1)],
		["sink", "池", Vector2i(1, 2), Vector2i(2, 1)],
		["dishwasher", "洗", Vector2i(4, 2), Vector2i(2, 1)],
		["table", "桌", Vector2i(2, 3), Vector2i(2, 1)],
		["table", "桌", Vector2i(6, 3), Vector2i(2, 1)],
		["chair", "椅", Vector2i(2, 5), Vector2i(1, 1)],
		["chair", "椅", Vector2i(3, 5), Vector2i(1, 1)],
		["chair", "椅", Vector2i(6, 5), Vector2i(1, 1)],
		["chair", "椅", Vector2i(7, 5), Vector2i(1, 1)],
	]
	for entry in defs:
		_spawn_furniture(str(entry[0]), str(entry[1]),
			entry[2] as Vector2i, entry[3] as Vector2i)
	_rebuild_owner()


func _spawn_furniture(kind: String, label: String, cell: Vector2i,
		footprint: Vector2i) -> void:
	var piece := RestaurantFurniture.new()
	piece.setup(kind, label, cell, footprint, _cell_center(cell),
		Vector2(CELL_W, CELL_H))
	add_child(piece)
	furniture.append(piece)


func _add_actor(kind: String, label: String, color: Color, cell: Vector2i) -> void:
	var actor := TutorialActor.new()
	actor.setup(kind, label, color)
	actor.position = _cell_center(cell)
	actor.z_index = 20
	add_child(actor)


func _cell_center(cell: Vector2i) -> Vector2:
	return CENTER + Vector2(
		(float(cell.x) - float(cell.y)) * CELL_W * 0.5,
		(float(cell.x) + float(cell.y)) * CELL_H * 0.5 - Y_OFFSET
	)


func _screen_to_cell(point: Vector2) -> Vector2i:
	var p := point - CENTER + Vector2(0, Y_OFFSET)
	var fx := p.x / (CELL_W * 0.5)
	var fy := p.y / (CELL_H * 0.5)
	return Vector2i(floori((fx + fy) * 0.5), floori((fy - fx) * 0.5))


func _in_room(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < COLS and cell.y < ROWS


func _rebuild_owner() -> void:
	cell_owner.clear()
	for piece in furniture:
		for cell in piece.footprint_cells():
			cell_owner[cell] = piece


func _furniture_at(cell: Vector2i) -> RestaurantFurniture:
	return cell_owner.get(cell) as RestaurantFurniture


func _can_place(piece: RestaurantFurniture, at: Vector2i) -> bool:
	for cell in piece.footprint_cells(at):
		if not _in_room(cell):
			return false
		if cell_owner.has(cell) and cell_owner[cell] != piece:
			return false
	return true


func _move_to(piece: RestaurantFurniture, at: Vector2i) -> void:
	piece.set_cell(at, _cell_center(at))
	_rebuild_owner()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key == KEY_E or key == KEY_ESCAPE:
			if dragging != null:
				_finish_drag(false)
			else:
				get_tree().change_scene_to_file("res://tutorial/TutorialLevel.tscn")
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var cell := _screen_to_cell(get_global_mouse_position())
				var piece := _furniture_at(cell)
				if piece != null:
					dragging = piece
					dragging.drag_origin = dragging.cell
					dragging.is_dragging = true
					dragging.z_index = 100
					dragging.modulate = Color(1.0, 0.96, 0.76)
					get_viewport().set_input_as_handled()
			elif dragging != null:
				_finish_drag(true)
				get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and dragging != null:
		var at := _screen_to_cell(get_global_mouse_position())
		if _in_room(at):
			dragging.set_cell(at, _cell_center(at))
			dragging.modulate = Color(1.0, 1.0, 1.0) \
				if _can_place(dragging, at) else Color(1.0, 0.55, 0.50)
		get_viewport().set_input_as_handled()


func _finish_drag(commit: bool) -> void:
	if dragging == null:
		return
	var target := dragging.cell
	var valid := commit and _can_place(dragging, target)
	if valid:
		_move_to(dragging, target)
	else:
		_move_to(dragging, dragging.drag_origin)
	dragging.modulate = Color.WHITE
	dragging.z_index = 0
	dragging.is_dragging = false
	dragging = null


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.08, 0.15, 0.18))
	for y in range(ROWS):
		for x in range(COLS):
			var c := _cell_center(Vector2i(x, y))
			var pts := PackedVector2Array([
				c + Vector2(0, -CELL_H * 0.5),
				c + Vector2(CELL_W * 0.5, 0),
				c + Vector2(0, CELL_H * 0.5),
				c + Vector2(-CELL_W * 0.5, 0)
			])
			draw_colored_polygon(pts, Color(0.55, 0.34, 0.22))
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, Color(0.36, 0.22, 0.14, 0.8), 1.2, true)
	# Back walls keep the room readable from the isometric camera.
	var left := PackedVector2Array([
		_cell_center(Vector2i(0, 0)) + Vector2(0, -CELL_H * 0.5),
		_cell_center(Vector2i(0, ROWS - 1)) + Vector2(0, -CELL_H * 0.5),
		_cell_center(Vector2i(0, ROWS - 1)) + Vector2(0, -CELL_H * 0.5 + 100),
		_cell_center(Vector2i(0, 0)) + Vector2(0, -CELL_H * 0.5 + 100)
	])
	draw_colored_polygon(left, Color(0.72, 0.46, 0.31))
	var right := PackedVector2Array([
		_cell_center(Vector2i(0, 0)) + Vector2(0, -CELL_H * 0.5),
		_cell_center(Vector2i(COLS - 1, 0)) + Vector2(0, -CELL_H * 0.5),
		_cell_center(Vector2i(COLS - 1, 0)) + Vector2(0, -CELL_H * 0.5 + 100),
		_cell_center(Vector2i(0, 0)) + Vector2(0, -CELL_H * 0.5 + 100)
	])
	draw_colored_polygon(right, Color(0.82, 0.56, 0.38))
	var door := _cell_center(Vector2i(DOOR_CELL.x, DOOR_CELL.y + 1))
	draw_colored_polygon(PackedVector2Array([
		door + Vector2(-45, 0), door + Vector2(0, -22),
		door + Vector2(45, 0), door + Vector2(0, 22)
	]), Color(0.24, 0.14, 0.10))
	draw_colored_polygon(PackedVector2Array([
		door + Vector2(-35, 4), door + Vector2(0, -14),
		door + Vector2(35, 4), door + Vector2(0, 18)
	]), Color(0.86, 0.70, 0.46))
	# Zone labels.
	Painter.draw_centered(self, "厨房区", _cell_center(Vector2i(3, 0)) + Vector2(0, 28), 13,
		Color(0.30, 0.20, 0.14), true)
	Painter.draw_centered(self, "用餐区", _cell_center(Vector2i(5, 4)) + Vector2(0, 24), 13,
		Color(0.30, 0.20, 0.14), true)
	Painter.draw_centered(self, "入口", door + Vector2(0, -34), 13,
		Color(0.30, 0.20, 0.14), true)
	# Header / instructions.
	Painter.panel(self, Rect2(Vector2(24, 24), Vector2(390, 86)), 14,
		Color(1.0, 0.973, 0.925, 0.96), Color(0.46, 0.34, 0.24), 1.6, true)
	Painter.draw_text(self, "餐厅内部 · 厨房布局", Vector2(42, 54), 20,
		Painter.BROWN_DARK, true)
	Painter.draw_text(self, "拖动设备/桌椅移动，松开后吸附网格", Vector2(42, 78), 11,
		Color(0.48, 0.38, 0.29), false)
	Painter.draw_text(self, "搅拌器 / 菜刀 / 菜板 / 水池 / 货架 / 餐盘 / 洗碗台", Vector2(42, 96), 10,
		Color(0.48, 0.38, 0.29), false)
	Painter.panel(self, Rect2(Vector2(940, 90), Vector2(300, 232)), 14,
		Color(1.0, 0.973, 0.925, 0.94), Color(0.46, 0.34, 0.24), 1.4, true)
	Painter.draw_text(self, "设备清单", Vector2(960, 120), 15,
		Painter.BROWN_DARK, true)
	var legend := [
		"搅拌器 / 菜刀 / 菜板", "水池 / 货架 / 餐盘",
		"洗碗台 / 餐桌 / 椅子", "全部可拖动并吸附网格",
	]
	for i in range(legend.size()):
		Painter.draw_text(self, legend[i], Vector2(960, 150 + i * 24), 11,
			Color(0.40, 0.32, 0.24), false)
	Painter.draw_text(self, "北：厨房区 · 南：入口", Vector2(960, 258), 11,
		Color(0.40, 0.32, 0.24), false)
	Painter.panel(self, Rect2(Vector2(400, 650), Vector2(480, 46)), 13,
		Color(1.0, 0.973, 0.925, 0.96), Color(0.46, 0.34, 0.24), 1.4, true)
	Painter.draw_centered(self, "拖动家具 · 按 E / Esc 返回岛屿", Vector2(640, 679), 14,
		Painter.BROWN_DARK, true)
