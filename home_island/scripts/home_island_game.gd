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
	if persistence_enabled and FileAccess.file_exists(save_path):
		if not load_game(save_path):
			_seed_default_objects()
	else:
		_seed_default_objects()
	ui.add_toast("F5 保存 · F9 读取 · 右键拆除已放置物件。", Painter.BROWN)
	get_tree().auto_accept_quit = false


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
		spawn_placeable(def, Vector2i(int(cell_array[0]), int(cell_array[1])))


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
	if int(data.get("version", 0)) != 1 or str(data.get("map", "")) != "home_island_v1":
		return false

	_clear_placed_objects()
	for id in inventory.order:
		inventory.counts[id] = 0
	var saved_inventory: Dictionary = data.get("inventory", {})
	for key in saved_inventory.keys():
		if inventory.counts.has(str(key)):
			inventory.counts[str(key)] = int(saved_inventory[key])

	var saved_resources: Dictionary = {}
	for item_value in data.get("resources", []):
		var item: Dictionary = item_value
		saved_resources[str(item.get("id", ""))] = int(item.get("uses_left", 0))
	for node in resource_nodes:
		if is_instance_valid(node) and saved_resources.has(node.node_id):
			node.restore_uses(int(saved_resources[node.node_id]))

	for item_value in data.get("objects", []):
		var item: Dictionary = item_value
		var def := find_def(str(item.get("id", "")))
		var origin_array: Array = item.get("origin", [0, 0])
		if def.is_empty() or origin_array.size() < 2:
			continue
		spawn_placeable(def, Vector2i(int(origin_array[0]), int(origin_array[1])))

	var saved_player: Dictionary = data.get("player", {})
	var pos_array: Array = saved_player.get("position", [])
	if pos_array.size() >= 2:
		var saved_pos := Vector2(float(pos_array[0]), float(pos_array[1]))
		player.position = saved_pos if player.can_stand(saved_pos) else grid.cell_to_world(_spawn_cell())
	else:
		player.position = grid.cell_to_world(_spawn_cell())
	player.camera.reset_smoothing()
	_autosave_elapsed = 0.0
	return true


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
