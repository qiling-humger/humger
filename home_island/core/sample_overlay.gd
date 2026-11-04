class_name VisualSampleOverlay
extends Node2D
## 样板场景的海岸线和建造网格。普通状态下网格节点完全隐藏。

var grid: IslandGrid
var mode := "grid"


func setup(grid_ref: IslandGrid, mode_value: String) -> void:
	grid = grid_ref
	mode = mode_value
	queue_redraw()


func _draw() -> void:
	if grid == null:
		return
	if mode == "coast":
		_draw_coast()
	else:
		_draw_grid()


func _draw_coast() -> void:
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for cell in grid.get_land_cells():
		var center := grid.cell_to_world(cell)
		var hw := grid.tile_width * 0.5
		var hh := grid.tile_height * 0.5
		var top := center + Vector2(0, -hh)
		var right := center + Vector2(hw, 0)
		var bottom := center + Vector2(0, hh)
		var left := center + Vector2(-hw, 0)
		for direction in dirs:
			var neighbor: Vector2i = cell + direction
			if grid.is_land(neighbor):
				continue
			var a := top
			var b := right
			if direction == Vector2i(1, 0):
				a = right
				b = bottom
			elif direction == Vector2i(-1, 0):
				a = top
				b = left
			elif direction == Vector2i(0, 1):
				a = bottom
				b = left
			draw_line(a, b, Color(0.99, 0.95, 0.81, 0.92), 4.0, true)
			draw_line(a, b, Color(0.73, 0.84, 0.67, 0.40), 1.2, true)


func _draw_grid() -> void:
	var color := Color(0.22, 0.36, 0.24, 0.23)
	for cell in grid.get_land_cells():
		var points := grid.get_diamond(cell, 1.2)
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, color, 1.0, true)
