class_name Customer
extends Node2D
## 顾客：随机动物外观、订单气泡、耐心倒计时和离场表现。

signal timed_out(customer: Customer)

const BUBBLE_FRONT := Rect2(-68, -198, 136, 58)
const BUBBLE_BACK := Rect2(-42, -176, 84, 30)

var profile: Dictionary = {}
var order: Dictionary = {}
var queue_ref: Node
var patience_max := 80.0
var patience_left := 80.0
var status := "waiting"
var is_front := false
var arriving := true
var reward_given := 0

var _anim := 0.0
var _move_tween: Tween
var _leaving := false
var _blink_phase := 0.0


func setup(customer_profile: Dictionary, customer_order: Dictionary, queue: Node, patience: float) -> void:
	profile = customer_profile.duplicate(true)
	order = customer_order.duplicate(true)
	queue_ref = queue
	patience_max = maxf(1.0, patience)
	patience_left = patience_max
	_blink_phase = randf_range(0.0, 2.6)
	queue_redraw()


func _process(delta: float) -> void:
	_anim += delta
	if status == "waiting" and not arriving:
		patience_left -= delta
		if patience_left <= 0.0:
			patience_left = 0.0
			status = "timed_out"
			timed_out.emit(self)
	queue_redraw()


func set_front(value: bool) -> void:
	if is_front != value:
		is_front = value
		queue_redraw()


func enter_slot(target: Vector2) -> void:
	position = Vector2(640, 694)
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)
	_move_tween = create_tween()
	_move_tween.set_parallel(true)
	_move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "position", target, 1.05)
	_move_tween.tween_property(self, "modulate:a", 1.0, 0.45)
	_move_tween.tween_property(self, "scale", Vector2.ONE, 0.55)
	_move_tween.set_parallel(false)
	_move_tween.tween_callback(_finish_arrival)


func move_to_slot(target: Vector2) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	arriving = true
	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "position", target, 0.42)
	_move_tween.tween_callback(_finish_arrival)


func _finish_arrival() -> void:
	arriving = false
	queue_redraw()


func play_served(reward: int) -> void:
	status = "happy"
	reward_given = reward
	arriving = false
	set_process(true)
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	queue_redraw()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.18)
	tween.tween_property(self, "position:y", position.y - 12.0, 0.7)
	tween.set_parallel(false)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18)
	tween.tween_interval(0.55)
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_property(self, "position:y", position.y - 46.0, 0.35)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func play_timeout() -> void:
	_leave_angry("等太久了！", Color(0.82, 0.25, 0.22))


func play_rejected() -> void:
	_leave_angry("不是这个…", Color(0.82, 0.25, 0.22))


func _leave_angry(_message: String, _color: Color) -> void:
	status = "angry"
	arriving = false
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	queue_redraw()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", position + Vector2(250, -70), 1.2)
	tween.tween_property(self, "modulate:a", 0.0, 1.2)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func patience_ratio() -> float:
	return clampf(patience_left / patience_max, 0.0, 1.0)


func _draw() -> void:
	var fur := GameData.color(str(profile.get("fur", "#F4C98F")), Color(0.956, 0.788, 0.561))
	var accent := GameData.color(str(profile.get("accent", "#D89462")), Color(0.545, 0.369, 0.275))
	var shirt := GameData.color(str(profile.get("shirt", "#9DD8C0")), Color(0.620, 0.851, 0.753))
	_draw_shadow_and_tail(fur, accent)
	_draw_body(fur, accent, shirt)
	_draw_head(fur, accent, shirt)
	if status == "waiting":
		if is_front:
			_draw_order_bubble()
		_draw_patience()
	elif status == "happy":
		_draw_happy()
	elif status == "angry":
		_draw_angry()


func _draw_shadow_and_tail(fur: Color, accent: Color) -> void:
	Painter.shadow(self, Vector2(0, 2), 27, 9, Color(0.23, 0.16, 0.12, 0.18))
	if str(profile.get("species", "")) in ["cat", "dog"]:
		var tail_points := PackedVector2Array()
		for i in range(7):
			var t := float(i) / 6.0
			tail_points.append(Vector2(20 + 20 * t, -24 - 20 * t + sin(t * PI) * 8.0))
		draw_polyline(tail_points, Painter.INK, 10.0, true)
		draw_polyline(tail_points, fur, 7.0, true)
		draw_circle(tail_points[tail_points.size() - 1], 5.0, accent)


func _draw_body(fur: Color, accent: Color, shirt: Color) -> void:
	var bob := sin(_anim * 2.0) * 0.8
	# 腿与鞋
	draw_line(Vector2(-9, -22 + bob), Vector2(-10, -4), Painter.INK, 9.0, true)
	draw_line(Vector2(-9, -22 + bob), Vector2(-10, -4), fur, 6.0, true)
	draw_line(Vector2(9, -22 + bob), Vector2(10, -4), Painter.INK, 9.0, true)
	draw_line(Vector2(9, -22 + bob), Vector2(10, -4), fur, 6.0, true)
	draw_circle(Vector2(-10, -3), 7.5, Painter.BROWN_DARK)
	draw_circle(Vector2(10, -3), 7.5, Painter.BROWN_DARK)
	# 身体
	Painter.panel(self, Rect2(-19, -60 + bob, 38, 42), 14, shirt, Painter.INK, 2.2, false)
	# 围裙/领口
	draw_line(Vector2(-14, -53 + bob), Vector2(14, -53 + bob), Color(1, 1, 1, 0.55), 2.0, true)
	draw_circle(Vector2(0, -53 + bob), 2.8, accent)
	# 手臂
	draw_line(Vector2(-19, -52 + bob), Vector2(-27, -30 + bob), Painter.INK, 9.0, true)
	draw_line(Vector2(-19, -52 + bob), Vector2(-27, -30 + bob), fur, 6.0, true)
	draw_circle(Vector2(-27, -29 + bob), 4.5, fur)
	draw_line(Vector2(19, -52 + bob), Vector2(26, -32 + bob), Painter.INK, 9.0, true)
	draw_line(Vector2(19, -52 + bob), Vector2(26, -32 + bob), fur, 6.0, true)
	draw_circle(Vector2(26, -31 + bob), 4.5, fur)


func _draw_head(fur: Color, accent: Color, _shirt: Color) -> void:
	var species := str(profile.get("species", "cat"))
	var bob := sin(_anim * 2.0) * 0.8
	var center := Vector2(0, -78 + bob)
	# 后层耳朵
	match species:
		"rabbit":
			_draw_rabbit_ear(Vector2(-12, -104 + bob), -0.16, fur, accent)
			_draw_rabbit_ear(Vector2(12, -104 + bob), 0.16, fur, accent)
		"cat":
			_draw_triangle_ear(Vector2(-19, -96 + bob), -1.0, fur, accent)
			_draw_triangle_ear(Vector2(19, -96 + bob), 1.0, fur, accent)
		"bear", "panda":
			var ear_color := accent if species == "panda" else fur
			draw_circle(Vector2(-20, -98 + bob), 9.5, ear_color)
			draw_arc(Vector2(-20, -98 + bob), 9.5, 0.0, TAU, 22, Painter.INK, 2.0, true)
			draw_circle(Vector2(20, -98 + bob), 9.5, ear_color)
			draw_arc(Vector2(20, -98 + bob), 9.5, 0.0, TAU, 22, Painter.INK, 2.0, true)
		"dog":
			draw_colored_polygon(Painter.ellipse_points(Vector2(-23, -84 + bob), 9, 17), accent)
			draw_polyline(_closed(Painter.ellipse_points(Vector2(-23, -84 + bob), 9, 17)), Painter.INK, 2.0, true)
			draw_colored_polygon(Painter.ellipse_points(Vector2(23, -84 + bob), 9, 17), accent)
			draw_polyline(_closed(Painter.ellipse_points(Vector2(23, -84 + bob), 9, 17)), Painter.INK, 2.0, true)
		"frog":
			draw_circle(Vector2(-11, -99 + bob), 8.5, fur)
			draw_arc(Vector2(-11, -99 + bob), 8.5, 0.0, TAU, 20, Painter.INK, 2.0, true)
			draw_circle(Vector2(11, -99 + bob), 8.5, fur)
			draw_arc(Vector2(11, -99 + bob), 8.5, 0.0, TAU, 20, Painter.INK, 2.0, true)
	# 头
	if species == "frog":
		draw_colored_polygon(Painter.ellipse_points(center, 28, 24), fur)
		draw_polyline(_closed(Painter.ellipse_points(center, 28, 24)), Painter.INK, 2.2, true)
	else:
		draw_circle(center, 25, fur)
		draw_arc(center, 25, 0.0, TAU, 34, Painter.INK, 2.2, true)
	# 面部
	var eye_y := center.y - 2
	if species == "frog":
		draw_circle(Vector2(-11, -99 + bob), 3.2, Painter.INK)
		draw_circle(Vector2(11, -99 + bob), 3.2, Painter.INK)
		draw_arc(Vector2(0, center.y + 3), 12, 0.18, PI - 0.18, 18, Painter.INK, 2.0, true)
		draw_circle(Vector2(-19, center.y + 4), 3.5, Color(0.95, 0.55, 0.55, 0.35))
		draw_circle(Vector2(19, center.y + 4), 3.5, Color(0.95, 0.55, 0.55, 0.35))
	else:
		if species == "panda":
			draw_circle(Vector2(-9, eye_y), 8.5, accent)
			draw_circle(Vector2(9, eye_y), 8.5, accent)
		# 眨眼
		var blink := fmod(_anim + _blink_phase, 3.7) > 3.55
		if blink:
			draw_line(Vector2(-12, eye_y), Vector2(-4, eye_y), Painter.INK, 2.0, true)
			draw_line(Vector2(4, eye_y), Vector2(12, eye_y), Painter.INK, 2.0, true)
		else:
			draw_circle(Vector2(-8, eye_y), 2.8, Painter.INK)
			draw_circle(Vector2(8, eye_y), 2.8, Painter.INK)
			draw_circle(Vector2(-7.1, eye_y - 0.9), 0.85, Color.WHITE)
			draw_circle(Vector2(8.9, eye_y - 0.9), 0.85, Color.WHITE)
		# 口鼻
		if species in ["cat", "dog", "bear", "panda"]:
			draw_circle(Vector2(0, center.y + 10), 6.5, Color(1, 0.96, 0.89, 0.55))
			draw_circle(Vector2(0, center.y + 7), 2.0, accent)
			draw_arc(Vector2(0, center.y + 10), 4.0, 0.2, PI - 0.2, 10, Painter.INK, 1.4, true)
		else:
			draw_arc(Vector2(0, center.y + 7), 5.0, 0.2, PI - 0.2, 10, Painter.INK, 1.6, true)
		# 胡须
		if species == "cat":
			draw_line(Vector2(-27, center.y + 8), Vector2(-14, center.y + 10), Color(0.35, 0.25, 0.2, 0.55), 1.2, true)
			draw_line(Vector2(27, center.y + 8), Vector2(14, center.y + 10), Color(0.35, 0.25, 0.2, 0.55), 1.2, true)
		# 脸红
		draw_circle(Vector2(-17, center.y + 5), 3.8, Color(0.94, 0.49, 0.50, 0.35))
		draw_circle(Vector2(17, center.y + 5), 3.8, Color(0.94, 0.49, 0.50, 0.35))
	# 前层耳朵细节
	if species == "cat":
		_draw_triangle_ear_inner(Vector2(-19, -96 + bob), -1.0, accent)
		_draw_triangle_ear_inner(Vector2(19, -96 + bob), 1.0, accent)


func _draw_triangle_ear(base: Vector2, side: float, fur: Color, _accent: Color) -> void:
	var points := PackedVector2Array([
		base + Vector2(-9 * side, 9), base + Vector2(5 * side, -18), base + Vector2(14 * side, 6)
	])
	draw_colored_polygon(points, fur)
	draw_polyline(_closed(points), Painter.INK, 2.0, true)


func _draw_triangle_ear_inner(base: Vector2, side: float, accent: Color) -> void:
	var points := PackedVector2Array([
		base + Vector2(-2 * side, 4), base + Vector2(5 * side, -11), base + Vector2(8 * side, 2)
	])
	draw_colored_polygon(points, accent)


func _draw_rabbit_ear(base: Vector2, tilt: float, fur: Color, accent: Color) -> void:
	draw_set_transform(base, tilt, Vector2.ONE)
	Painter.panel(self, Rect2(-7, -34, 14, 41), 7, fur, Painter.INK, 2.0, false)
	Painter.panel(self, Rect2(-3, -29, 6, 30), 3, accent, Color.TRANSPARENT, 0.0, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_patience() -> void:
	var ratio := patience_ratio()
	var bar_color := Painter.MINT
	if ratio < 0.55:
		bar_color = Painter.BUTTER
	if ratio < 0.28:
		bar_color = Painter.CORAL
	if not is_front:
		# 后排顾客只用一根细耐心条，避免三条大血条和订单气泡遮住厨房。
		Painter.panel(self, Rect2(-31, -118, 62, 9), 4, Color(1, 1, 1, 0.78), Painter.INK_SOFT, 1.1, false)
		if ratio > 0.0:
			Painter.panel(self, Rect2(-29, -116, 58 * ratio, 5), 2.5, bar_color,
				Color.TRANSPARENT, 0.0, false)
		return
	var pulse := 1.0
	if ratio < 0.25:
		pulse = 1.0 + sin(_anim * 9.0) * 0.04
	draw_set_transform(Vector2(0, -121), 0.0, Vector2(pulse, pulse))
	Painter.heart(self, Vector2(-50, 1), 13, Painter.CORAL if ratio < 0.3 else Painter.PEACH)
	Painter.panel(self, Rect2(-41, -6, 82, 13), 6, Color(1, 1, 1, 0.82), Painter.INK_SOFT, 1.4, false)
	var fill_width := maxf(0.0, 72.0 * ratio)
	if fill_width > 1.0:
		Painter.panel(self, Rect2(-37, -2, fill_width, 5), 2.5, bar_color, Color.TRANSPARENT, 0.0, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if ratio < 0.28:
		Painter.draw_centered(self, "!", Vector2(58, -119), 18, Painter.TOMATO, true)


func _draw_order_bubble() -> void:
	if order.is_empty():
		return
	var recipe_name := str(order.get("recipe_name", "热狗"))
	var sauce_name := str(order.get("sauce_name", "原味"))
	var sauce_color := GameData.color(str(order.get("sauce_color", "#D9534F")), Painter.TOMATO)
	if is_front:
		Painter.panel(self, BUBBLE_FRONT, 13, Painter.PAPER, Painter.INK, 2.0, true)
		# 气泡尾巴
		draw_colored_polygon(PackedVector2Array([
			Vector2(-9, -141), Vector2(9, -141), Vector2(0, -129)
		]), Painter.PAPER)
		draw_line(Vector2(-9, -141), Vector2(0, -129), Painter.INK, 1.8, true)
		draw_line(Vector2(9, -141), Vector2(0, -129), Painter.INK, 1.8, true)
		# 内容
		Painter.draw_food_icon(self, "hotdog", Vector2(-45, -168), 0.55,
			str(order.get("quality_hint", "perfect")), {
				"ketchup": bool(order.get("ketchup", false)),
				"mustard": bool(order.get("mustard", false)),
			})
		Painter.draw_text(self, str(profile.get("name", "顾客")), Vector2(-18, -179), 9,
			Color(0.48, 0.36, 0.28, 0.8), false, HORIZONTAL_ALIGNMENT_LEFT, 78)
		Painter.draw_text(self, recipe_name, Vector2(-18, -164), 12, Painter.INK, true,
			HORIZONTAL_ALIGNMENT_LEFT, 82)
		draw_circle(Vector2(-13, -154), 4.0, sauce_color)
		Painter.draw_text(self, sauce_name, Vector2(-4, -150), 9, Color(0.41, 0.30, 0.22), false,
			HORIZONTAL_ALIGNMENT_LEFT, 62)
	else:
		Painter.panel(self, BUBBLE_BACK, 10, Color(1, 1, 1, 0.92), Painter.INK, 1.7, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-6, -147), Vector2(6, -147), Vector2(0, -138)
		]), Color(1, 1, 1, 0.92))
		Painter.draw_food_icon(self, "hotdog", Vector2(-25, -161), 0.44,
			"perfect", {
				"ketchup": bool(order.get("ketchup", false)),
				"mustard": bool(order.get("mustard", false)),
			})
		draw_circle(Vector2(5, -167), 4.0, sauce_color)
		Painter.draw_text(self, "等", Vector2(12, -156), 11, Color(0.48, 0.36, 0.28, 0.8), true,
			HORIZONTAL_ALIGNMENT_LEFT, 24)


func _draw_happy() -> void:
	var bob := sin(_anim * 7.0) * 2.0
	draw_circle(Vector2(-19, -97 + bob), 3.0, Painter.CORAL)
	draw_circle(Vector2(18, -104 + bob), 2.5, Painter.BUTTER)
	Painter.draw_centered(self, "谢谢！", Vector2(0, -132 + bob), 15, Painter.TEAL, true)
	if reward_given > 0:
		Painter.draw_centered(self, "+¥%d" % reward_given, Vector2(0, -113 + bob), 13,
			Color(0.78, 0.54, 0.16), true)
	# 闭眼弧线和笑容
	for side in [-1.0, 1.0]:
		draw_arc(Vector2(side * 8, -80 + bob), 4.0, PI + 0.2, TAU - 0.2, 10, Painter.INK, 1.8, true)
	draw_arc(Vector2(0, -70 + bob), 6.0, 0.15, PI - 0.15, 12, Painter.INK, 2.0, true)


func _draw_angry() -> void:
	Painter.draw_centered(self, "…", Vector2(0, -129), 22, Painter.TOMATO, true)
	# 怒气符号
	var c := Vector2(25, -109)
	for i in range(3):
		var angle := -0.7 + i * 1.2
		draw_line(c + Vector2(cos(angle), sin(angle)) * 4, c + Vector2(cos(angle), sin(angle)) * 10,
			Painter.TOMATO, 2.2, true)
	# 皱起的眉毛
	draw_line(Vector2(-15, -86), Vector2(-5, -82), Painter.INK, 2.0, true)
	draw_line(Vector2(15, -86), Vector2(5, -82), Painter.INK, 2.0, true)
	draw_arc(Vector2(0, -66), 6.0, PI + 0.25, TAU - 0.25, 12, Painter.INK, 2.0, true)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
