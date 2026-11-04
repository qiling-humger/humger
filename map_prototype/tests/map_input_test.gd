extends Node
## 窗口模式真实输入验收：E/B/鼠标选择/鼠标放置/鼠标拖动。

var game: MapGame
var checks := 0
var failures := 0


func _ready() -> void:
	print("\n========== 家园岛真实输入验收开始 ==========")
	var packed := load("res://map_prototype/MapPrototype.tscn") as PackedScene
	game = packed.instantiate() as MapGame
	add_child(game)
	await _frames(30)
	await _run_tests()
	print("\n========== 输入验收结束：%d 项检查，%d 项失败 ==========" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _run_tests() -> void:
	print("\n[1] E 动作采集")
	game.player.position = game.grid.cell_to_world(Vector2i(6, 5))
	await _frames(4)
	game._refresh_nearest()
	_check(game.nearest_resource != null, "靠近树木获得交互目标")
	var action := InputEventAction.new()
	action.action = "interact"
	action.pressed = true
	Input.parse_input_event(action)
	await _frames(4)
	_check(game.inventory.get_count("wood") == 2, "真实 E 动作采集到木材",
		str(game.inventory.get_count("wood")))

	print("\n[2] B 键与建造面板点击")
	var b_event := InputEventKey.new()
	b_event.keycode = KEY_B
	b_event.physical_keycode = KEY_B
	b_event.pressed = true
	Input.parse_input_event(b_event)
	await _frames(4)
	_check(game.placement.build_mode, "真实 B 键进入建造模式")
	# 第二张卡（2×1 小桌子）
	_click_screen(Vector2(1132, 311))
	await _frames(3)
	_check(game.placement.selected_index == 1, "鼠标点击建造卡片选中 2×1",
		str(game.placement.selected_index))

	print("\n[3] 鼠标点击放置")
	var size := Vector2i(2, 1)
	var origin := _find_empty_near_center(size)
	var world := game.grid.world_from_float(Vector2(
		origin.x + (size.x - 1) * 0.5, origin.y + (size.y - 1) * 0.5))
	var screen := _world_to_screen(world)
	_click_screen(screen)
	await _frames(4)
	var found: IslandPlaceable = null
	for object in game.placed_objects:
		if object.size == size and object.origin == origin:
			found = object
	_check(found != null, "鼠标放置 2×1 物件", str(origin))
	if found:
		_check(found.get_cells().size() == 2, "2×1 实际占两格")

	print("\n[4] 鼠标拖动搬动")
	# 退出建造
	Input.parse_input_event(b_event)
	await _frames(3)
	_check(not game.placement.build_mode, "再次 B 退出建造")
	var crate: IslandPlaceable = null
	for object in game.placed_objects:
		if str(object.def.get("id", "")) == "crate":
			crate = object
			break
	_check(crate != null, "找到初始木箱")
	if crate:
		var old_origin := crate.origin
		var target := _find_empty_near_center(Vector2i(1, 1))
		var press_pos := _world_to_screen(game.grid.cell_to_world(old_origin))
		var move_pos := _world_to_screen(game.grid.cell_to_world(target))
		_mouse_button(press_pos, true)
		await _frames(3)
		_check(game.placement.is_dragging(), "鼠标按下木箱开始拖动")
		_mouse_button(move_pos, false)
		await _frames(4)
		_check(not game.placement.is_dragging(), "鼠标松开结束拖动")
		_check(crate.origin == target, "鼠标拖动更新物件位置", str(crate.origin))


func _find_empty_near_center(size: Vector2i) -> Vector2i:
	var center := Vector2i(12, 8)
	var best := Vector2i(-1, -1)
	var best_dist := 999999.0
	for y in range(1, game.grid.rows - size.y):
		for x in range(1, game.grid.columns - size.x):
			var origin := Vector2i(x, y)
			if not game.grid.can_place(origin, size):
				continue
			var dist := Vector2(origin).distance_squared_to(Vector2(center))
			if dist < best_dist:
				best_dist = dist
				best = origin
	return best


func _world_to_screen(world: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world


func _click_screen(pos: Vector2) -> void:
	_mouse_button(pos, true)
	_mouse_button(pos, false)


func _mouse_button(pos: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = pos
	event.global_position = pos
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


func _check(condition: bool, title: String, detail := "") -> void:
	checks += 1
	if condition:
		print("  [PASS] ", title, ("  " + detail) if detail != "" else "")
	else:
		failures += 1
		print("  [FAIL] ", title, ("  " + detail) if detail != "" else "")
