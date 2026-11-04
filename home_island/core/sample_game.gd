class_name VisualSampleGame
extends Node2D
## 8×8 视觉样板协调器。复用现有网格、库存、放置、采集逻辑，
## 只把渲染换成独立 Sprite 素材。

@onready var water: IslandWater = $Water
@onready var terrain: VisualSampleTerrain = $Terrain
@onready var entities: Node2D = $Entities
@onready var player: VisualSampleRabbit = $Entities/Player
@onready var placement: VisualSamplePlacement = $Placement
@onready var ui: VisualSampleUI = $UI/HUD

@export var config_path := "res://home_island/data/home_island_config.json"
@export var asset_catalog_path := "res://home_island/data/home_asset_catalog.json"

var config: Dictionary = {}
var asset_catalog: Dictionary = {}
var grid: IslandGrid
var inventory: MapInventory
var island_map: VisualSampleTerrain
var resource_nodes: Array[VisualSampleResource] = []
var placed_objects: Array[VisualSamplePlaceable] = []
var nearest_resource: VisualSampleResource = null
var interaction_radius := 84.0

var _next_object_id := 1
var _texture_cache: Dictionary = {}


func _ready() -> void:
	config = _load_json(config_path)
	asset_catalog = _load_json(asset_catalog_path)
	if config.is_empty() or asset_catalog.is_empty():
		push_error("VisualSampleGame: 配置或资产目录读取失败。")
		return
	grid = IslandGrid.new()
	grid.setup(config)
	terrain.setup(self, grid, asset_catalog)
	island_map = terrain
	inventory = MapInventory.new()
	inventory.setup(config.get("resource_order", []), config.get("resource_types", {}))
	player.setup_assets(asset_catalog)
	player.setup(grid, _spawn_cell())
	player.camera.zoom = Vector2(1.55, 1.55)
	player.camera.position = Vector2(0, -38)
	player.camera.reset_smoothing()
	interaction_radius = float(config.get("player", {}).get("interaction_radius", 84.0))
	placement.setup(self, grid, entities, config.get("placeables", []))
	_spawn_resources()
	_spawn_initial_objects()
	ui.setup(self)
	ui.add_toast(_welcome_toast_text(), Painter.TEAL)
	set_process(true)


func _welcome_toast_text() -> String:
	return "视觉样板：独立 Sprite、隐藏网格、8×8 小岛。"


func _spawn_cell() -> Vector2i:
	var spawn: Array = config.get("player", {}).get("spawn", [3, 4])
	return Vector2i(int(spawn[0]), int(spawn[1]))


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed as Dictionary
	return {}


func _spawn_resources() -> void:
	var node_types: Dictionary = config.get("node_types", {})
	for entry_value in config.get("resource_nodes", []):
		var entry: Dictionary = entry_value
		var type_id := str(entry.get("type", "tree"))
		var type_def: Dictionary = node_types.get(type_id, {})
		if type_def.is_empty():
			continue
		var cell_array: Array = entry.get("cell", [0, 0])
		var cell := Vector2i(int(cell_array[0]), int(cell_array[1]))
		if not grid.is_land(cell):
			push_warning("样板资源点不在陆地上: " + str(entry.get("id", "")))
			continue
		var node := VisualSampleResource.new()
		node.setup(str(entry.get("id", "res_%d" % resource_nodes.size())), type_id,
			cell, type_def, grid, self)
		entities.add_child(node)
		resource_nodes.append(node)


func _spawn_initial_objects() -> void:
	for entry_value in config.get("initial_objects", []):
		var entry: Dictionary = entry_value
		var def := find_def(str(entry.get("type", "")))
		if def.is_empty():
			continue
		var cell_array: Array = entry.get("cell", [0, 0])
		var cell := Vector2i(int(cell_array[0]), int(cell_array[1]))
		spawn_placeable(def, cell)


func find_def(type_id: String) -> Dictionary:
	for def_value in config.get("placeables", []):
		if str(def_value.get("id", "")) == type_id:
			return def_value
	return {}


func get_asset_texture(key: String) -> Texture2D:
	var props: Dictionary = asset_catalog.get("props", {})
	var data: Dictionary = props.get(key, {})
	if data.is_empty():
		return null
	var path := str(data.get("texture", ""))
	if path.is_empty():
		return null
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path] as Texture2D


func get_asset_base_pad(key: String) -> float:
	var props: Dictionary = asset_catalog.get("props", {})
	var data: Dictionary = props.get(key, {})
	return float(data.get("base_pad", 0.0))


func get_asset_scale(key: String) -> float:
	var props: Dictionary = asset_catalog.get("props", {})
	var data: Dictionary = props.get(key, {})
	return float(data.get("display_scale", 1.0))


func has_asset(key: String) -> bool:
	return get_asset_texture(key) != null


func spawn_placeable(def: Dictionary, origin: Vector2i) -> VisualSamplePlaceable:
	if def.is_empty():
		return null
	var size := Vector2i(int(def.get("width", 1)), int(def.get("height", 1)))
	if not grid.can_place(origin, size):
		return null
	var object_id := "sample_object_%d" % _next_object_id
	_next_object_id += 1
	var object := VisualSamplePlaceable.new()
	object.setup(object_id, def, origin, grid, self)
	entities.add_child(object)
	grid.reserve(object.get_cells(), object_id, bool(def.get("blocking", true)))
	placed_objects.append(object)
	return object


func get_movable_at_cell(cell: Vector2i) -> VisualSamplePlaceable:
	for object in placed_objects:
		if is_instance_valid(object) and object.contains_cell(cell):
			return object
	return null


func toggle_build_mode() -> void:
	if placement.is_dragging():
		return
	if placement.build_mode:
		exit_build_mode()
	else:
		placement.enter_build_mode()
		_clear_nearest_highlight()
		nearest_resource = null
		ui.add_toast("建造模式：1-3 选物件，左键放置，Esc 退出。", Painter.BROWN)


func exit_build_mode() -> void:
	placement.exit_build_mode()
	ui.add_toast("已退出建造模式，网格重新隐藏。", Painter.BROWN)


func select_buildable(index: int) -> void:
	if not placement.build_mode:
		return
	placement.select_buildable(index)
	placement.update_preview(get_global_mouse_position())


func gather_nearest() -> bool:
	if placement.build_mode or placement.is_dragging():
		return false
	if nearest_resource == null or not is_instance_valid(nearest_resource):
		return false
	if nearest_resource.is_depleted():
		return false
	var info := nearest_resource.gather()
	if info.is_empty():
		return false
	inventory.add(str(info.get("resource", "")), int(info.get("amount", 0)))
	var type_data: Dictionary = config.get("resource_types", {}).get(
		str(info.get("resource", "")), {})
	ui.add_toast("+%d %s" % [int(info.get("amount", 0)), str(type_data.get("name", "资源"))],
		Color.from_string(str(type_data.get("color", "#6D9A57")), Painter.TEAL))
	nearest_resource.set_highlighted(false)
	nearest_resource = null
	_refresh_nearest()
	return true


func notify(text: String, color: Color = Painter.INK) -> void:
	if ui:
		ui.add_toast(text, color)


func _process(_delta: float) -> void:
	if placement.build_mode or placement.is_dragging():
		placement.update_preview(get_global_mouse_position())
		if nearest_resource != null:
			_clear_nearest_highlight()
			nearest_resource = null
	else:
		_refresh_nearest()


func _refresh_nearest() -> void:
	var origin := player.interaction_origin()
	var best: VisualSampleResource = null
	var best_distance := 999999.0
	for node in resource_nodes:
		if not is_instance_valid(node) or node.is_depleted():
			continue
		var distance := origin.distance_to(node.position)
		if distance <= interaction_radius and distance < best_distance:
			best_distance = distance
			best = node
	if best == nearest_resource:
		return
	_clear_nearest_highlight()
	nearest_resource = best
	if nearest_resource != null:
		nearest_resource.set_highlighted(true)


func _clear_nearest_highlight() -> void:
	if nearest_resource != null and is_instance_valid(nearest_resource):
		nearest_resource.set_highlighted(false)


func _event_world_position(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var key := key_event.keycode
		if key == 0:
			key = key_event.physical_keycode
		if key == KEY_B:
			toggle_build_mode()
			get_viewport().set_input_as_handled()
			return
		if key == KEY_ESCAPE:
			if placement.cancel():
				get_viewport().set_input_as_handled()
			return
		if placement.build_mode:
			for i in range(3):
				if key == KEY_1 + i:
					select_buildable(i)
					get_viewport().set_input_as_handled()
					return
	if event.is_action_pressed("interact"):
		if gather_nearest():
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var world := _event_world_position(mb.position)
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if placement.build_mode:
				if placement.try_place_at(world):
					get_viewport().set_input_as_handled()
			else:
				if placement.begin_drag(world):
					get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if placement.is_dragging():
				placement.finish_drag(world)
				get_viewport().set_input_as_handled()
