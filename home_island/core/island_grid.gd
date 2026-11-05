class_name IslandGrid
extends RefCounted
## 纯逻辑的菱形等距网格：地形、边界、坐标转换、占地与阻挡。
## 屏幕像素只用于渲染；放置、碰撞、采集全部通过逻辑格判断。

const WATER := 0
const GRASS := 1
const SAND := 2
const DIRT := 3
const ROAD := 4
const FLOWER := 5

var columns := 24
var rows := 18
var tile_width := 64.0
var tile_height := 32.0
var island_center := Vector2(11.5, 8.5)
var island_radius := Vector2(11.0, 8.0)
var sand_threshold := 0.78
var clearing_center := Vector2(11.5, 10.0)
var clearing_radius := Vector2(3.4, 2.5)

var land_cells: Dictionary = {}
var world_offset := Vector2.ZERO
var _explicit_terrain_rows: Array = []

var _occupancy: Dictionary = {}
var _object_cells: Dictionary = {}
var _blocking_ids: Dictionary = {}


func setup(config: Dictionary) -> void:
	var map_data: Dictionary = config.get("map", {})
	columns = int(map_data.get("columns", 24))
	rows = int(map_data.get("rows", 18))
	tile_width = float(map_data.get("tile_width", 64))
	tile_height = float(map_data.get("tile_height", 32))
	_explicit_terrain_rows = map_data.get("terrain_rows", [])

	var island_data: Dictionary = config.get("island", {})
	var center_value: Array = island_data.get("center", [11.5, 8.5])
	island_center = Vector2(float(center_value[0]), float(center_value[1]))
	var radius_value: Array = island_data.get("radius", [11.0, 8.0])
	island_radius = Vector2(float(radius_value[0]), float(radius_value[1]))
	sand_threshold = float(island_data.get("sand_threshold", 0.78))
	var clear_center: Array = island_data.get("clearing_center", [11.5, 10.0])
	clearing_center = Vector2(float(clear_center[0]), float(clear_center[1]))
	var clear_radius: Array = island_data.get("clearing_radius", [3.4, 2.5])
	clearing_radius = Vector2(float(clear_radius[0]), float(clear_radius[1]))

	var c := Vector2((columns - 1) * 0.5, (rows - 1) * 0.5)
	world_offset = Vector2(
		(c.x - c.y) * tile_width * 0.5,
		(c.x + c.y) * tile_height * 0.5
	)
	generate_island()


func generate_island() -> void:
	land_cells.clear()
	if not _explicit_terrain_rows.is_empty():
		for y in range(mini(rows, _explicit_terrain_rows.size())):
			var row := str(_explicit_terrain_rows[y])
			for x in range(mini(columns, row.length())):
				var terrain := _terrain_for_char(row.substr(x, 1))
				if terrain >= 0:
					land_cells[Vector2i(x, y)] = terrain
		return
	for y in range(rows):
		for x in range(columns):
			var cell := Vector2i(x, y)
			var nx := (float(x) - island_center.x) / island_radius.x
			var ny := (float(y) - island_center.y) / island_radius.y
			var distance := nx * nx + ny * ny
			if distance > 1.0:
				continue
			var terrain := GRASS
			if distance > sand_threshold:
				terrain = SAND
			var cx := (float(x) - clearing_center.x) / clearing_radius.x
			var cy := (float(y) - clearing_center.y) / clearing_radius.y
			if cx * cx + cy * cy <= 1.0 and terrain != SAND:
				terrain = DIRT
			land_cells[cell] = terrain


func _terrain_for_char(ch: String) -> int:
	match ch:
		"海", "H":
			return -1
		"沙", "S":
			return SAND
		"路", "P":
			return ROAD
		"花", "F":
			return FLOWER
		"草", "G", "树", "T", "石", "K", "兔", "B", "店", "R", "码", "D":
			return GRASS
		_:
			return -1


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < columns and cell.y < rows


func is_land(cell: Vector2i) -> bool:
	return land_cells.has(cell)


func is_water(cell: Vector2i) -> bool:
	return not in_bounds(cell) or not land_cells.has(cell)


func terrain_at(cell: Vector2i) -> int:
	return int(land_cells.get(cell, WATER))


func terrain_name(cell: Vector2i) -> String:
	match terrain_at(cell):
		GRASS:
			return "grass"
		SAND:
			return "sand"
		DIRT:
			return "dirt"
		ROAD:
			return "road"
		FLOWER:
			return "flower"
		_:
			return "water"


func get_land_cells() -> Array:
	return land_cells.keys()


func get_land_count() -> int:
	return land_cells.size()


func cell_to_world(cell: Vector2i) -> Vector2:
	return world_from_float(Vector2(cell.x, cell.y))


func world_from_float(cell: Vector2) -> Vector2:
	var iso := Vector2(
		(cell.x - cell.y) * tile_width * 0.5,
		(cell.x + cell.y) * tile_height * 0.5
	)
	return iso - world_offset


func world_to_cell_float(point: Vector2) -> Vector2:
	var local := point + world_offset
	var a := local.x / (tile_width * 0.5)
	var b := local.y / (tile_height * 0.5)
	return Vector2((a + b) * 0.5, (b - a) * 0.5)


func world_to_cell(point: Vector2) -> Vector2i:
	var precise := world_to_cell_float(point)
	return Vector2i(roundi(precise.x), roundi(precise.y))


func is_walkable_cell(cell: Vector2i) -> bool:
	if not is_land(cell):
		return false
	if not _occupancy.has(cell):
		return true
	var owner_id := str(_occupancy[cell])
	return not bool(_blocking_ids.get(owner_id, true))


func is_walkable_at(point: Vector2) -> bool:
	return is_walkable_cell(world_to_cell(point))


func is_blocking_at(point: Vector2) -> bool:
	var cell := world_to_cell(point)
	if not is_land(cell):
		return true
	if not _occupancy.has(cell):
		return false
	var owner_id := str(_occupancy[cell])
	return bool(_blocking_ids.get(owner_id, true))


func ownership_at(cell: Vector2i) -> String:
	return str(_occupancy.get(cell, ""))


func footprint_cells(origin: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(size.y):
		for x in range(size.x):
			cells.append(Vector2i(origin.x + x, origin.y + y))
	return cells


func can_place(origin: Vector2i, size: Vector2i, ignore_id := "") -> bool:
	if size.x <= 0 or size.y <= 0:
		return false
	for cell in footprint_cells(origin, size):
		if not is_land(cell):
			return false
		if _occupancy.has(cell) and str(_occupancy[cell]) != ignore_id:
			return false
	return true


func reserve(cells: Array[Vector2i], owner_id: String, blocking: bool) -> void:
	for cell in cells:
		_occupancy[cell] = owner_id
	_object_cells[owner_id] = cells.duplicate()
	_blocking_ids[owner_id] = blocking


func release(owner_id: String) -> void:
	if not _object_cells.has(owner_id):
		return
	var cells: Array = _object_cells[owner_id]
	for cell in cells:
		if str(_occupancy.get(cell, "")) == owner_id:
			_occupancy.erase(cell)
	_object_cells.erase(owner_id)
	_blocking_ids.erase(owner_id)


func owned_cells(owner_id: String) -> Array:
	return _object_cells.get(owner_id, []).duplicate()


func front_cell(origin: Vector2i, size: Vector2i) -> Vector2i:
	return Vector2i(origin.x + size.x - 1, origin.y + size.y - 1)


func get_world_bounds() -> Rect2:
	var min_point := Vector2(INF, INF)
	var max_point := Vector2(-INF, -INF)
	for cell in land_cells.keys():
		var c := cell_to_world(cell)
		var corners := [
			c + Vector2(-tile_width * 0.5, 0),
			c + Vector2(0, -tile_height * 0.5),
			c + Vector2(tile_width * 0.5, 0),
			c + Vector2(0, tile_height * 0.5),
		]
		for p in corners:
			min_point.x = minf(min_point.x, p.x)
			min_point.y = minf(min_point.y, p.y)
			max_point.x = maxf(max_point.x, p.x)
			max_point.y = maxf(max_point.y, p.y)
	return Rect2(min_point, max_point - min_point)


func get_diamond(cell: Vector2i, inset := 0.0) -> PackedVector2Array:
	var c := cell_to_world(cell)
	var hw := tile_width * 0.5 - inset
	var hh := tile_height * 0.5 - inset * 0.5
	return PackedVector2Array([
		c + Vector2(0, -hh),
		c + Vector2(hw, 0),
		c + Vector2(0, hh),
		c + Vector2(-hw, 0),
	])
