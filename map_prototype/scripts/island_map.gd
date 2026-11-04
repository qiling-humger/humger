class_name IslandMap
extends Node2D
## 家园岛地形渲染：菱形地块、海岸线、弱网格和固定装饰。
## 只画表现；是否可走、能否放置由 IslandGrid 决定。

const GRASS_A := Color(0.655, 0.808, 0.490)
const GRASS_B := Color(0.596, 0.765, 0.435)
const SAND := Color(0.949, 0.855, 0.647)
const SAND_LIGHT := Color(0.984, 0.914, 0.745)
const DIRT := Color(0.845, 0.714, 0.522)
const DIRT_LIGHT := Color(0.886, 0.769, 0.596)
const GRID_NORMAL := Color(0.204, 0.337, 0.243, 0.075)
const GRID_BUILD := Color(0.196, 0.333, 0.243, 0.26)
const COAST := Color(0.980, 0.925, 0.749)
const COAST_DARK := Color(0.510, 0.706, 0.506)
const FLOWER_COLORS := [Color(0.973, 0.854, 0.506), Color(0.949, 0.678, 0.627),
	Color(0.965, 0.957, 0.907)]

var grid: IslandGrid
var build_mode := false


func setup(grid_ref: IslandGrid) -> void:
	grid = grid_ref
	z_index = -5
	queue_redraw()


func set_build_mode(value: bool) -> void:
	if build_mode == value:
		return
	build_mode = value
	queue_redraw()


func _draw() -> void:
	if grid == null:
		return
	_draw_land()
	_draw_coastline()
	_draw_grid()
	_draw_details()


func _draw_land() -> void:
	for cell in grid.get_land_cells():
		var center := grid.cell_to_world(cell)
		var terrain := grid.terrain_at(cell)
		var color := GRASS_A
		var h := _noise(cell, 1)
		match terrain:
			IslandGrid.GRASS:
				color = GRASS_A.lerp(GRASS_B, h * 0.8)
			IslandGrid.SAND:
				color = SAND.lerp(SAND_LIGHT, h)
			IslandGrid.DIRT:
				color = DIRT.lerp(DIRT_LIGHT, h)
		var points := grid.get_diamond(cell, 0.6)
		draw_colored_polygon(points, color)
		# 极轻的接触边，防止大面积纯色发闷。
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, Color(0.27, 0.42, 0.26, 0.08), 1.0, true)


func _draw_coastline() -> void:
	var dirs := [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
	]
	for cell in grid.get_land_cells():
		var center := grid.cell_to_world(cell)
		var hw := grid.tile_width * 0.5
		var hh := grid.tile_height * 0.5
		var top := center + Vector2(0, -hh)
		var right := center + Vector2(hw, 0)
		var bottom := center + Vector2(0, hh)
		var left := center + Vector2(-hw, 0)
		for d in dirs:
			var neighbor: Vector2i = cell + d
			if grid.is_land(neighbor):
				continue
			var a := top
			var b := right
			if d == Vector2i(1, 0):
				a = right
				b = bottom
			elif d == Vector2i(-1, 0):
				a = top
				b = left
			elif d == Vector2i(0, 1):
				a = bottom
				b = left
			# 外侧浅色沙滩边 + 内侧重一点的海岸线。
			draw_line(a, b, COAST, 5.0, true)
			draw_line(a, b, Color(COAST_DARK, 0.42), 1.5, true)
			draw_line(a + (b - a).normalized() * 3.0,
				b - (b - a).normalized() * 3.0, Color(1, 1, 1, 0.42), 1.2, true)


func _draw_grid() -> void:
	var alpha := GRID_BUILD if build_mode else GRID_NORMAL
	var width := 1.25 if build_mode else 0.8
	for y in range(grid.rows):
		for x in range(grid.columns):
			var cell := Vector2i(x, y)
			if not grid.is_land(cell):
				continue
			var points := grid.get_diamond(cell, 1.4)
			var closed := points.duplicate()
			closed.append(points[0])
			draw_polyline(closed, alpha, width, true)


func _draw_details() -> void:
	for cell in grid.get_land_cells():
		var terrain := grid.terrain_at(cell)
		var center := grid.cell_to_world(cell)
		var h := _noise(cell, 7)
		if terrain == IslandGrid.GRASS:
			if h > 0.40:
				_draw_grass_tuft(center + Vector2((h - 0.5) * 26, (h - 0.4) * 9), h)
			if h > 0.88:
				_draw_flower(center + Vector2(-12 + h * 18, -2 + h * 5), h)
		elif terrain == IslandGrid.SAND:
			if h > 0.35:
				draw_circle(center + Vector2((h - 0.5) * 28, 3), 1.3,
					Color(0.74, 0.61, 0.40, 0.34))
		elif terrain == IslandGrid.DIRT:
			if h > 0.55:
				draw_circle(center + Vector2((h - 0.5) * 22, 4), 1.6,
					Color(0.63, 0.47, 0.30, 0.24))


func _draw_grass_tuft(center: Vector2, h: float) -> void:
	var color := Color(0.33, 0.55, 0.28, 0.34)
	draw_line(center + Vector2(-4, 2), center + Vector2(-6, -5), color, 1.5, true)
	draw_line(center + Vector2(0, 2), center + Vector2(1, -7), color, 1.6, true)
	draw_line(center + Vector2(4, 2), center + Vector2(7, -4), color, 1.4, true)
	if h > 0.72:
		draw_circle(center + Vector2(2, -7), 1.5, Color(0.96, 0.92, 0.72, 0.8))


func _draw_flower(center: Vector2, h: float) -> void:
	var color: Color = FLOWER_COLORS[int(h * 7.0) % FLOWER_COLORS.size()]
	draw_line(center + Vector2(0, 2), center + Vector2(0, -6), Color(0.33, 0.55, 0.28, 0.45), 1.4)
	draw_circle(center + Vector2(-3, -6), 2.1, color)
	draw_circle(center + Vector2(3, -6), 2.1, color)
	draw_circle(center + Vector2(0, -9), 2.1, color)
	draw_circle(center + Vector2(0, -6), 1.4, Painter.BROWN)


func _noise(cell: Vector2i, salt: int) -> float:
	var n := cell.x * 374761393 + cell.y * 668265263 + salt * 69069
	n = (n ^ (n >> 13)) * 1274126177
	return float(absi(n % 1000)) / 1000.0
