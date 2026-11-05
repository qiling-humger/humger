extends Node
## Home Island V1 acceptance: map/water, rabbit, gathering, build/move/demolish,
## and save/load. This is an engine-level headless test, not a mock.

var game: HomeIslandGame
var checks := 0
var failures := 0
const TEST_SAVE := "user://home_island_test_save.json"


func _ready() -> void:
	print("\n========== 家园岛 V1 验收开始 ==========")
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var packed := load("res://home_island/HomeIsland.tscn") as PackedScene
	game = packed.instantiate() as HomeIslandGame
	game.persistence_enabled = false
	add_child(game)
	await _frames(12)
	await _run_tests()
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("\n========== 家园岛 V1 验收结束：%d 项检查，%d 项失败 ==========" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _run_tests() -> void:
	print("\n[1] 地图 / 水域 / 沙滩 / 隐藏网格")
	_check(game != null, "HomeIsland 实例化成功")
	_check(game.grid.columns == 24 and game.grid.rows == 20, "网格为 24×20",
		"%d×%d" % [game.grid.columns, game.grid.rows])
	_check(game.grid.get_land_count() >= 90, "海岛陆地数量足够",
		str(game.grid.get_land_count()))
	_check(game.grid.is_water(Vector2i(0, 0)), "地图角落是水域")
	var sand_count := 0
	var road_count := 0
	var flower_count := 0
	for cell in game.grid.get_land_cells():
		match game.grid.terrain_at(cell):
			IslandGrid.SAND:
				sand_count += 1
			IslandGrid.ROAD:
				road_count += 1
			IslandGrid.FLOWER:
				flower_count += 1
	_check(sand_count == 72, "沙滩分布符合参考图", str(sand_count))
	_check(road_count == 9, "道路分布符合参考图", str(road_count))
	_check(flower_count == 12, "花草分布符合参考图", str(flower_count))
	var landmarks := game.get_node_or_null("MapLandmarks")
	_check(landmarks != null and landmarks.get_child_count() == 3,
		"兔屋/餐厅/码头三个地标存在")
	_check(game.terrain.land_tile_count == game.grid.get_land_count(),
		"每块陆地都有独立地形 Sprite", str(game.terrain.land_tile_count))
	_check(not game.terrain.is_grid_visible(), "普通状态网格隐藏")

	print("\n[2] 兔子 / 移动 / 待机行走")
	var sprite: AnimatedSprite2D = game.player.get_node("AnimatedSprite2D")
	_check(sprite.sprite_frames.has_animation("idle_down")
		and sprite.sprite_frames.has_animation("walk_down")
		and sprite.sprite_frames.has_animation("idle_side")
		and sprite.sprite_frames.has_animation("walk_side")
		and sprite.sprite_frames.has_animation("idle_up")
		and sprite.sprite_frames.has_animation("walk_up"), "六个方向/状态动画存在")
	_check(sprite.sprite_frames.get_frame_count("walk_down") == 4,
		"下行走路 4 帧", str(sprite.sprite_frames.get_frame_count("walk_down")))
	_check(sprite.sprite_frames.get_frame_count("idle_down") == 2,
		"下行待机 2 帧")
	await _frames(4)
	_check(sprite.animation.begins_with("idle_") and sprite.frame == 0,
		"待机默认使用睁眼帧", "%s/%d" % [sprite.animation, sprite.frame])
	var before := game.player.position
	Input.action_press("move_right")
	await _frames(16)
	var moving_anim := sprite.animation
	Input.action_release("move_right")
	await _frames(4)
	_check(game.player.position.x > before.x + 3.0, "WASD 移动有效",
		"%.1f -> %.1f" % [before.x, game.player.position.x])
	_check(moving_anim == "walk_side", "移动时播放行走动画", moving_anim)
	_check(sprite.animation.begins_with("idle_"), "停下后回到待机")
	_check(game.player.can_stand(game.grid.cell_to_world(Vector2i(7, 6))),
		"出生区域可站立")
	_check(not game.player.can_stand(game.grid.cell_to_world(Vector2i(0, 0))),
		"玩家不能进入海水")

	print("\n[3] 三种资源采集 / 枯竭状态 / 资源统计")
	var tree: VisualSampleResource = _resource_by_type("tree")
	var bush: VisualSampleResource = _resource_by_type("bush")
	var rock: VisualSampleResource = _resource_by_type("rock")
	_check(tree != null and bush != null and rock != null, "树/草丛/石头齐全")
	_check(game.resource_nodes.size() == 25, "资源节点数量为 25",
		str(game.resource_nodes.size()))
	var reachable := _reachable_cells(game.grid.world_to_cell(game.player.position))
	var all_reachable := true
	for node in game.resource_nodes:
		var has_reachable_neighbor := false
		for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			if reachable.has(node.cell + d):
				has_reachable_neighbor = true
				break
		if not has_reachable_neighbor:
			all_reachable = false
			print("  [DETAIL] unreachable resource ", node.node_id, " at ", node.cell)
	_check(all_reachable, "所有资源至少有一个可达邻格")
	if tree:
		_move_next_to(tree)
		game._refresh_nearest()
		_check(game.gather_nearest(), "靠近树采集成功")
		game.gather_nearest()
		game.gather_nearest()
		_check(tree.is_depleted(), "树采集 3 次后耗尽")
		_check(game.inventory.get_count("wood") == 6, "木材累计 6",
			str(game.inventory.get_count("wood")))
		var visual := tree.get("_sprite") as Sprite2D
		_check(visual != null and visual.modulate.a < 0.9,
			"树耗尽后视觉变淡")
	if bush:
		_move_next_to(bush)
		game._refresh_nearest()
		game.gather_nearest()
		game.gather_nearest()
		_check(bush.is_depleted(), "草丛采集 2 次后耗尽")
		_check(game.inventory.get_count("grass") == 4, "草累计 4",
			str(game.inventory.get_count("grass")))
	if rock:
		_move_next_to(rock)
		game._refresh_nearest()
		game.gather_nearest()
		game.gather_nearest()
		game.gather_nearest()
		_check(rock.is_depleted(), "石头采集 3 次后耗尽")
		_check(game.inventory.get_count("stone") == 3, "石头累计 3",
			str(game.inventory.get_count("stone")))

	var rotated_origin := Vector2i(-9, -9)
	print("\n[4] 建造 / 绿红预览 / 多格 / 拆除")
	game.toggle_build_mode()
	_check(game.placement.build_mode, "B 建造模式开启")
	_check(game.terrain.is_grid_visible(), "建造模式显示网格")
	game.select_buildable(1)
	var target := _find_empty(Vector2i(2, 1))
	_check(target.x >= 0, "找到 2×1 放置位置", str(target))
	var target_world := game.grid.world_from_float(Vector2(target.x + 0.5, target.y))
	game.placement.update_preview(target_world)
	_check(game.placement.preview_valid, "合法位置预览为绿色")
	await _frames(2)
	var ghost := game.placement.get("_ghost") as Sprite2D
	_check(ghost != null and ghost.visible, "半透明放置预览可见")
	var count_before := game.placed_objects.size()
	_check(game.placement.try_place_at(target_world), "2×1 放置成功")
	_check(game.placed_objects.size() == count_before + 1, "物件数量增加")
	_check(not game.grid.can_place(target, Vector2i(2, 1)), "放置后占格锁定")
	game.placement.update_preview(game.grid.cell_to_world(Vector2i(0, 0)))
	_check(not game.placement.preview_valid, "水面位置预览为红色/非法")
	_check(not game.placement.try_place_at(game.grid.cell_to_world(Vector2i(0, 0))),
		"水面放置被拒绝")
	game.exit_build_mode()
	_check(not game.placement.build_mode and not game.terrain.is_grid_visible(),
		"退出建造后网格隐藏")
	var demolished := game.placement as HomeIslandPlacement
	_check(demolished.demolish_at(target_world), "右键式拆除成功")
	_check(game.placed_objects.size() == count_before, "拆除后物件数量恢复")
	_check(game.grid.can_place(target, Vector2i(2, 1)), "拆除后占格释放")

	print("\n[4b] 旋转 / 占地 / 碰撞 / 存档")
	game.toggle_build_mode()
	game.select_buildable(1)
	var rotated_target := _find_empty(Vector2i(1, 2))
	var rotated_world := game.grid.world_from_float(
		Vector2(rotated_target.x, rotated_target.y + 0.5))
	game.placement.update_preview(rotated_world)
	_check(game.placement.preview_size == Vector2i(2, 1), "未旋转时桌子 2×1")
	game.placement.rotate_preview(1)
	_check(game.placement.preview_rotation == 1
		and game.placement.preview_size == Vector2i(1, 2),
		"旋转 90° 后宽高互换")
	game.placement.rotate_preview(1)
	_check(game.placement.preview_size == Vector2i(2, 1), "连续旋转 180° 恢复 2×1")
	game.placement.rotate_preview(1)
	_check(game.placement.preview_size == Vector2i(1, 2), "连续旋转 270° 为 1×2")
	game.placement.rotate_preview(1)
	_check(game.placement.preview_size == Vector2i(2, 1), "连续旋转 360° 回到 2×1")
	game.placement.rotate_preview(-1)
	_check(game.placement.preview_rotation == 3
		and game.placement.preview_size == Vector2i(1, 2),
		"Shift+R 逆时针旋转 90°")
	game.placement.rotate_preview(1)
	_check(game.placement.preview_rotation == 0
		and game.placement.preview_size == Vector2i(2, 1),
		"顺时针旋转回 2×1")
	game.placement.rotate_preview(1)
	_check(game.placement.preview_rotation == 1
		and game.placement.preview_size == Vector2i(1, 2),
		"确认前回到 1×2 朝向")
	game.placement.update_preview(game.grid.cell_to_world(Vector2i(0, 0)))
	_check(not game.placement.preview_valid, "旋转后水面为红色非法预览")
	game.placement.update_preview(rotated_world)
	_check(game.placement.preview_valid, "旋转后合法位置为绿色预览")
	var before_rotated := game.placed_objects.size()
	_check(game.placement.try_place_at(rotated_world), "旋转后的桌子放置成功")
	_check(game.placed_objects.size() == before_rotated + 1, "旋转桌子数量增加")
	var rotated_table: VisualSamplePlaceable = game.placed_objects.back()
	rotated_origin = rotated_table.origin
	_check(rotated_table.rotation_quarters == 1
		and rotated_table.size == Vector2i(1, 2),
		"放置后保留 1×2 朝向")
	_check(not game.grid.can_place(rotated_origin, Vector2i(1, 2)),
		"旋转后的占格参与碰撞")
	var pivot := rotated_table.get("_pivot") as Node2D
	_check(pivot != null
		and pivot.position.is_equal_approx(
			rotated_table.get_footprint_center() - rotated_table.position),
		"旋转物件使用统一底部锚点")
	var rotated_sprite := rotated_table.get("_sprite") as Sprite2D
	_check(rotated_sprite != null
		and rotated_sprite.texture.resource_path.contains("table_rotated")
		and VisualAnchor.bottom_pad(rotated_sprite.texture) > 0.0,
		"旋转视觉使用 1×2 变体贴图且底部 alpha 对齐")
	_check(game.has_rotated_texture("table"), "旋转变体贴图已配置")
	game.exit_build_mode()

	print("\n[5] 搬动 / 非法回滚")
	var crate: VisualSamplePlaceable = null
	for object in game.placed_objects:
		if str(object.def.get("id", "")) == "crate":
			crate = object
			break
	_check(crate != null, "初始木箱存在")
	if crate:
		var old_origin := crate.origin
		var move_target := _find_empty(Vector2i(1, 1))
		_check(move_target.x >= 0, "找到搬动目标", str(move_target))
		_check(game.placement.begin_drag(game.grid.cell_to_world(old_origin)),
			"拖动木箱开始")
		game.placement.update_drag(game.grid.cell_to_world(move_target))
		_check(game.placement.preview_valid, "搬动合法预览绿色")
		game.placement.finish_drag(game.grid.cell_to_world(move_target))
		_check(crate.origin == move_target, "木箱搬动成功", str(crate.origin))
		var crate_pivot := crate.get("_pivot") as Node2D
		_check(crate_pivot != null and crate_pivot.position.is_equal_approx(
			crate.get_footprint_center() - crate.position),
			"1×1 物件统一底部锚点")
		game.placement.begin_drag(game.grid.cell_to_world(move_target))
		game.placement.finish_drag(game.grid.cell_to_world(Vector2i(0, 0)))
		_check(crate.origin == move_target, "非法搬动回滚", str(crate.origin))

	print("\n[6] 存档 / 重启恢复")
	var saved_player_cell := Vector2i(12, 9)
	game.player.position = game.grid.cell_to_world(saved_player_cell)
	var saved_wood := game.inventory.get_count("wood")
	var saved_grass := game.inventory.get_count("grass")
	var saved_stone := game.inventory.get_count("stone")
	var saved_tree_uses: int = tree.uses_left if tree else -1
	var saved_crate_origin := crate.origin if crate else Vector2i(-1, -1)
	_check(game.save_game(TEST_SAVE), "保存存档成功")
	# Mutate everything that should be restored.
	game.inventory.add("wood", 9)
	game.player.position = game.grid.cell_to_world(Vector2i(1, 1))
	if tree and not tree.is_depleted():
		tree.gather()
	if crate:
		crate.set_origin(Vector2i(6, 6))
	_check(game.load_game(TEST_SAVE), "读取存档成功")
	_check(game.inventory.get_count("wood") == saved_wood, "木材数量恢复",
		str(game.inventory.get_count("wood")))
	_check(game.inventory.get_count("grass") == saved_grass, "草数量恢复")
	_check(game.inventory.get_count("stone") == saved_stone, "石头数量恢复")
	_check(tree != null and tree.uses_left == saved_tree_uses, "资源剩余次数恢复",
		"%s -> %s" % [str(saved_tree_uses), str(tree.uses_left if tree else -1)])
	var restored_crate: VisualSamplePlaceable = null
	for object in game.placed_objects:
		if str(object.def.get("id", "")) == "crate":
			restored_crate = object
			break
	_check(restored_crate != null and restored_crate.origin == saved_crate_origin,
		"物件位置恢复", str(restored_crate.origin if restored_crate else Vector2i(-1, -1)))
	var restored_rotated: VisualSamplePlaceable = null
	for object in game.placed_objects:
		if object.origin == rotated_origin and str(object.def.get("id", "")) == "table":
			restored_rotated = object
			break
	_check(restored_rotated != null and restored_rotated.rotation_quarters == 1
		and restored_rotated.size == Vector2i(1, 2),
		"旋转方向存档恢复")
	_check(game.grid.world_to_cell(game.player.position) == saved_player_cell,
		"角色位置恢复", str(game.grid.world_to_cell(game.player.position)))

	print("\n[6b] 新实例启动恢复")
	var restart_packed := load("res://home_island/HomeIsland.tscn") as PackedScene
	var restarted := restart_packed.instantiate() as HomeIslandGame
	restarted.persistence_enabled = true
	restarted.save_path = TEST_SAVE
	add_child(restarted)
	await _frames(8)
	_check(restarted.inventory.get_count("wood") == saved_wood, "重启后木材恢复",
		str(restarted.inventory.get_count("wood")))
	_check(restarted.grid.world_to_cell(restarted.player.position) == saved_player_cell,
		"重启后角色位置恢复",
		str(restarted.grid.world_to_cell(restarted.player.position)))
	var restarted_crate: VisualSamplePlaceable = null
	for object in restarted.placed_objects:
		if str(object.def.get("id", "")) == "crate":
			restarted_crate = object
			break
	_check(restarted_crate != null and restarted_crate.origin == saved_crate_origin,
		"重启后物件位置恢复",
		str(restarted_crate.origin if restarted_crate else Vector2i(-1, -1)))
	var restarted_tree: VisualSampleResource = null
	for node in restarted.resource_nodes:
		if node.node_id == (tree.node_id if tree else ""):
			restarted_tree = node
			break
	_check(restarted_tree != null and restarted_tree.uses_left == saved_tree_uses,
		"重启后资源剩余次数恢复",
		str(restarted_tree.uses_left if restarted_tree else -1))
	restarted.queue_free()
	await _frames(2)

	print("\n[6c] 存档异常防护")
	var empty_path := "user://home_island_empty.json"
	_write_text(empty_path, "")
	_check(not game.load_game(empty_path), "空存档安全拒绝")
	var broken_path := "user://home_island_broken.json"
	_write_text(broken_path, "{ not valid json")
	_check(not game.load_game(broken_path), "格式错误 JSON 安全拒绝")
	var wrong_types_path := "user://home_island_wrong_types.json"
	_write_text(wrong_types_path, JSON.stringify({
		"version": 1, "map": "home_island_v1", "inventory": {},
		"resources": [], "objects": "not-an-array", "player": {}
	}))
	_check(not game.load_game(wrong_types_path), "错误顶层类型安全拒绝")
	var weird_path := "user://home_island_weird.json"
	_write_text(weird_path, JSON.stringify({
		"version": 1, "map": "home_island_v1", "inventory": {},
		"resources": [],
		"objects": [
			{"id": "unknown_object", "origin": [0, 0]},
			{"id": "table", "origin": [9999, 9999]}
		],
		"player": {"position": [9999, 9999]}
	}))
	_check(game.load_game(weird_path), "未知物件/非法坐标存档可安全加载")
	_check(game.player.can_stand(game.player.position), "非法角色坐标回退到可站立点")
	_check(game.placed_objects.is_empty(), "未知物件和非法坐标物件被跳过")
	for p in [empty_path, broken_path, wrong_types_path, weird_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

	print("\n[7] 旧样板测试兼容基础")
	_check(game.grid.columns == 24 and game.grid.rows == 20,
		"家园岛使用独立 24×20 配置")
	_check(game.config.get("map", {}).get("columns", 0) == 24,
		"配置来自 home_island_config.json")
	_check(game.asset_catalog.get("rabbit", {}).get("animations", {}).has("walk_down"),
		"复用冻结的兔子动画资源")


func _reachable_cells(start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var next: Vector2i = cell + d
			if seen.has(next) or not game.grid.is_walkable_cell(next):
				continue
			seen[next] = true
			queue.append(next)
	return seen


func _write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)


func _resource_by_type(type_id: String) -> VisualSampleResource:
	for node in game.resource_nodes:
		if node.node_type == type_id and not node.is_depleted():
			return node
	return null


func _move_next_to(node) -> void:
	var directions := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
	for d in directions:
		var cell: Vector2i = node.cell + d
		if game.grid.is_walkable_cell(cell):
			game.player.position = game.grid.cell_to_world(cell)
			return
	game.player.position = game.grid.cell_to_world(node.cell)


func _find_empty(size: Vector2i) -> Vector2i:
	var center := Vector2(7.5, 6.0)
	var best := Vector2i(-1, -1)
	var best_distance := 99999.0
	var player_cell := game.grid.world_to_cell(game.player.position)
	for y in range(0, game.grid.rows - size.y + 1):
		for x in range(0, game.grid.columns - size.x + 1):
			var origin := Vector2i(x, y)
			if not game.grid.can_place(origin, size):
				continue
			var footprint := game.grid.footprint_cells(origin, size)
			if player_cell in footprint:
				continue
			var distance := Vector2(x, y).distance_squared_to(center)
			if distance < best_distance:
				best_distance = distance
				best = origin
	return best


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
