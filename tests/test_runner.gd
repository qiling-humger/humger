extends Node
## 无头自动化验收：真正实例化 Main.tscn，并调用玩家/设备/系统完成完整订单。
## 运行：
##   godot --headless --path . tests/TestRunner.tscn

var manager: GameManager
var failures := 0
var checks := 0
var gui_input_available := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	gui_input_available = DisplayServer.get_name() != "headless"
	print("========== 《汉堡物语》自动验收开始（GUI 鼠标: %s） ==========" % ("开" if gui_input_available else "无头跳过"))
	var packed: PackedScene = load("res://scenes/Main.tscn")
	manager = packed.instantiate() as GameManager
	add_child(manager)
	await _frames(3)
	await _run_tests()


func _check(condition: bool, label: String, detail: String = "") -> void:
	checks += 1
	if condition:
		print("  [PASS] ", label)
	else:
		failures += 1
		print("  [FAIL] ", label, "  ", detail)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


func _physics_frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame


func _click_at(position: Vector2) -> void:
	if not gui_input_available:
		return
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	get_viewport().push_input(motion)
	await _frames(1)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(press)
	await _frames(1)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	Input.parse_input_event(release)
	await _frames(2)


func _send_action(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await _frames(2)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await _frames(1)


func _serve_correct(recipe_id: String, sauce_id: String) -> bool:
	var customer := manager.customer_queue.spawn_customer_now(recipe_id, sauce_id)
	if customer == null:
		_check(false, "连续订单顾客生成失败")
		return false
	await _frames(1)
	var sausages: Array = []
	for i in range(int(customer.order.get("sausages", 1))):
		sausages.append(GameData.make_cooked_sausage("perfect", 9.0))
	var dog := GameData.make_hotdog(sausages, {
		"ketchup": bool(customer.order.get("ketchup", false)),
		"mustard": bool(customer.order.get("mustard", false)),
	})
	manager.player.set_item(dog)
	return await _teleport_and_interact("Entities/DeliveryStation")


func _check_reachability() -> void:
	const STEP := 10
	var start := Vector2i(int(manager.player.position.x / STEP), int(manager.player.position.y / STEP))
	var visited := {start: true}
	var frontier: Array[Vector2i] = [start]
	var directions := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for d: Vector2i in directions:
			var next := cell + d
			if visited.has(next):
				continue
			if next.x < 0 or next.y < 0 or next.x > 128 or next.y > 72:
				continue
			var world := Vector2(next) * float(STEP)
			if not manager.player._can_stand(world):
				continue
			visited[next] = true
			frontier.append(next)
	var unreachable: Array[String] = []
	for node in get_tree().get_nodes_in_group("stations"):
		var station := node as Station
		var target := station.get_interaction_position()
		var found := false
		for cell: Vector2i in visited.keys():
			var world := Vector2(cell) * float(STEP)
			if world.distance_to(target) <= station.interaction_radius:
				found = true
				break
		if not found:
			unreachable.append(station.display_name)
	_check(unreachable.is_empty(), "所有设备交互点均可步行到达",
		"无法到达: " + ", ".join(unreachable))


func _teleport_and_interact(path: String) -> bool:
	var station := manager.get_node(path) as Station
	if station == null:
		_check(false, "找不到设备 " + path)
		return false
	manager.player.position = station.get_interaction_position()
	await _frames(3)
	return manager.interaction_system.try_interact()


func _run_tests() -> void:
	print("\n[1] 启动 / 场景结构")
	_check(manager != null, "Main.tscn 实例化成功")
	_check(manager.state == GameManager.State.TITLE, "启动进入标题状态")
	_check(manager.ui.start_screen.visible, "标题界面可见")
	_check(manager.ui.hud.visible == false, "标题界面下 HUD 隐藏")
	_check(manager.get_tree().get_nodes_in_group("stations").size() == 8,
		"8 个功能设备全部注册", str(manager.get_tree().get_nodes_in_group("stations").size()))
	_check(manager.player != null and not manager.player.input_enabled, "标题状态禁止移动")

	print("\n[2] 开始营业 / 玩家移动 / 全设备可达性")
	if gui_input_available:
		await _click_at(Vector2(640, 560))
		await _frames(3)
		_check(manager.state == GameManager.State.PLAYING, "鼠标点击开始营业按钮")
	else:
		print("  [SKIP] 鼠标点击开始营业按钮（无头模式没有 GUI 输入）")
	if manager.state != GameManager.State.PLAYING:
		manager.start_shift()
		await _frames(1)
	_check(manager.state == GameManager.State.PLAYING, "进入营业状态")
	_check(manager.player.input_enabled, "营业状态允许移动")
	_check(manager.ui.hud.visible, "HUD 已显示")
	_check_reachability()
	var start_x := manager.player.position.x
	Input.action_press("move_right")
	await _physics_frames(18)
	Input.action_release("move_right")
	await _physics_frames(2)
	_check(manager.player.position.x > start_x + 5.0, "WASD 屏幕方向移动有效",
		"x %.1f -> %.1f" % [start_x, manager.player.position.x])

	print("\n[3] 订单与顾客生成")
	# 不手动生成，先等营业计时器把第一位顾客送进来。
	var waited := 0.0
	while manager.customer_queue.customers.is_empty() and waited < 2.0:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	_check(not manager.customer_queue.customers.is_empty(), "顾客按到店计时自动生成",
		"等待 %.1fs" % waited)
	manager.customer_queue.clear_all()
	var customer := manager.customer_queue.spawn_customer_now("classic", "ketchup")
	await _frames(2)
	_check(customer != null, "顾客成功到店")
	_check(manager.customer_queue.get_front() == customer, "顾客进入队首")
	_check(not customer.order.is_empty(), "顾客拥有订单")
	_check(str(customer.order.get("recipe_name", "")) == "经典热狗", "订单为经典热狗")
	_check(str(customer.order.get("sauce_name", "")) == "番茄酱", "订单为番茄酱")

	print("\n[4] 取生肠 -> 烤制 -> 完美火候")
	var ok := await _teleport_and_interact("Entities/SausageStation")
	_check(ok, "生肠冷柜交互成功")
	_check(manager.player.item_type() == "raw_sausage", "手持生热狗肠",
		manager.player.item_type())
	ok = await _teleport_and_interact("Entities/GrillStation")
	_check(ok, "煎烤台放入交互成功")
	_check(manager.player.get_item().is_empty(), "放入后手部清空")
	_check(manager.cooking_system.occupied_count() == 1, "烤架占用 1 个烤位")
	_check(GameData.cook_state(9.0).get("id", "") == "perfect", "9 秒对应完美火候")
	manager.cooking_system.set_slot_time(0, 9.2)
	await _frames(1)
	ok = await _teleport_and_interact("Entities/GrillStation")
	_check(ok, "煎烤台取出交互成功")
	_check(manager.player.item_type() == "cooked_sausage", "手持烤好的肠")
	_check(str(manager.player.get_item().get("quality", "")) == "perfect", "取出品质为完美")

	print("\n[5] 组装 -> 面包 -> 挤酱")
	ok = await _teleport_and_interact("Entities/AssemblyStation")
	_check(ok, "烤肠放上组装台")
	_check(manager.assembly_station.board_sausages.size() == 1, "案板有 1 根烤肠")
	ok = await _teleport_and_interact("Entities/BunStation")
	_check(ok, "面包篮交互成功")
	_check(manager.player.item_type() == "bun", "手持热狗面包")
	ok = await _teleport_and_interact("Entities/AssemblyStation")
	_check(ok, "面包合上热狗")
	_check(not manager.assembly_station.board_hotdog.is_empty(), "案板上出现成品热狗")
	ok = await _teleport_and_interact("Entities/AssemblyStation")
	_check(ok, "拿起成品热狗")
	_check(manager.player.item_type() == "hotdog", "手持热狗")
	_check(int(manager.player.get_item().get("count", 0)) == 1, "热狗为单肠")
	ok = await _teleport_and_interact("Entities/KetchupStation")
	_check(ok, "番茄酱台交互成功")
	var hotdog := manager.player.get_item()
	_check(bool(hotdog.get("sauces", {}).get("ketchup", false)), "热狗已加番茄酱")

	print("\n[6] 交付 / 金币 / 满意度 / 统计")
	var coins_before := manager.economy_system.coins
	var served_before := int(manager.economy_system.stats.get("served", 0))
	ok = await _teleport_and_interact("Entities/DeliveryStation")
	_check(ok, "交付窗口交互成功")
	_check(manager.player.get_item().is_empty(), "交付后手部清空")
	_check(manager.economy_system.coins > coins_before, "交付获得金币",
		"%d -> %d" % [coins_before, manager.economy_system.coins])
	_check(int(manager.economy_system.stats.get("served", 0)) == served_before + 1, "接待数 +1")
	_check(manager.customer_queue.get_front() == null, "队首顾客已离店")

	print("\n[7] 错误交付惩罚")
	var wrong_customer := manager.customer_queue.spawn_customer_now("classic", "mustard")
	await _frames(1)
	_check(wrong_customer != null, "第二位顾客到店")
	var wrong_coins_before := manager.economy_system.coins
	var wrong_before := int(manager.economy_system.stats.get("wrong", 0))
	var wrong_sat_before := manager.economy_system.satisfaction
	var bad_dog := GameData.make_hotdog([GameData.make_cooked_sausage("perfect", 9.0)],
		{"ketchup": true, "mustard": false})
	manager.player.set_item(bad_dog)
	ok = await _teleport_and_interact("Entities/DeliveryStation")
	_check(ok, "错误热狗可以递交")
	_check(int(manager.economy_system.stats.get("wrong", 0)) == wrong_before + 1, "错误交付统计 +1")
	_check(manager.economy_system.coins <= wrong_coins_before, "错误交付扣金币")
	_check(manager.economy_system.satisfaction < wrong_sat_before, "错误交付扣满意度")

	print("\n[8] 顾客耐心耗尽")
	var lost_customer := manager.customer_queue.spawn_customer_now("classic", "ketchup")
	await _frames(1)
	var lost_before := int(manager.economy_system.stats.get("lost", 0))
	var sat_before_timeout := manager.economy_system.satisfaction
	if lost_customer:
		lost_customer.arriving = false
		lost_customer._process(999.0)
		await _frames(2)
	_check(int(manager.economy_system.stats.get("lost", 0)) == lost_before + 1, "超时顾客计入流失")
	_check(manager.economy_system.satisfaction < sat_before_timeout, "超时扣满意度")

	print("\n[9] 暂停 / 继续")
	manager.toggle_pause()
	_check(manager.state == GameManager.State.PAUSED, "暂停状态正确")
	_check(get_tree().paused, "暂停时场景树停止")
	_check(manager.ui.pause_screen.visible, "暂停菜单显示")
	manager.resume_game()
	_check(manager.state == GameManager.State.PLAYING, "继续营业恢复")
	_check(not get_tree().paused, "继续时场景树恢复")

	print("\n[10] 结算 / 重开")
	manager.end_shift("shift_end")
	_check(manager.state == GameManager.State.GAME_OVER, "结束状态正确")
	_check(manager.ui.results_screen.visible, "结算界面显示")
	_check(manager.ui.hud.visible == false, "结算时 HUD 隐藏")
	_check(manager.results.has("rank") and manager.results.has("coins"), "结算数据完整")
	if gui_input_available:
		await _click_at(Vector2(496, 619))
		await _frames(2)
		_check(manager.state == GameManager.State.PLAYING, "结算界面鼠标点击再开一局")
	else:
		print("  [SKIP] 结算界面鼠标点击（无头模式没有 GUI 输入）")
	if manager.state != GameManager.State.PLAYING:
		manager.restart_round()
	await _frames(2)
	_check(manager.state == GameManager.State.PLAYING, "重开后进入营业")
	_check(not get_tree().paused, "重开后解除暂停")
	_check(manager.economy_system.coins == 0, "重开后金币归零")
	_check(manager.player.get_item().is_empty(), "重开后空手")
	_check(manager.ui.hud.visible and not manager.ui.results_screen.visible, "重开后 HUD 恢复")

	print("\n[11] 连续完成多笔订单")
	manager.customer_queue.clear_all()
	var served_before_streak := int(manager.economy_system.stats.get("served", 0))
	var coins_before_streak := manager.economy_system.coins
	await _serve_correct("classic", "mustard")
	await _serve_correct("double", "both")
	await _serve_correct("classic", "ketchup")
	_check(int(manager.economy_system.stats.get("served", 0)) == served_before_streak + 3,
		"连续完成 3 笔订单", str(manager.economy_system.stats.get("served", 0)))
	_check(manager.economy_system.coins > coins_before_streak, "连续订单持续产生金币")
	_check(manager.customer_queue.get_front() == null, "连续订单后队列清空")

	print("\n[12] 先放面包的组装流程")
	manager.assembly_station.reset_board()
	manager.player.clear_item()
	await _teleport_and_interact("Entities/BunStation")
	await _teleport_and_interact("Entities/AssemblyStation")
	_check(manager.assembly_station.board_bun and manager.player.get_item().is_empty(),
		"面包可以先放在组装台上")
	manager.player.set_item(GameData.make_cooked_sausage("perfect", 9.0))
	await _teleport_and_interact("Entities/AssemblyStation")
	_check(manager.assembly_station.board_sausages.size() == 1, "空手返回后可以加入烤肠")
	await _teleport_and_interact("Entities/AssemblyStation")
	_check(not manager.assembly_station.board_hotdog.is_empty(), "空手按 E 可以合上热狗")
	await _teleport_and_interact("Entities/AssemblyStation")
	_check(manager.player.item_type() == "hotdog", "先放面包的流程也能拿到成品")
	manager.player.clear_item()

	print("\n[13] 真实输入事件（E / ESC）")
	manager.player.clear_item()
	manager.player.position = (manager.get_node("Entities/BunStation") as Station).get_interaction_position()
	await _frames(3)
	await _send_action("interact")
	_check(manager.player.item_type() == "bun", "键盘 E 事件触发设备交互",
		manager.player.item_type())
	manager.player.clear_item()
	await _send_action("pause")
	_check(manager.state == GameManager.State.PAUSED, "键盘 ESC 事件触发暂停")
	_check(get_tree().paused, "ESC 暂停后场景树停止")
	if gui_input_available:
		await _click_at(Vector2(640, 319))
		await _frames(2)
		_check(manager.state == GameManager.State.PLAYING, "鼠标点击继续营业按钮")
		_check(not get_tree().paused, "暂停菜单点击继续后场景树恢复")
	else:
		print("  [SKIP] 暂停菜单鼠标点击（无头模式没有 GUI 输入）")
		await _send_action("pause")
	_check(manager.state == GameManager.State.PLAYING, "暂停后可以恢复营业")
	_check(not get_tree().paused, "恢复后场景树继续")
	await _send_action("pause")
	_check(manager.state == GameManager.State.PAUSED, "再次 ESC 暂停")
	await _send_action("pause")
	_check(manager.state == GameManager.State.PLAYING, "再按 ESC 恢复营业")
	_check(not get_tree().paused, "ESC 恢复后场景树继续")

	print("\n[14] 纯数据边界")
	_check(GameData.cook_state(0.0).get("id", "") == "raw", "0 秒为生的")
	_check(GameData.cook_state(4.0).get("id", "") == "heating", "4 秒为加热中")
	_check(GameData.cook_state(6.5).get("id", "") == "just_cooked", "6.5 秒为刚刚熟透")
	_check(GameData.cook_state(20.0).get("id", "") == "burnt", "20 秒为烤焦")
	var raw_dog := GameData.make_hotdog([GameData.make_cooked_sausage("raw", 0.0)], {})
	var validation := manager.order_system.validate_order(
		{"sausages": 1, "ketchup": false, "mustard": false}, raw_dog)
	_check(not bool(validation.get("ok", true)), "生肠不能交付")

	print("\n[15] 自动结束条件")
	manager.time_left = 0.03
	manager._process(0.05)
	_check(manager.state == GameManager.State.GAME_OVER, "营业时间耗尽自动结束")
	_check(str(manager.results.get("reason", "")) == "shift_end", "计时结束原因正确")
	manager.restart_round()
	await _frames(2)
	_check(manager.state == GameManager.State.PLAYING, "自动结束后可以重开")
	manager.economy_system.satisfaction = 1
	manager.economy_system.penalize_timeout("测试顾客")
	await _frames(1)
	_check(manager.state == GameManager.State.GAME_OVER, "满意度归零提前打烊")
	_check(str(manager.results.get("reason", "")) == "satisfaction", "满意度结束原因正确")

	print("\n========== 验收结束：%d 项检查，%d 项失败 ==========" % [checks, failures])
	get_tree().paused = false
	manager.customer_queue.stop()
	await _frames(1)
	get_tree().quit(0 if failures == 0 else 1)
