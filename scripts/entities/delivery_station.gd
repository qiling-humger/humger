class_name DeliveryStation
extends Station
## 交付窗口：把热狗交给队首顾客，校验订单并触发结算。

var ring_time := 0.0


func wants_animation() -> bool:
	return ring_time > 0.0


func ring_bell() -> void:
	ring_time = 0.8
	queue_redraw()


func _process(delta: float) -> void:
	super._process(delta)
	if ring_time > 0.0:
		ring_time = maxf(0.0, ring_time - delta)
		queue_redraw()


func get_prompt(player: Player) -> Dictionary:
	var front: Customer = manager.customer_queue.get_front() if manager and manager.customer_queue else null
	if player == null:
		return {"text": "交付窗口", "enabled": false}
	if front == null:
		return {"text": "暂时没有等待的顾客", "enabled": false}
	if player.item_type() != "hotdog":
		return {"text": "把做好的热狗拿来", "enabled": false}
	return {"text": "把热狗交给%s" % str(front.profile.get("name", "顾客")), "enabled": true}


func interact(player: Player) -> void:
	ring_bell()
	if manager:
		manager.deliver_hotdog(player)


func _draw_station_art() -> void:
	var w := footprint.x
	var h := footprint.y
	Painter.iso_box(self, Vector2.ZERO, w, h, 56, Color(0.996, 0.961, 0.902),
		Color(0.620, 0.851, 0.753), Color(0.400, 0.706, 0.608))
	# 台面
	Painter.diamond(self, Vector2(0, -56), w * 0.84, h * 0.76, Color(0.984, 0.933, 0.847))
	# 前脸薄荷格子
	for i in range(5):
		var x := -w * 0.40 + i * (w * 0.20)
		draw_line(Vector2(x, -48), Vector2(x, -2), Color(0.31, 0.62, 0.53, 0.22), 1.5, true)
	# 收银机
	Painter.panel(self, Rect2(-75, -104, 56, 48), 8, Color(0.435, 0.396, 0.353), Painter.INK, 2.0, false)
	Painter.panel(self, Rect2(-68, -98, 42, 19), 4, Color(0.639, 0.827, 0.757), Painter.INK, 1.6, false)
	for row in range(2):
		for col in range(3):
			draw_circle(Vector2(-61 + col * 14, -68 + row * 12), 3.4, Color(0.945, 0.851, 0.706))
	# 小票
	draw_colored_polygon(PackedVector2Array([
		Vector2(-78, -110), Vector2(-47, -112), Vector2(-44, -98), Vector2(-80, -96)
	]), Color(1, 0.992, 0.965))
	draw_polyline(PackedVector2Array([
		Vector2(-78, -110), Vector2(-47, -112), Vector2(-44, -98), Vector2(-80, -96), Vector2(-78, -110)
	]), Painter.INK, 1.4, true)
	# 交付托盘
	Painter.diamond(self, Vector2(2, -60), 82, 34, Color(0.741, 0.545, 0.376))
	Painter.diamond(self, Vector2(2, -60), 70, 27, Color(0.894, 0.745, 0.557))
	# 铃铛
	var bell_x := 63.0
	var ding := sin(ring_time * 28.0) * ring_time * 9.0 if ring_time > 0.0 else 0.0
	draw_set_transform(Vector2(bell_x + ding, -57), 0.0, Vector2.ONE)
	draw_colored_polygon(Painter.ellipse_points(Vector2(0, 0), 18, 8), Color(0.96, 0.80, 0.35))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -1), Vector2(-12, -18), Vector2(12, -18), Vector2(16, -1)
	]), Color(0.98, 0.84, 0.39))
	draw_polyline(PackedVector2Array([
		Vector2(-16, -1), Vector2(-12, -18), Vector2(12, -18), Vector2(16, -1), Vector2(-16, -1)
	]), Painter.INK, 1.8, true)
	draw_circle(Vector2(0, -20), 4.0, Painter.BROWN)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if ring_time > 0.0:
		for i in range(2):
			var radius := 24.0 + i * 10.0 + (0.8 - ring_time) * 18.0
			draw_arc(Vector2(bell_x, -75), radius, -PI * 0.7, -PI * 0.3, 16,
				Color(0.96, 0.77, 0.30, ring_time * 0.8), 2.0, true)
	# 下方欢迎小牌
	Painter.panel(self, Rect2(-48, -25, 96, 21), 6, Color(1, 0.976, 0.925), Painter.INK, 1.6, false)
	Painter.draw_centered(self, "谢谢光临", Vector2(0, -10), 10, Painter.TEAL, true)
