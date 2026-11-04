class_name MapGame
extends Node2D
## 家园岛地图原型总协调器。
## 键盘：WASD 移动、E 采集、B 建造、Esc 取消/退出、1-4 选择物件。
## 鼠标：拖动已放置家具搬家；建造模式下左键放置。

@onready var water: IslandWater = $Water
@onready var island_map: IslandMap = $IslandMap
@onready var entities: Node2D = $Entities
@onready var player: RabbitPlayer = $Entities/Player
@onready var placement: MapPlacementController = $Placement
@onready var ui: MapUI = $UI/HUD

var config: Dictionary = {}
var grid: IslandGrid
var inventory: MapInventory
var resource_nodes: Array[IslandResourceNode] = []
var placed_objects: Array[IslandPlaceable] = []
var objects_by_id: Dictionary = {}
var nearest_resource: IslandResourceNode = null
var interaction_radius := 82.0

var _next_object_id := 1


func _ready() -> void:
	config = MapConfig.load_data()
	if config.is_empty():
		push_error("MapGame: 配置为空，无法启动地图原型。")
		return
	grid = IslandGrid.new()
	grid.setup(config)
	island_map.setup(grid)
	inventory = MapInventory.new()
	var order: Array = config.get("resource_order", [])
	inventory.setup(order, config.get("resource_types", {}))
	player.setup(grid, _spawn_cell())
	interaction_radius = float(config.get("player", {}).get("interaction_radius", 82.0))
	placement.setup(self, grid, entities, config.get("placeables", []))
	_spawn_resources()
	_spawn_initial_objects()
	ui.setup(self)
	ui.add_toast("欢迎来到家园岛！靠近资源按 E 采集。", Painter.TEAL)
	set_process(true)
	queue_redraw()


func _spawn_cell() -> Vector2i:
	var spawn: Array = config.get("player", {}).get("spawn", [11, 10])
	return Vector2i(int(spawn[0]), int(spawn[1]))


func _spawn_resources() -> void:
	var node_types: Dictionary = config.get("node_types", {})
	for entry_value in config.get("resource_nodes", []):
		var entry: Dictionary = entry_value
		var type_id := str(entry.get("type", "tree"))
		var type_def: Dictionary = node_types.get(type_id, {})
		if type_def.is_empty():
			push_warning("MapGame: 未知资源类型 " + type_id)
			continue
		var cell_array: Array = entry.get("cell", [0, 0])
		var cell := Vector2i(int(cell_array[0]), int(cell_array[1]))
		if not grid.is_land(cell):
			push_warning("MapGame: 资源点不在陆地上 " + str(entry.get("id", "")))
			continue
		var node := IslandResourceNode.new()
		node.setup(str(entry.get("id", "res_%d" % resource_nodes.size())), type_id, cell,
			type_def, grid, self)
		entities.add_child(node)
		resource_nodes.append(node)


func _spawn_initial_objects() -> void:
	for entry_value in config.get("initial_objects", []):
		var entry: Dictionary = entry_value
		var def := find_def(str(entry.get("type", "")))
		if def.is_empty():
			push_warning("MapGame: 未知初始物件 " + str(entry.get("type", "")))
			continue
		var cell_array: Array = entry.get("cell", [0, 0])
		var cell := Vector2i(int(cell_array[0]), int(cell_array[1]))
		var placed := spawn_placeable(def, cell)
		if placed == null:
			push_warning("MapGame: 初始物件位置冲突 %s @ %s" % [str(entry.get("type", "")), str(cell)])


func find_def(type_id: String) -> Dictionary:
	for def in config.get("placeables", []):
		if str(def.get("id", "")) == type_id:
			return def
	return {}


func spawn_placeable(def: Dictionary, origin: Vector2i) -> IslandPlaceable:
	if def.is_empty():
		return null
	var size := Vector2i(int(def.get("width", 1)), int(def.get("height", 1)))
	if not grid.can_place(origin, size):
		return null
	var object_id := "object_%d" % _next_object_id
	_next_object_id += 1
	var object := IslandPlaceable.new()
	object.setup(object_id, def, origin, grid, self)
	entities.add_child(object)
	grid.reserve(object.get_cells(), object_id, bool(def.get("blocking", true)))
	placed_objects.append(object)
	objects_by_id[object_id] = object
	return object


func get_movable_at_cell(cell: Vector2i) -> IslandPlaceable:
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
		ui.add_toast("建造模式：1-4 选物件，左键放置，Esc 退出。", Painter.BROWN)


func exit_build_mode() -> void:
	placement.exit_build_mode()
	ui.add_toast("已退出建造模式。", Painter.BROWN)


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
	var resource_name := str(config.get("resource_types", {}).get(
		str(info.get("resource", "")), {}).get("name", "资源"))
	ui.add_toast("+%d %s" % [int(info.get("amount", 0)), resource_name],
		Color.from_string(str(config.get("resource_types", {}).get(
			str(info.get("resource", "")), {}).get("color", "#6D9A57")), Painter.TEAL))
	nearest_resource.set_highlighted(false)
	nearest_resource = null
	_refresh_nearest()
	return true


func get_nearest_prompt() -> Dictionary:
	if nearest_resource == null or not is_instance_valid(nearest_resource):
		return {}
	return nearest_resource.prompt_data()


func notify(text: String, color: Color = Painter.INK) -> void:
	if ui:
		ui.add_toast(text, color)


func _process(_delta: float) -> void:
	if placement == null:
		return
	if placement.build_mode or placement.is_dragging():
		placement.update_preview(get_global_mouse_position())
		if nearest_resource != null:
			_clear_nearest_highlight()
			nearest_resource = null
	else:
		_refresh_nearest()


func _refresh_nearest() -> void:
	var origin := player.interaction_origin()
	var best: IslandResourceNode = null
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
			for i in range(4):
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


func _event_world_position(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position
