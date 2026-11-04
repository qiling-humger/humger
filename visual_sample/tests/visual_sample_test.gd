extends Node
## 8×8 视觉样板自动验收：Sprite 帧、隐藏网格、移动、采集、建造、搬动。

var game: VisualSampleGame
var checks := 0
var failures := 0


func _ready() -> void:
	print("\n========== 视觉样板验收开始 ==========")
	var packed := load("res://visual_sample/VisualSample.tscn") as PackedScene
	game = packed.instantiate() as VisualSampleGame
	add_child(game)
	await _frames(10)
	await _run_tests()
	print("\n========== 视觉样板验收结束：%d 项检查，%d 项失败 ==========" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _run_tests() -> void:
	print("\n[1] 场景 / 资源 / 隐藏网格")
	_check(game != null, "VisualSample 实例化成功")
	_check(game.grid.columns == 8 and game.grid.rows == 8, "样板网格为 8×8",
		"%d×%d" % [game.grid.columns, game.grid.rows])
	_check(game.grid.get_land_count() > 20, "样板有足够陆地",
		str(game.grid.get_land_count()))
	_check(game.terrain.land_tile_count == game.grid.get_land_count(),
		"每块陆地都有独立地块 Sprite", str(game.terrain.land_tile_count))
	_check(not game.terrain.is_grid_visible(), "普通状态网格完全隐藏")
	_check(game.resource_nodes.size() == 4, "资源节点数量正确",
		str(game.resource_nodes.size()))
	_check(game.placed_objects.size() == 3, "初始家具数量正确",
		str(game.placed_objects.size()))
	var table_count := 0
	for object in game.placed_objects:
		if object.size == Vector2i(2, 1):
			table_count += 1
	_check(table_count == 1, "初始 2×1 桌子存在")

	print("\n[2] 完整角色 Sprite / 独立动画帧")
	var sprite: AnimatedSprite2D = game.player.get_node("AnimatedSprite2D")
	_check(sprite != null and sprite.sprite_frames != null, "兔子使用 AnimatedSprite2D")
	var frames := sprite.sprite_frames
	_check(frames.has_animation("idle_down") and frames.has_animation("walk_down")
		and frames.has_animation("idle_side") and frames.has_animation("walk_side")
		and frames.has_animation("idle_up") and frames.has_animation("walk_up"),
		"兔子有六个方向/状态动画")
	_check(frames.get_frame_count("walk_down") == 4, "下行走路有 4 个独立帧",
		str(frames.get_frame_count("walk_down")))
	_check(frames.get_frame_count("idle_down") == 2, "下行待机有 2 个独立帧",
		str(frames.get_frame_count("idle_down")))
	_check(sprite.scale.x < 1.0 and sprite.scale.x > 0.4, "角色缩放到样板比例",
		str(sprite.scale))
	_check(frames.get_frame_texture(sprite.animation, sprite.frame) != null,
		"动画帧纹理已加载")

	print("\n[3] 移动 / 碰撞 / 镜头")
	var before := game.player.position
	Input.action_press("move_right")
	await _frames(16)
	var moving_animation := sprite.animation
	Input.action_release("move_right")
	await _frames(3)
	_check(game.player.position.x > before.x + 3.0, "WASD 移动有效",
		"%.1f -> %.1f" % [before.x, game.player.position.x])
	_check(moving_animation.begins_with("walk_"), "移动时切换到走路动画",
		moving_animation)
	_check(sprite.animation.begins_with("idle_"), "停下后切换到待机动画",
		sprite.animation)
	_check(game.player.get_node("Camera2D").enabled, "镜头启用")
	_check(not game.player.can_stand(game.grid.cell_to_world(Vector2i(0, 0))),
		"玩家不能进入海水")
	var tree := _resource_by_type("tree")
	_check(tree != null, "存在树木节点")
	if tree:
		_check(not game.player.can_stand(game.grid.cell_to_world(tree.cell)),
			"玩家不能穿过树干")

	print("\n[4] E 采集 / 资源栏")
	if tree:
		game.player.position = game.grid.cell_to_world(Vector2i(1, 5))
		await _frames(3)
		game._refresh_nearest()
		_check(game.nearest_resource == tree, "靠近树自动选中")
		var ok := game.gather_nearest()
		_check(ok and game.inventory.get_count("wood") == 2, "采集获取木材",
			str(game.inventory.get_count("wood")))
		game.gather_nearest()
		game.gather_nearest()
		_check(tree.is_depleted(), "树采集 3 次后耗尽")
		_check(game.inventory.get_count("wood") == 6, "木材累计 6",
			str(game.inventory.get_count("wood")))
		var visual := tree.get("_sprite") as Sprite2D
		_check(visual != null and visual.texture != null
			and str(visual.texture.resource_path).contains("stump"),
			"树耗尽后切换为树桩 Sprite")

	print("\n[5] B 建造 / 半透明预览 / 放置")
	var b_event := InputEventKey.new()
	b_event.keycode = KEY_B
	b_event.physical_keycode = KEY_B
	b_event.pressed = true
	Input.parse_input_event(b_event)
	await _frames(4)
	_check(game.placement.build_mode, "真实 B 键进入建造模式")
	_check(game.terrain.is_grid_visible(), "建造模式显示网格")
	game.select_buildable(1)
	var target := _find_empty(Vector2i(2, 1))
	_check(target.x >= 0, "找到 2×1 放置位置", str(target))
	var world_center := game.grid.world_from_float(Vector2(target.x + 0.5, target.y))
	game.placement.update_preview(world_center)
	await _frames(2)
	var ghost := game.placement.get("_ghost") as Sprite2D
	_check(ghost != null and ghost.visible and ghost.texture != null,
		"放置前显示半透明 Sprite 预览")
	var count_before := game.placed_objects.size()
	_check(game.placement.try_place_at(world_center), "2×1 鼠标放置逻辑成功")
	_check(game.placed_objects.size() == count_before + 1, "场景中新增 2×1 物件")
	_check(not game.grid.can_place(target, Vector2i(2, 1)), "放置后占格锁定")
	_check(not game.placement.try_place_at(game.grid.cell_to_world(Vector2i(0, 0))),
		"水面放置被拒绝")
	game.exit_build_mode()
	await _frames(2)
	_check(not game.placement.build_mode and not game.terrain.is_grid_visible(),
		"退出建造后网格重新隐藏")

	print("\n[6] 搬动 / 回滚")
	var crate: VisualSamplePlaceable = null
	for object in game.placed_objects:
		if str(object.def.get("id", "")) == "crate":
			crate = object
			break
	_check(crate != null, "找到木箱")
	if crate:
		var old_origin := crate.origin
		var new_origin := _find_empty(Vector2i(1, 1))
		_check(game.placement.begin_drag(game.grid.cell_to_world(old_origin)),
			"鼠标式搬动开始")
		game.placement.update_drag(game.grid.cell_to_world(new_origin))
		_check(game.placement.preview_valid, "合法新位置预览为绿色")
		game.placement.finish_drag(game.grid.cell_to_world(new_origin))
		_check(crate.origin == new_origin, "木箱搬到新格", str(crate.origin))
		# 非法水面回滚
		var before_bad := crate.origin
		game.placement.begin_drag(game.grid.cell_to_world(before_bad))
		game.placement.finish_drag(game.grid.cell_to_world(Vector2i(0, 0)))
		_check(crate.origin == before_bad, "非法搬动回滚", str(crate.origin))
	_check(game.inventory.get_count("wood") == 6, "资源统计保持")


func _resource_by_type(type_id: String) -> VisualSampleResource:
	for node in game.resource_nodes:
		if node.node_type == type_id:
			return node
	return null


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
