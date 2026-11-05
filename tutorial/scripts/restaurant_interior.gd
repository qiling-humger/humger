class_name RestaurantInterior
extends Node2D
## Restaurant interior map design (placeholder art, no new textures).

const COLS := 10
const ROWS := 7
const CELL_W := 76.0
const CELL_H := 38.0
const CENTER := Vector2(640, 360)
const DOOR_CELL := Vector2i(4, 6)

var _floor_origin := Vector2.ZERO
var _table_sprite: Texture2D


func _ready() -> void:
	_table_sprite = load("res://assets/art_style_v2_test/furniture/transparent/table.png")
	_add_table(Vector2i(2, 2))
	_add_table(Vector2i(5, 2))
	_add_table(Vector2i(7, 4))
	var customer := TutorialActor.new()
	customer.setup("cat_customer", "顾客", Color(0.94, 0.66, 0.38))
	customer.position = _cell_center(Vector2i(5, 3))
	customer.order_text = "欢迎光临"
	add_child(customer)
	var player := TutorialActor.new()
	player.setup("rabbit_customer", "你", Color(0.96, 0.92, 0.84))
	player.position = _cell_center(Vector2i(4, 6))
	add_child(player)
	queue_redraw()


func _cell_center(cell: Vector2i) -> Vector2:
	return CENTER + Vector2(
		(float(cell.x) - float(cell.y)) * CELL_W * 0.5,
		(float(cell.x) + float(cell.y)) * CELL_H * 0.5 - 140.0
	)


func _add_table(cell: Vector2i) -> void:
	if _table_sprite == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = _table_sprite
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var table_scale := 0.10
	sprite.scale = Vector2(table_scale, table_scale)
	var p := _cell_center(cell)
	sprite.position = p + Vector2(
		-float(_table_sprite.get_width()) * table_scale * 0.5,
		-float(_table_sprite.get_height()) * table_scale)
	add_child(sprite)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.08, 0.15, 0.18))
	# Floor.
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
	# Back walls.
	if true:
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
	# Kitchen counter / stove (placeholders).
	var counter := _cell_center(Vector2i(1, 1))
	draw_colored_polygon(PackedVector2Array([
		counter + Vector2(-90, -30), counter + Vector2(0, -60),
		counter + Vector2(90, -30), counter + Vector2(0, 0)
	]), Color(0.86, 0.60, 0.38))
	draw_line(counter + Vector2(-90, -30), counter + Vector2(0, 0),
		Color(0.42, 0.24, 0.16), 2.0, true)
	draw_line(counter + Vector2(90, -30), counter + Vector2(0, 0),
		Color(0.42, 0.24, 0.16), 2.0, true)
	var stove := _cell_center(Vector2i(2, 1))
	Painter.iso_box(self, stove + Vector2(0, 8), 50, 25, 30,
		Color(0.72, 0.68, 0.62), Color(0.56, 0.52, 0.48),
		Color(0.42, 0.38, 0.34), Painter.INK, 2.0)
	# Door.
	var door := _cell_center(Vector2i(DOOR_CELL.x, DOOR_CELL.y + 1))
	draw_colored_polygon(PackedVector2Array([
		door + Vector2(-45, 0), door + Vector2(0, -22),
		door + Vector2(45, 0), door + Vector2(0, 22)
	]), Color(0.24, 0.14, 0.10))
	draw_colored_polygon(PackedVector2Array([
		door + Vector2(-35, 4), door + Vector2(0, -14),
		door + Vector2(35, 4), door + Vector2(0, 18)
	]), Color(0.86, 0.70, 0.46))
	Painter.draw_centered(self, "厨房", counter + Vector2(0, -48), 14,
		Color(0.30, 0.20, 0.14), true)
	Painter.draw_centered(self, "取餐台", counter + Vector2(120, 16), 12,
		Color(0.30, 0.20, 0.14), true)
	Painter.draw_centered(self, "入口", door + Vector2(0, -34), 13,
		Color(0.30, 0.20, 0.14), true)
	# UI labels.
	Painter.panel(self, Rect2(Vector2(24, 24), Vector2(330, 64)), 14,
		Color(1.0, 0.973, 0.925, 0.96), Color(0.46, 0.34, 0.24), 1.6, true)
	Painter.draw_text(self, "餐厅内部 · 地图设计", Vector2(42, 54), 20,
		Painter.BROWN_DARK, true)
	Painter.draw_text(self, "厨房 / 取餐台 / 餐桌 / 入口", Vector2(42, 76), 11,
		Color(0.48, 0.38, 0.29), false)
	Painter.panel(self, Rect2(Vector2(940, 90), Vector2(300, 150)), 14,
		Color(1.0, 0.973, 0.925, 0.94), Color(0.46, 0.34, 0.24), 1.4, true)
	Painter.draw_text(self, "餐厅内部布局", Vector2(960, 120), 15,
		Painter.BROWN_DARK, true)
	Painter.draw_text(self, "北：厨房 / 灶台", Vector2(960, 150), 12,
		Color(0.40, 0.32, 0.24), false)
	Painter.draw_text(self, "中：取餐台 / 餐桌", Vector2(960, 174), 12,
		Color(0.40, 0.32, 0.24), false)
	Painter.draw_text(self, "南：入口 / 返回岛屿", Vector2(960, 198), 12,
		Color(0.40, 0.32, 0.24), false)
	Painter.panel(self, Rect2(Vector2(400, 650), Vector2(480, 46)), 13,
		Color(1.0, 0.973, 0.925, 0.96), Color(0.46, 0.34, 0.24), 1.4, true)
	Painter.draw_centered(self, "按 E / Esc 返回岛屿", Vector2(640, 679), 14,
		Painter.BROWN_DARK, true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key == KEY_E or key == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://tutorial/TutorialLevel.tscn")
			get_viewport().set_input_as_handled()
