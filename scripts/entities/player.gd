class_name Player
extends Node2D
## 玩家控制与外观。
## 45° 斜俯视下 WASD 直接对应屏幕上下左右，角色朝向跟随输入，
## 地面用菱形边界限制，设备用屏幕空间矩形阻挡，避免“按键方向和画面方向打架”。

signal inventory_changed(item: Dictionary)

const FLOOR_CENTER := Vector2(640, 385)
const FLOOR_HALF := Vector2(560, 265)
const WALK_BOUNDS_MARGIN := 0.925

var manager: Node
var input_enabled := false
var move_speed := 235.0
var body_radius := 18.0
var inventory: Dictionary = {}
var spawn_position := Vector2(620, 535)

var _facing := Vector2.DOWN
var _facing_sign := 1.0
var _walk_phase := 0.0
var _anim := 0.0
var _moving := false
var _obstacles: Array[Rect2] = []
var _blink_phase := 0.7


func setup(manager_node: Node, start_position: Vector2, obstacles: Array[Rect2]) -> void:
	manager = manager_node
	spawn_position = start_position
	_obstacles = obstacles.duplicate()
	position = spawn_position
	_blink_phase = randf_range(0.0, 3.0)
	queue_redraw()


func set_obstacles(obstacles: Array[Rect2]) -> void:
	_obstacles = obstacles.duplicate()


func reset_player() -> void:
	position = spawn_position
	inventory = {}
	inventory_changed.emit({})
	_facing = Vector2.DOWN
	_facing_sign = 1.0
	queue_redraw()


func set_input_enabled(value: bool) -> void:
	input_enabled = value
	if not value:
		_moving = false


func _physics_process(delta: float) -> void:
	_anim += delta
	if not input_enabled:
		_moving = false
		queue_redraw()
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length() < 0.08:
		_moving = false
		queue_redraw()
		return
	_moving = true
	var direction := input.normalized()
	_facing = direction
	if absf(direction.x) > 0.05:
		_facing_sign = signf(direction.x)
	_walk_phase += delta * 10.5
	var step := direction * move_speed * delta
	_move_with_collision(step)
	queue_redraw()


func _move_with_collision(step: Vector2) -> void:
	var next_x := position + Vector2(step.x, 0)
	if _can_stand(next_x):
		position = next_x
	var next_y := position + Vector2(0, step.y)
	if _can_stand(next_y):
		position = next_y


func _can_stand(point: Vector2) -> bool:
	var normalized := (point - FLOOR_CENTER).abs()
	if normalized.x / FLOOR_HALF.x + normalized.y / FLOOR_HALF.y > WALK_BOUNDS_MARGIN:
		return false
	for rect in _obstacles:
		if rect.has_point(point):
			return false
	return true


func set_item(item: Dictionary) -> void:
	inventory = item.duplicate(true)
	inventory_changed.emit(inventory.duplicate(true))
	queue_redraw()


func clear_item() -> void:
	inventory = {}
	inventory_changed.emit({})
	queue_redraw()


func get_item() -> Dictionary:
	return inventory.duplicate(true)


func has_item() -> bool:
	return not inventory.is_empty()


func item_type() -> String:
	return str(inventory.get("type", ""))


func hand_position() -> Vector2:
	return global_position + Vector2(30.0 * _facing_sign, -48)


func _draw() -> void:
	var bob := 0.0
	if _moving:
		bob = -absf(sin(_walk_phase)) * 2.2
	else:
		bob = sin(_anim * 2.2) * 0.8
	var foot_swing := sin(_walk_phase) * 4.0 if _moving else 0.0
	_draw_shadow()
	_draw_dust(foot_swing)
	_draw_legs(foot_swing, bob)
	_draw_body(bob)
	_draw_held_item(bob)
	_draw_head(bob)
	_draw_hat(bob)


func _draw_shadow() -> void:
	Painter.shadow(self, Vector2(0, 1), 30, 10, Color(0.23, 0.16, 0.12, 0.20))
	# 脚边小高光，让角色从地面上“立”起来。
	draw_arc(Vector2(0, 1), 25, 0.15, PI - 0.15, 20, Color(1, 1, 1, 0.18), 2.0, true)


func _draw_dust(foot_swing: float) -> void:
	if not _moving:
		return
	var alpha := 0.12 + absf(sin(_walk_phase * 0.5)) * 0.10
	draw_circle(Vector2(-24, 2), 5.0 + absf(foot_swing) * 0.3, Color(0.61, 0.46, 0.34, alpha))
	draw_circle(Vector2(22, 4), 4.0, Color(0.61, 0.46, 0.34, alpha * 0.8))


func _draw_legs(foot_swing: float, bob: float) -> void:
	var left_y := -18.0 + bob
	var right_y := -18.0 + bob
	Painter.line(self, Vector2(-9, left_y), Vector2(-11 + foot_swing, -3), Color(0.93, 0.66, 0.58), 8.0, true)
	Painter.line(self, Vector2(9, right_y), Vector2(11 - foot_swing, -3), Color(0.93, 0.66, 0.58), 8.0, true)
	# 小鞋子
	draw_colored_polygon(Painter.ellipse_points(Vector2(-12 + foot_swing, -2), 9, 5), Painter.BROWN_DARK)
	draw_polyline(_closed(Painter.ellipse_points(Vector2(-12 + foot_swing, -2), 9, 5)), Painter.INK, 1.8, true)
	draw_colored_polygon(Painter.ellipse_points(Vector2(12 - foot_swing, -2), 9, 5), Painter.BROWN_DARK)
	draw_polyline(_closed(Painter.ellipse_points(Vector2(12 - foot_swing, -2), 9, 5)), Painter.INK, 1.8, true)


func _draw_body(bob: float) -> void:
	# 身体：奶油色厨师服 + 薄荷绿围裙
	Painter.panel(self, Rect2(-21, -62 + bob, 42, 46), 15, Painter.CREAM, Painter.INK, 2.4, false)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -48 + bob), Vector2(16, -48 + bob), Vector2(12, -19 + bob), Vector2(-12, -19 + bob)
	]), Painter.MINT)
	draw_polyline(PackedVector2Array([
		Vector2(-16, -48 + bob), Vector2(16, -48 + bob), Vector2(12, -19 + bob), Vector2(-12, -19 + bob),
		Vector2(-16, -48 + bob)
	]), Painter.INK, 2.0, true)
	# 围裙口袋
	Painter.panel(self, Rect2(-7, -36 + bob, 14, 9), 4, Painter.MINT_LIGHT, Painter.INK_SOFT, 1.4, false)
	# 领巾
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, -64 + bob), Vector2(9, -64 + bob), Vector2(4, -53 + bob), Vector2(-4, -53 + bob)
	]), Painter.CORAL)
	draw_polyline(PackedVector2Array([
		Vector2(-9, -64 + bob), Vector2(9, -64 + bob), Vector2(4, -53 + bob), Vector2(-4, -53 + bob),
		Vector2(-9, -64 + bob)
	]), Painter.INK, 1.8, true)
	# 手臂，随走路摆动
	var swing := sin(_walk_phase) * 4.0 if _moving else 0.0
	Painter.capsule(self, Vector2(-19, -55 + bob), Vector2(-27, -38 + bob + swing), Color(0.95, 0.70, 0.61), 9.0)
	Painter.capsule(self, Vector2(19, -55 + bob), Vector2(27, -38 + bob - swing), Color(0.95, 0.70, 0.61), 9.0)
	draw_circle(Vector2(-27, -37 + bob + swing), 5.2, Color(0.96, 0.74, 0.64))
	draw_arc(Vector2(-27, -37 + bob + swing), 5.2, 0.0, TAU, 16, Painter.INK, 1.6, true)
	draw_circle(Vector2(27, -37 + bob - swing), 5.2, Color(0.96, 0.74, 0.64))
	draw_arc(Vector2(27, -37 + bob - swing), 5.2, 0.0, TAU, 16, Painter.INK, 1.6, true)


func _draw_held_item(bob: float) -> void:
	if inventory.is_empty():
		return
	var x := 31.0 * _facing_sign
	var center := Vector2(x, -45 + bob + sin(_anim * 4.0) * 1.2)
	Painter.draw_item_icon(self, inventory, center, 0.9)
	# 握住的小手
	draw_circle(center + Vector2(-7 * _facing_sign, 9), 5.0, Color(0.96, 0.74, 0.64))
	draw_arc(center + Vector2(-7 * _facing_sign, 9), 5.0, 0.0, TAU, 16, Painter.INK, 1.6, true)


func _draw_head(bob: float) -> void:
	var center := Vector2(0, -83 + bob)
	# 猪耳朵
	for side in [-1.0, 1.0]:
		var points := PackedVector2Array([
			Vector2(side * 14, -104 + bob),
			Vector2(side * 30, -119 + bob),
			Vector2(side * 31, -99 + bob),
		])
		draw_colored_polygon(points, Color(0.95, 0.69, 0.62))
		draw_polyline(_closed(points), Painter.INK, 2.1, true)
		var inner := PackedVector2Array([
			Vector2(side * 19, -105 + bob),
			Vector2(side * 27, -112 + bob),
			Vector2(side * 27, -103 + bob),
		])
		draw_colored_polygon(inner, Color(0.93, 0.57, 0.56))
	# 头
	draw_circle(center, 29, Color(0.97, 0.74, 0.65))
	draw_arc(center, 29, 0.0, TAU, 38, Painter.INK, 2.4, true)
	# 腮红
	draw_circle(center + Vector2(-20, 8), 5.2, Color(0.94, 0.49, 0.50, 0.28))
	draw_circle(center + Vector2(20, 8), 5.2, Color(0.94, 0.49, 0.50, 0.28))
	# 猪鼻
	draw_colored_polygon(Painter.ellipse_points(center + Vector2(0, 9), 11, 7.5), Color(0.95, 0.64, 0.61))
	draw_polyline(_closed(Painter.ellipse_points(center + Vector2(0, 9), 11, 7.5)), Painter.INK, 1.8, true)
	draw_circle(center + Vector2(-4, 9), 1.7, Painter.BROWN_DARK)
	draw_circle(center + Vector2(4, 9), 1.7, Painter.BROWN_DARK)
	# 眼睛看向移动方向
	var eye_offset := Vector2(clampf(_facing.x, -1.0, 1.0) * 2.2, clampf(_facing.y, -1.0, 1.0) * 1.1)
	var blink := fmod(_anim + _blink_phase, 4.1) > 3.96
	for side in [-1.0, 1.0]:
		var eye := center + Vector2(side * 10, -3) + eye_offset
		if blink:
			draw_line(eye + Vector2(-3, 0), eye + Vector2(3, 0), Painter.INK, 2.0, true)
		else:
			draw_circle(eye, 3.2, Painter.INK)
			draw_circle(eye + Vector2(-1, -1), 1.0, Color.WHITE)
	# 微笑
	draw_arc(center + Vector2(0, 2), 6.0, 0.22, PI - 0.22, 14, Painter.INK, 1.8, true)
	# 小虎牙
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(3, 6), center + Vector2(6, 6), center + Vector2(4.5, 9)
	]), Color(1, 1, 1))


func _draw_hat(bob: float) -> void:
	# 厨师帽：蓬松的白色云朵 + 薄荷色帽带
	var y := -113 + bob
	Painter.panel(self, Rect2(-20, y + 6, 40, 13), 6, Painter.MINT_LIGHT, Painter.INK, 2.0, false)
	draw_circle(Vector2(-13, y - 2), 14, Painter.WHITE)
	draw_circle(Vector2(13, y - 2), 14, Painter.WHITE)
	draw_circle(Vector2(0, y - 12), 18, Painter.WHITE)
	draw_circle(Vector2(-25, y + 1), 9, Painter.WHITE)
	draw_circle(Vector2(25, y + 1), 9, Painter.WHITE)
	# 帽子的轮廓（只描外沿，内部保持云朵感）
	draw_arc(Vector2(-13, y - 2), 14, PI * 0.9, PI * 2.1, 16, Painter.INK, 2.0, true)
	draw_arc(Vector2(13, y - 2), 14, PI * 0.9, PI * 2.1, 16, Painter.INK, 2.0, true)
	draw_arc(Vector2(0, y - 12), 18, PI * 0.9, PI * 2.1, 20, Painter.INK, 2.0, true)
	draw_line(Vector2(-20, y + 6), Vector2(20, y + 6), Painter.INK, 2.0, true)
	draw_line(Vector2(-20, y + 19), Vector2(20, y + 19), Painter.INK, 2.0, true)
	draw_line(Vector2(-20, y + 6), Vector2(-20, y + 19), Painter.INK, 2.0, true)
	draw_line(Vector2(20, y + 6), Vector2(20, y + 19), Painter.INK, 2.0, true)
	draw_line(Vector2(-9, y + 16), Vector2(8, y + 16), Color(1, 1, 1, 0.65), 2.0, true)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
