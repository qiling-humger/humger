extends Node
## 样板窗口输入验收：真实 E/B、鼠标选卡、放置、拖动。

var game: VisualSampleGame
var checks := 0
var failures := 0


func _ready() -> void:
	print("\n========== 视觉样板真实输入验收开始 ==========")
	var packed := load("res://visual_sample/VisualSample.tscn") as PackedScene
	game = packed.instantiate() as VisualSampleGame
	add_child(game)
	await _frames(30)
	await _run_tests()
	print("\n========== 样板输入验收结束：%d 项检查，%d 项失败 ==========" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _run_tests() -> void:
	print("\n[1] 真实 E 采集")
	game.player.position = game.grid.cell_to_world(Vector2i(1, 5))
	await _frames(4)
	game._refresh_nearest()
	_check(game.nearest_resource != null, "靠近树取得交互目标")
	var action := InputEventAction.new()
	action.action = "interact"
	action.pressed = true
	Input.parse_input_event(action)
	await _frames(4)
	_check(game.inventory.get_count("wood") == 2, "真实 E 动作采到木材",
		str(game.inventory.get_count("wood")))

	print("\n[2] B 与鼠标选卡")
	var b_event := InputEventKey.new()
	b_event.keycode = KEY_B
	b_event.physical_keycode = KEY_B
	b_event.pressed = true
	Input.parse_input_event(b_event)
	await _frames(4)
	_check(game.placement.build_mode, "真实 B 进入建造模式")
	_click_screen(Vector2(1132, 311))
	await _frames(3)
	_check(game.placement.selected_index == 1, "鼠标点击选中桌子",
		str(game.placement.selected_index))

	print("\n[3] 鼠标放置")
	var origin := _find_empty(Vector2i(2, 1))
	var world := game.grid.world_from_float(Vector2(origin.x + 0.5, origin.y))
	var screen := _screen(world)
	var count_before := game.placed_objects.size()
	_click_screen(screen)
	await _frames(4)
	_check(game.placed_objects.size() == count_before + 1, "鼠标放置新增物件",
		str(game.placed_objects.size()))
	var placed: VisualSamplePlaceable = game.placed_objects.back()
	_check(placed.size == Vector2i(2, 1), "放置的是 2×1 桌子",
		str(placed.size))

	print("\n[4] 鼠标拖动搬动")
	Input.parse_input_event(b_event)
	await _frames(3)
	var crate: VisualSamplePlaceable = null
	for object in game.placed_objects:
		if str(object.def.get("id", "")) == "crate":
			crate = object
			break
	_check(crate != null, "找到木箱")
	if crate:
		var old_origin := crate.origin
		var target := _find_empty(Vector2i(1, 1))
		_mouse_button(_screen(game.grid.cell_to_world(old_origin)), true)
		await _frames(3)
		_check(game.placement.is_dragging(), "鼠标按下木箱开始拖动")
		_mouse_button(_screen(game.grid.cell_to_world(target)), false)
		await _frames(4)
		_check(not game.placement.is_dragging(), "松开结束拖动")
		_check(crate.origin == target, "鼠标拖动更新位置", str(crate.origin))


func _find_empty(size: Vector2i) -> Vector2i:
	var center := Vector2(3.5, 3.5)
	var best := Vector2i(-1, -1)
	var best_distance := 99999.0
	for y in range(1, game.grid.rows - size.y):
		for x in range(1, game.grid.columns - size.x):
			if not game.grid.can_place(Vector2i(x, y), size):
				continue
			var distance := Vector2(x, y).distance_squared_to(center)
			if distance < best_distance:
				best_distance = distance
				best = Vector2i(x, y)
	return best


func _screen(world: Vector2) -> Vector2:
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
