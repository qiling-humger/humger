class_name HomeIslandGame
extends VisualSampleGame
## Playable home-island V1 coordinator.
## Reuses the accepted visual-sample grid, terrain, rabbit, gathering and
## placement logic. Adds persistence and right-click demolition only.

@export var save_path := "user://home_island_v1_save.json"
@export var persistence_enabled := true

var _autosave_elapsed := 0.0


func _ready() -> void:
	super._ready()
	player.camera.zoom = Vector2(1.15, 1.15)
	player.camera.position = Vector2(0, -28)
	player.camera.reset_smoothing()
	_build_landmarks()
	if persistence_enabled and FileAccess.file_exists(save_path):
		if not load_game(save_path):
			_seed_default_objects()
	else:
		_seed_default_objects()
	ui.add_toast("F5 保存 · F9 读取 · 右键拆除已放置物件。", Painter.BROWN)
	get_tree().auto_accept_quit = false


func _build_landmarks() -> void:
	var entries: Array = config.get("landmarks", [])
	if entries.is_empty():
		return
	var root := Node2D.new()
	root.name = "MapLandmarks"
	add_child(root)
	for entry_value in entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		var landmark: IslandLandmark = IslandLandmark.new()
		landmark.setup(grid, entry)
		root.add_child(landmark)
		var origin_value: Array = entry.get("origin", [0, 0])
		var size_value: Array = entry.get("size", [1, 1])
		var origin := Vector2i(int(origin_value[0]), int(origin_value[1]))
		var size := Vector2i(int(size_value[0]), int(size_value[1]))
		var cells := grid.footprint_cells(origin, size)
		grid.reserve(cells, "landmark_" + str(entry.get("id", "x")), true)


func _welcome_toast_text() -> String:
	return "家园岛 V1：探索、采集、建造，进度会自动保存。"


func _spawn_initial_objects() -> void:
	# HomeIslandGame loads a save after the parent setup, so initial objects
	# are seeded explicitly in _ready instead of from the parent.
	pass


func _seed_default_objects() -> void:
	for entry_value in config.get("initial_objects", []):
		var entry: Dictionary = entry_value
		var def := find_def(str(entry.get("type", "")))
		if def.is_empty():
			continue
		var cell_array: Array = entry.get("cell", [0, 0])
		spawn_placeable(def, Vector2i(int(cell_array[0]), int(cell_array[1])),
			int(entry.get("rotation", 0)))


func _process(delta: float) -> void:
	super._process(delta)
	if not persistence_enabled:
		return
	_autosave_elapsed += delta
	if _autosave_elapsed >= 2.0:
		_autosave_elapsed = 0.0
		save_game()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var key := key_event.keycode
		if key == 0:
			key = key_event.physical_keycode
		if key == KEY_F5:
			if save_game():
				ui.add_toast("已保存家园岛进度。", Painter.TEAL)
			else:
				ui.add_toast("保存失败，请检查存档目录。", Painter.CORAL_DARK)
			get_viewport().set_input_as_handled()
			return
		if key == KEY_F9:
			if load_game(save_path):
				ui.add_toast("已读取家园岛进度。", Painter.TEAL)
			else:
				ui.add_toast("没有可读取的存档。", Painter.BROWN)
			get_viewport().set_input_as_handled()
			return

	super._unhandled_input(event)

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			var world := _event_world_position(mb.position)
			if placement.demolish_at(world):
				save_game()
				get_viewport().set_input_as_handled()


func remove_placeable(object) -> void:
	if object == null:
		return
	placed_objects.erase(object)
	grid.release(object.object_id)
	object.queue_free()


func save_game(path: String = "") -> bool:
	var target := save_path if path.is_empty() else path
	if grid == null or inventory == null:
		return false
	var data := {
		"version": 1,
		"map": "home_island_v1",
		"player": {"position": [player.position.x, player.position.y]},
		"inventory": inventory.snapshot(),
		"resources": [],
		"objects": [],
	}
	for node in resource_nodes:
		if is_instance_valid(node):
			data["resources"].append({
				"id": node.node_id,
				"type": node.node_type,
				"uses_left": node.uses_left,
			})
	for object in placed_objects:
		if is_instance_valid(object):
			data["objects"].append({
				"id": str(object.def.get("id", "")),
				"origin": [object.origin.x, object.origin.y],
				"rotation": object.rotation_quarters,
			})
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func load_game(path: String = "") -> bool:
	var target := save_path if path.is_empty() else path
	if not FileAccess.file_exists(target):
		return false
	var file := FileAccess.open(target, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	var version_value: Variant = data.get("version", 0)
	var map_value: Variant = data.get("map", "")
	if not _is_number(version_value) or int(version_value) != 1:
		return false
	if typeof(map_value) != TYPE_STRING or str(map_value) != "home_island_v1":
		return false

	# Validate top-level containers before clearing the live island. A malformed
	# save must fail safely or load only known entries, never destroy the scene.
	var inventory_value: Variant = data.get("inventory", {})
	var resources_value: Variant = data.get("resources", [])
	var objects_value: Variant = data.get("objects", [])
	var player_value: Variant = data.get("player", {})
	if typeof(inventory_value) != TYPE_DICTIONARY:
		return false
	if typeof(resources_value) != TYPE_ARRAY:
		return false
	if typeof(objects_value) != TYPE_ARRAY:
		return false
	if typeof(player_value) != TYPE_DICTIONARY:
		return false

	_clear_placed_objects()
	for id in inventory.order:
		inventory.counts[id] = 0
	var saved_inventory: Dictionary = inventory_value
	for key in saved_inventory.keys():
		var count_value: Variant = saved_inventory[key]
		if inventory.counts.has(str(key)) and _is_number(count_value):
			inventory.counts[str(key)] = maxi(0, int(count_value))

	var saved_resources: Dictionary = {}
	for item_value in resources_value:
		if typeof(item_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_value
		var id_value: Variant = item.get("id", "")
		var uses_value: Variant = item.get("uses_left", 0)
		if typeof(id_value) != TYPE_STRING or not _is_number(uses_value):
			continue
		saved_resources[str(id_value)] = clampi(int(uses_value), 0, 9999)
	for node in resource_nodes:
		if is_instance_valid(node) and saved_resources.has(node.node_id):
			node.restore_uses(int(saved_resources[node.node_id]))

	for item_value in objects_value:
		if typeof(item_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_value
		var id_value: Variant = item.get("id", "")
		var origin_value: Variant = item.get("origin", [])
		if typeof(id_value) != TYPE_STRING or typeof(origin_value) != TYPE_ARRAY:
			continue
		var origin_array: Array = origin_value
		if origin_array.size() < 2:
			continue
		if not _is_number(origin_array[0]) or not _is_number(origin_array[1]):
			continue
		var def := find_def(str(id_value))
		if def.is_empty():
			continue
		var rotation_value: Variant = item.get("rotation", 0)
		var rotation := int(rotation_value) if _is_number(rotation_value) else 0
		spawn_placeable(def, Vector2i(int(origin_array[0]), int(origin_array[1])), rotation)

	var saved_player: Dictionary = player_value
	var pos_value: Variant = saved_player.get("position", [])
	var fallback_pos := grid.cell_to_world(_spawn_cell())
	player.position = fallback_pos
	if typeof(pos_value) == TYPE_ARRAY:
		var pos_array: Array = pos_value
		if pos_array.size() >= 2 and _is_number(pos_array[0]) and _is_number(pos_array[1]):
			var x := float(pos_array[0])
			var y := float(pos_array[1])
			if absf(x) < 1000000.0 and absf(y) < 1000000.0:
				var saved_pos := Vector2(x, y)
				if player.can_stand(saved_pos):
					player.position = saved_pos
	player.camera.reset_smoothing()
	_autosave_elapsed = 0.0
	return true


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _clear_placed_objects() -> void:
	for object in placed_objects:
		if is_instance_valid(object):
			grid.release(object.object_id)
			object.queue_free()
	placed_objects.clear()
	_next_object_id = 1


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if persistence_enabled:
			save_game()
		get_tree().quit()
