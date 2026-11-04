class_name RabbitPlayer
extends Node2D
## 小白兔玩家：屏幕方向移动、逻辑格碰撞、镜头平滑跟随。
## 脚底位置 = Node2D.position，因此可以直接参与 Y 排序。

@onready var camera: Camera2D = $Camera2D

var grid: IslandGrid
var move_speed := 215.0
var input_enabled := true
var body_radius := 11.0

var _facing := 1.0
var _walk_phase := 0.0
var _moving := false
var _blink := 0.0
var _time := 0.0


func setup(grid_ref: IslandGrid, spawn_cell: Vector2i) -> void:
	grid = grid_ref
	position = grid.cell_to_world(spawn_cell)
	_setup_camera()
	queue_redraw()


func _setup_camera() -> void:
	if camera == null:
		return
	camera.enabled = true
	camera.zoom = Vector2(1.15, 1.15)
	camera.position = Vector2(0, -24)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_smoothed = true
	var bounds := grid.get_world_bounds()
	var margin := 180.0
	camera.limit_left = int(bounds.position.x - margin)
	camera.limit_top = int(bounds.position.y - margin)
	camera.limit_right = int(bounds.end.x + margin)
	camera.limit_bottom = int(bounds.end.y + margin)
	camera.reset_smoothing()


func _process(delta: float) -> void:
	_time += delta
	if _blink > 0.0:
		_blink -= delta
	var input := Vector2.ZERO
	if input_enabled:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length() > 0.08:
		_moving = true
		_walk_phase += delta * 9.0
		if absf(input.x) > 0.05:
			_facing = signf(input.x)
		var motion := input.normalized() * move_speed * delta
		_try_move(Vector2(motion.x, 0.0))
		_try_move(Vector2(0.0, motion.y))
	else:
		_moving = false
		_walk_phase = lerpf(_walk_phase, 0.0, minf(1.0, delta * 8.0))
	queue_redraw()


func _try_move(motion: Vector2) -> void:
	if motion.length_squared() < 0.0001:
		return
	var candidate := position + motion
	if can_stand(candidate):
		position = candidate


func can_stand(world_point: Vector2) -> bool:
	if grid == null:
		return false
	var samples := [
		Vector2.ZERO,
		Vector2(body_radius, 0),
		Vector2(-body_radius, 0),
		Vector2(0, body_radius * 0.72),
		Vector2(0, -body_radius * 0.72),
	]
	for offset in samples:
		if not grid.is_walkable_at(world_point + offset):
			return false
	return true


func interaction_origin() -> Vector2:
	return position + Vector2(0, -18)


func _draw() -> void:
	var bob := sin(_walk_phase * 2.0) * (2.0 if _moving else 0.0)
	Painter.shadow(self, Vector2(0, 2), 17, 6, Color(0.18, 0.27, 0.20, 0.20))

	# 脚和腿
	var step := sin(_walk_phase) * 4.0 if _moving else 0.0
	_draw_foot(Vector2(-9 + step * 0.5, -3), -1)
	_draw_foot(Vector2(9 - step * 0.5, -3), 1)

	# 身体
	var body_center := Vector2(0, -28 + bob)
	Painter.circle_outline(self, body_center, 19.0, Painter.CREAM, Painter.INK, 2.2)
	draw_circle(body_center + Vector2(-7, -5), 5.0, Color(1, 1, 1, 0.55))
	# 围裙/小背包带子
	draw_arc(body_center + Vector2(0, 2), 14.0, PI * 0.12, PI * 0.88, 12,
		Color(0.35, 0.55, 0.43, 0.55), 2.0, true)
	draw_circle(body_center + Vector2(0, 9), 3.0, Painter.CORAL)

	# 头
	var head_center := Vector2(_facing * 2.0, -60 + bob)
	_draw_ears(head_center)
	Painter.circle_outline(self, head_center, 23.0, Color(0.996, 0.980, 0.933), Painter.INK, 2.4)
	# 脸颊和眼睛
	draw_circle(head_center + Vector2(-8 + _facing * 3, -2), 6.2, Color(1, 1, 1, 0.58))
	draw_circle(head_center + Vector2(8 + _facing * 3, -2), 6.2, Color(1, 1, 1, 0.58))
	var eye_open := 2.5 if _blink <= 0.0 else 0.8
	draw_circle(head_center + Vector2(-7 + _facing * 4, -1), eye_open, Painter.INK)
	draw_circle(head_center + Vector2(7 + _facing * 4, -1), eye_open, Painter.INK)
	if _blink <= 0.0:
		draw_circle(head_center + Vector2(-6 + _facing * 4, -2), 0.8, Color(1, 1, 1, 0.9))
		draw_circle(head_center + Vector2(8 + _facing * 4, -2), 0.8, Color(1, 1, 1, 0.9))
	# 粉鼻子、嘴和腮红
	draw_circle(head_center + Vector2(_facing * 4, 8), 2.4, Color(0.902, 0.565, 0.552))
	draw_arc(head_center + Vector2(_facing * 4, 10), 4.0, PI * 0.15, PI * 0.85, 8,
		Painter.INK_SOFT, 1.2, true)
	draw_circle(head_center + Vector2(-13, 8), 3.6, Color(0.949, 0.678, 0.655, 0.55))
	draw_circle(head_center + Vector2(13, 8), 3.6, Color(0.949, 0.678, 0.655, 0.55))
	# 围巾
	draw_arc(Vector2(0, -40 + bob), 16.0, PI * 0.08, PI * 0.92, 16,
		Color(0.365, 0.659, 0.557), 5.0, true)
	draw_circle(Vector2(_facing * 11, -37 + bob), 3.2, Painter.MINT)


func _draw_ears(head_center: Vector2) -> void:
	var left_base := head_center + Vector2(-10, -18)
	var right_base := head_center + Vector2(10, -18)
	var sway := sin(_time * 2.2) * 1.5
	var left_tip := Vector2(-19 + _facing * 3, -103 + sway)
	var right_tip := Vector2(20 + _facing * 3, -111 - sway)
	_draw_ear(left_base, left_tip)
	_draw_ear(right_base, right_tip)


func _draw_ear(base: Vector2, tip: Vector2) -> void:
	var direction := (tip - base).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		base + normal * 9.0,
		base - normal * 8.0,
		tip - normal * 3.0,
		tip + normal * 3.0,
	])
	Painter.outline_polygon(self, points, Color(0.996, 0.980, 0.933), Painter.INK, 2.2)
	var inner_points := PackedVector2Array([
		base + normal * 4.0 + direction * 7.0,
		base - normal * 3.0 + direction * 7.0,
		tip - normal * 1.2,
		tip + normal * 1.2,
	])
	draw_colored_polygon(inner_points, Color(0.949, 0.729, 0.702, 0.8))


func _draw_foot(center: Vector2, side: int) -> void:
	draw_circle(center, 7.0, Color(0.996, 0.980, 0.933))
	draw_arc(center, 7.0, 0, TAU, 20, Painter.INK, 1.8, true)
	draw_line(center + Vector2(side * 1.5, 1), center + Vector2(side * 5.5, 1),
		Color(0.949, 0.678, 0.655), 1.2, true)
