class_name IslandLandmark
extends Node2D
## Static map-layout landmark (rabbit house / restaurant / dock). It reserves
## its footprint in the grid but is intentionally not a gameplay building yet.

var grid: IslandGrid
var definition: Dictionary
var origin := Vector2i.ZERO
var size := Vector2i.ONE


func setup(grid_ref: IslandGrid, def: Dictionary) -> void:
	grid = grid_ref
	definition = def.duplicate(true)
	var origin_value: Array = def.get("origin", [0, 0])
	var size_value: Array = def.get("size", [1, 1])
	origin = Vector2i(int(origin_value[0]), int(origin_value[1]))
	size = Vector2i(int(size_value[0]), int(size_value[1]))
	var center_cell := Vector2(
		float(origin.x) + (float(size.x) - 1.0) * 0.5,
		float(origin.y) + (float(size.y) - 1.0) * 0.5
	)
	position = grid.world_from_float(center_cell)
	z_index = 5
	queue_redraw()


func _draw() -> void:
	var kind := str(definition.get("kind", "house"))
	var fill := Color(0.72, 0.48, 0.30, 0.42)
	var line := Color(0.35, 0.24, 0.16, 0.9)
	match kind:
		"restaurant":
			fill = Color(0.90, 0.44, 0.25, 0.42)
			line = Color(0.55, 0.22, 0.12, 0.9)
		"dock":
			fill = Color(0.24, 0.56, 0.72, 0.42)
			line = Color(0.12, 0.32, 0.44, 0.9)
	for cell in grid.footprint_cells(origin, size):
		var points := PackedVector2Array()
		for p in grid.get_diamond(cell, 1.0):
			points.append(p - position)
		draw_colored_polygon(points, fill)
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, line, 2.4, true)
	var label := str(definition.get("name", ""))
	if not label.is_empty():
		var r := Rect2(Vector2(-44, -40), Vector2(88, 28))
		Painter.panel(self, r, 9, Color(1.0, 0.973, 0.925, 0.95),
			line, 1.4, true)
		Painter.draw_centered(self, label, r.position + Vector2(44, 19), 15,
			Color(0.30, 0.22, 0.16, 0.95), true)
