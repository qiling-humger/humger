class_name RestaurantFurniture
extends Node2D
## A draggable placeholder furniture piece for the restaurant interior.

var kind := ""
var label := ""
var cell := Vector2i.ZERO
var footprint := Vector2i.ONE
var cell_center := Vector2.ZERO
var cell_size := Vector2(76, 38)
var drag_origin := Vector2i.ZERO
var is_dragging := false


func setup(p_kind: String, p_label: String, p_cell: Vector2i,
		p_footprint: Vector2i, p_center: Vector2, p_cell_size: Vector2) -> void:
	kind = p_kind
	label = p_label
	cell = p_cell
	drag_origin = p_cell
	footprint = p_footprint
	cell_center = p_center
	cell_size = p_cell_size
	position = cell_center
	queue_redraw()


func set_cell(value: Vector2i, center: Vector2) -> void:
	cell = value
	position = center
	queue_redraw()


func footprint_cells(at: Vector2i = cell) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(footprint.y):
		for x in range(footprint.x):
			out.append(at + Vector2i(x, y))
	return out


func _draw() -> void:
	var shadow := PackedVector2Array()
	var rw := cell_size.x * (float(footprint.x) * 0.5 + 0.12)
	var rh := cell_size.y * (float(footprint.y) * 0.5 + 0.12)
	shadow.append_array(Painter.ellipse_points(Vector2(0, 2), rw, rh))
	draw_colored_polygon(shadow, Color(0.16, 0.09, 0.06, 0.20))

	match kind:
		"mixer":
			_draw_mixer()
		"knife":
			_draw_knife()
		"cutting_board":
			_draw_board()
		"sink":
			_draw_sink()
		"shelf":
			_draw_shelf()
		"plate":
			_draw_plate()
		"dishwasher":
			_draw_dishwasher()
		"table":
			_draw_table()
		"chair":
			_draw_chair()
		_:
			_draw_table()

	if not label.is_empty():
		Painter.draw_centered(self, label, Vector2(0, 30), 11,
			Color(0.22, 0.14, 0.09, 0.95), true)


func _draw_mixer() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-25, 8), Vector2(15, 8), Vector2(20, -14), Vector2(-20, -14)
	]), Color(0.72, 0.74, 0.76))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, -14), Vector2(10, -14), Vector2(7, -35), Vector2(-10, -35)
	]), Color(0.84, 0.90, 0.91))
	draw_line(Vector2(0, -35), Vector2(0, -46), Color(0.45, 0.45, 0.47), 4)
	draw_circle(Vector2(0, -46), 7, Color(0.36, 0.36, 0.38))
	draw_line(Vector2(-16, 16), Vector2(-16, 32), Color(0.42, 0.42, 0.44), 3)
	draw_line(Vector2(16, 16), Vector2(16, 32), Color(0.42, 0.42, 0.44), 3)


func _draw_knife() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-28, -4), Vector2(18, -14), Vector2(28, 6), Vector2(-20, 10)
	]), Color(0.82, 0.84, 0.86))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20, 10), Vector2(-10, 8), Vector2(-6, 20), Vector2(-18, 22)
	]), Color(0.34, 0.22, 0.14))
	draw_line(Vector2(-28, -4), Vector2(18, -14), Color(0.96, 0.97, 0.98), 2)


func _draw_board() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-30, -8), Vector2(30, -8), Vector2(24, 16), Vector2(-24, 16)
	]), Color(0.68, 0.44, 0.25))
	draw_line(Vector2(-20, 1), Vector2(20, 1), Color(0.48, 0.29, 0.16), 2)
	draw_line(Vector2(-16, 8), Vector2(16, 8), Color(0.48, 0.29, 0.16), 2)


func _draw_sink() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-34, -12), Vector2(34, -12), Vector2(28, 16), Vector2(-28, 16)
	]), Color(0.76, 0.77, 0.78))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-23, -5), Vector2(23, -5), Vector2(18, 12), Vector2(-18, 12)
	]), Color(0.42, 0.67, 0.72))
	draw_line(Vector2(-8, -12), Vector2(-8, -32), Color(0.5, 0.5, 0.52), 4)
	draw_line(Vector2(-8, -32), Vector2(12, -32), Color(0.5, 0.5, 0.52), 4)


func _draw_shelf() -> void:
	draw_rect(Rect2(Vector2(-38, -24), Vector2(76, 42)),
		Color(0.58, 0.35, 0.20))
	draw_rect(Rect2(Vector2(-30, -17), Vector2(60, 12)),
		Color(0.78, 0.55, 0.34))
	draw_rect(Rect2(Vector2(-30, 0), Vector2(60, 11)),
		Color(0.72, 0.49, 0.29))
	draw_circle(Vector2(-18, -11), 4, Color(0.86, 0.80, 0.65))
	draw_circle(Vector2(2, -11), 4, Color(0.72, 0.38, 0.24))
	draw_circle(Vector2(18, -11), 4, Color(0.52, 0.68, 0.42))


func _draw_plate() -> void:
	for i in range(4):
		draw_circle(Vector2(0, -4 - i * 4), 19 - i * 2,
			Color(0.90, 0.91, 0.88))
		draw_arc(Vector2(0, -4 - i * 4), 19 - i * 2, 0, TAU, 20,
			Color(0.60, 0.62, 0.60), 1.5, true)


func _draw_dishwasher() -> void:
	draw_rect(Rect2(Vector2(-38, -24), Vector2(76, 42)),
		Color(0.66, 0.68, 0.70))
	draw_rect(Rect2(Vector2(-28, -15), Vector2(56, 23)),
		Color(0.38, 0.47, 0.52))
	draw_rect(Rect2(Vector2(-23, -10), Vector2(46, 13)),
		Color(0.54, 0.75, 0.79))
	draw_circle(Vector2(27, -30), 4, Color(0.34, 0.35, 0.36))


func _draw_table() -> void:
	var half := cell_size.x * float(footprint.x) * 0.5 - 9.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-half, -8), Vector2(0, -8 - cell_size.y * 0.42),
		Vector2(half, -8), Vector2(0, -8 + cell_size.y * 0.42)
	]), Color(0.74, 0.45, 0.25))
	draw_line(Vector2(-half + 8, -2), Vector2(-half + 8, 22),
		Color(0.46, 0.27, 0.15), 5)
	draw_line(Vector2(half - 8, -2), Vector2(half - 8, 22),
		Color(0.46, 0.27, 0.15), 5)


func _draw_chair() -> void:
	draw_rect(Rect2(Vector2(-18, -8), Vector2(36, 12)),
		Color(0.78, 0.50, 0.28))
	draw_line(Vector2(-14, 4), Vector2(-14, 21),
		Color(0.44, 0.26, 0.14), 4)
	draw_line(Vector2(14, 4), Vector2(14, 21),
		Color(0.44, 0.26, 0.14), 4)
	draw_line(Vector2(-18, -8), Vector2(-18, -30),
		Color(0.58, 0.34, 0.18), 5)
	draw_line(Vector2(18, -8), Vector2(18, -30),
		Color(0.58, 0.34, 0.18), 5)
	draw_line(Vector2(-18, -30), Vector2(18, -30),
		Color(0.58, 0.34, 0.18), 5)
