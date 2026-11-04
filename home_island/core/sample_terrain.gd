class_name VisualSampleTerrain
extends Node2D
## 8×8 样板地形：透明地块 PNG 拼接，普通状态不显示网格。

var grid: IslandGrid
var game: Node
var catalog: Dictionary

@export var tile_overlap := 1.12
@export var grass_base_color := Color(0.61, 0.79, 0.47)
@export var sand_base_color := Color(0.93, 0.81, 0.59)

var _base_root: Node2D
var _tile_root: Node2D
var _coast_overlay: VisualSampleOverlay
var _grid_overlay: VisualSampleOverlay
var land_tile_count := 0


func setup(game_ref: Node, grid_ref: IslandGrid, asset_catalog: Dictionary) -> void:
	game = game_ref
	grid = grid_ref
	catalog = asset_catalog
	z_index = -10
	# 先铺一层不透明底色，遮住透明地块边缘的 1px 接缝。
	_base_root = Node2D.new()
	_base_root.name = "TerrainBase"
	_base_root.z_index = -2
	add_child(_base_root)
	_tile_root = Node2D.new()
	_tile_root.name = "Tiles"
	_tile_root.z_index = -1
	add_child(_tile_root)
	_build_base()
	_build_tiles()

	_coast_overlay = VisualSampleOverlay.new()
	_coast_overlay.name = "Coast"
	_coast_overlay.z_index = 2
	add_child(_coast_overlay)
	_coast_overlay.setup(grid, "coast")

	_grid_overlay = VisualSampleOverlay.new()
	_grid_overlay.name = "BuildGrid"
	_grid_overlay.z_index = 3
	_grid_overlay.visible = false
	add_child(_grid_overlay)
	_grid_overlay.setup(grid, "grid")


func _build_base() -> void:
	for cell in grid.get_land_cells():
		var polygon := Polygon2D.new()
		polygon.polygon = grid.get_diamond(cell, -2.0)
		polygon.color = grass_base_color if grid.terrain_at(cell) != IslandGrid.SAND \
			else sand_base_color
		_base_root.add_child(polygon)


func _build_tiles() -> void:
	var terrain_paths: Dictionary = catalog.get("terrain", {})
	var grass_tex := load(str(terrain_paths.get("grass", ""))) as Texture2D
	var sand_tex := load(str(terrain_paths.get("sand", ""))) as Texture2D
	land_tile_count = 0
	for cell in grid.get_land_cells():
		var terrain := grid.terrain_at(cell)
		var texture: Texture2D = grass_tex
		if terrain == IslandGrid.SAND and sand_tex != null:
			texture = sand_tex
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.position = grid.cell_to_world(cell)
		# 轻微重叠，避免透明菱形边缘拼出 1px 网格感。
		sprite.scale = Vector2(
			grid.tile_width / float(texture.get_width()) * tile_overlap,
			grid.tile_height / float(texture.get_height()) * tile_overlap
		)
		_tile_root.add_child(sprite)
		land_tile_count += 1


func set_build_mode(value: bool) -> void:
	if _grid_overlay:
		_grid_overlay.visible = value


func is_grid_visible() -> bool:
	return _grid_overlay != null and _grid_overlay.visible
