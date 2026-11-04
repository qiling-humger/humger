extends Node
## 家园岛地图原型自动验收。覆盖逻辑网格、玩家、采集、建造和搬动。

var game: MapGame
var checks := 0
var failures := 0


func _ready() -> void:
	print("\n========== 家园岛原型验收开始 ==========")
	var packed := load("res://map_prototype/MapPrototype.tscn") as PackedScene
	game = packed.instantiate() as MapGame
	add_child(game)
	await _frames(8)
	await _run_tests()
	print("\n========== 验收结束：%d 项检查，%d 项失败 ==========" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _run_tests() -> void:
	print("\n[1] 场景 / 网格")
	_check(game != null, "MapPrototype 实例化成功")
	_check(game.grid.columns == 24 and game.grid.rows == 18, "网格为 24×18",
		"%d×%d" % [game.grid.columns, game.grid.rows])
	_check(game.grid.tile_width == 64.0 and game.grid.tile_height == 32.0,
		"Tile 为 64×32")
	_check(game.grid.get_land_count() > 250, "海岛陆地格数量足够",
		str(game.grid.get_land_count()))
	_check(not game.grid.is_land(Vector2i(0, 0)), "地图角落是海水")
	var sample := Vector2i(11, 9)
	var roundtrip := game.grid.world_to_cell(game.grid.cell_to_world(sample))
	_check(roundtrip == sample, "逻辑格与屏幕坐标可逆", str(roundtrip))

	print("\n[2] 玩家 / 碰撞 / 镜头")
	var spawn := game.grid.world_to_cell(game.player.position)
	_check(game.grid.is_land(spawn), "玩家出生在陆地上", str(spawn))
	_check(game.player.get_node("Camera2D").enabled, "镜头已启用")
	_check(game.player.can_stand(game.player.position), "出生点可站立")
	_check(not game.player.can_stand(game.grid.cell_to_world(Vector2i(0, 0))),
		"玩家不能站进海水")
	var tree_cell := Vector2i(6, 4)
	_check(not game.player.can_stand(game.grid.cell_to_world(tree_cell)),
		"玩家不能站进树干占格")
	var before_move := game.player.position
	Input.action_press("move_right")
	await _frames(18)
	Input.action_release("move_right")
	await _frames(2)
	_check(game.player.position.x > before_move.x + 4.0, "WASD 屏幕向右移动有效",
		"%.1f -> %.1f" % [before_move.x, game.player.position.x])
	_check(game.player.get_node("Camera2D").global_position.distance_to(
		game.player.global_position) < 90.0, "镜头跟随玩家")
	game.player.position = game.grid.cell_to_world(Vector2i(6, 5))
	await _frames(3)

	print("\n[3] 资源节点 / E 采集 / 库存")
	_check(game.resource_nodes.size() == 22, "资源节点数量正确",
		str(game.resource_nodes.size()))
	var types := {}
	for node in game.resource_nodes:
		types[node.node_type] = true
	_check(types.has("tree") and types.has("bush") and types.has("leaf_pile")
		and types.has("rock"), "树/草丛/落叶堆/石块齐全", str(types.keys()))
	_check(game.inventory.get_count("wood") == 0, "开局木材为 0")
	game._refresh_nearest()
	_check(game.nearest_resource != null and game.nearest_resource.node_type == "tree",
		"靠近树时自动选中树")
	var tree := game.nearest_resource
	var tree_start_uses := tree.uses_left
	_check(game.gather_nearest(), "E 采集调用成功")
	_check(game.inventory.get_count("wood") == 2, "采集一次获得 2 木材",
		str(game.inventory.get_count("wood")))
	_check(tree.uses_left == tree_start_uses - 1, "采集次数递减")
	game.gather_nearest()
	game.gather_nearest()
	_check(tree.is_depleted(), "资源耗尽后进入枯竭状态")
	_check(game.inventory.get_count("wood") == 6, "树上限 3 次采集共 6 木材",
		str(game.inventory.get_count("wood")))
	_check(game.nearest_resource == null or game.nearest_resource != tree,
		"枯竭资源不再作为交互目标")

	print("\n[4] 建造模式 / 多格 footprint")
	game.toggle_build_mode()
	_check(game.placement.build_mode, "B 进入建造模式")
	_check(game.island_map.build_mode, "建造模式强化网格")
	var sizes := [Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 3)]
	for i in range(sizes.size()):
		var size: Vector2i = sizes[i]
		var origin := _find_empty_origin(size)
		_check(origin.x >= 0, "找到 %d×%d 放置位置" % [size.x, size.y], str(origin))
		if origin.x < 0:
			continue
		game.select_buildable(i)
		var target := game.grid.world_from_float(Vector2(
			origin.x + (size.x - 1) * 0.5, origin.y + (size.y - 1) * 0.5))
		var before_count := game.placed_objects.size()
		var placed_ok := game.placement.try_place_at(target)
		_check(placed_ok and game.placed_objects.size() == before_count + 1,
			"放置 %d×%d 物件成功" % [size.x, size.y])
		var placed: IslandPlaceable = game.placed_objects.back()
		_check(placed.origin == origin and placed.size == size,
			"%d×%d footprint 数据正确" % [size.x, size.y],
			"%s / %s" % [str(placed.origin), str(placed.size)])
		_check(not game.grid.can_place(origin, size),
			"放置后占格被锁定")
	_check(game.placed_objects.size() == 7, "初始 3 件 + 新建 4 件",
		str(game.placed_objects.size()))
	var invalid_origin := Vector2i(0, 0)
	_check(not game.grid.can_place(invalid_origin, Vector2i(1, 1)),
		"海水格不能放置")
	var occupied_origin: Vector2i = game.placed_objects.back().origin
	_check(not game.grid.can_place(occupied_origin, Vector2i(1, 1)),
		"已占格不能重复放置")
	_check(game.spawn_placeable(game.find_def("crate"), occupied_origin) == null,
		"重复放置会被逻辑层拒绝")
	game.exit_build_mode()
	_check(not game.placement.build_mode, "Esc/退出建造模式生效")

	print("\n[4b] 真实 B 键事件")
	var b_event := InputEventKey.new()
	b_event.keycode = KEY_B
	b_event.physical_keycode = KEY_B
	b_event.pressed = true
	Input.parse_input_event(b_event)
	await _frames(3)
	_check(game.placement.build_mode, "键盘 B 事件进入建造模式")
	var esc_event := InputEventKey.new()
	esc_event.keycode = KEY_ESCAPE
	esc_event.pressed = true
	Input.parse_input_event(esc_event)
	await _frames(3)
	_check(not game.placement.build_mode, "键盘 Esc 事件退出建造模式")

	print("\n[5] 搬动 / 非法位置回滚")
	var movable: IslandPlaceable = null
	for object in game.placed_objects:
		if str(object.def.get("id", "")) == "crate":
			movable = object
			break
	_check(movable != null, "存在可搬动初始物件")
	if movable != null:
		var old_origin := movable.origin
		var old_cells := movable.get_cells()
		var start_center := game.grid.cell_to_world(old_origin)
		var drag_started := game.placement.begin_drag(start_center)
		_check(drag_started and game.placement.is_dragging(), "按住已放置物件开始搬动")
		_check(not game.grid.is_blocking_at(start_center), "拖动时原占格暂时释放")
		var target := _find_empty_origin(Vector2i(1, 1))
		var target_center := game.grid.cell_to_world(target)
		game.placement.update_drag(target_center)
		_check(game.placement.preview_valid, "新位置合法预览为绿色")
		game.placement.finish_drag(target_center)
		_check(not game.placement.is_dragging(), "松开后结束搬动")
		_check(movable.origin == target, "物件 origin 已更新", str(movable.origin))
		_check(not game.grid.is_blocking_at(start_center), "旧占格已释放")
		_check(game.grid.is_blocking_at(target_center), "新占格已登记阻挡")
		# 再拖到海水，必须回滚到上一个合法位置。
		var before_bad := movable.origin
		game.placement.begin_drag(game.grid.cell_to_world(before_bad))
		var water_center := game.grid.cell_to_world(Vector2i(0, 0))
		game.placement.update_drag(water_center)
		_check(not game.placement.preview_valid, "海水位置预览为非法")
		game.placement.finish_drag(water_center)
		_check(movable.origin == before_bad, "非法搬动回滚到原位置", str(movable.origin))
		_check(game.grid.is_blocking_at(game.grid.cell_to_world(before_bad)),
			"回滚后占格恢复")
	# 2×2 也走同一套搬动逻辑。
	var medium: IslandPlaceable = null
	for object in game.placed_objects:
		if object.size == Vector2i(2, 2):
			medium = object
			break
	_check(medium != null, "存在 2×2 物件用于搬动")
	if medium != null:
		var medium_old := medium.origin
		var medium_target := _find_empty_origin(Vector2i(2, 2))
		_check(medium_target.x >= 0, "找到 2×2 新位置", str(medium_target))
		_check(game.placement.begin_drag(game.grid.cell_to_world(medium_old)),
			"按住 2×2 物件开始搬动")
		var medium_center := game.grid.world_from_float(Vector2(
			medium_target.x + 0.5, medium_target.y + 0.5))
		game.placement.finish_drag(medium_center)
		_check(medium.origin == medium_target, "2×2 物件搬动成功", str(medium.origin))
	# 3×3 也走同一套搬动逻辑。
	var big: IslandPlaceable = null
	for object in game.placed_objects:
		if object.size == Vector2i(3, 3):
			big = object
			break
	_check(big != null, "存在 3×3 物件用于搬动")
	if big != null:
		var big_old := big.origin
		var big_target := _find_empty_origin(Vector2i(3, 3))
		_check(big_target.x >= 0, "找到 3×3 新位置", str(big_target))
		_check(game.placement.begin_drag(game.grid.cell_to_world(big_old)),
			"按住 3×3 物件开始搬动")
		var big_center := game.grid.world_from_float(Vector2(
			big_target.x + 1.0, big_target.y + 1.0))
		game.placement.finish_drag(big_center)
		_check(big.origin == big_target, "3×3 物件搬动成功", str(big.origin))
		_check(game.player.can_stand(game.player.position), "测试结束后玩家仍在可站立位置")
	_check(game.inventory.get_count("wood") == 6, "资源栏数据保持")


func _find_empty_origin(size: Vector2i) -> Vector2i:
	for y in range(0, game.grid.rows - size.y + 1):
		for x in range(0, game.grid.columns - size.x + 1):
			var origin := Vector2i(x, y)
			if game.grid.can_place(origin, size):
				return origin
	return Vector2i(-1, -1)


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
