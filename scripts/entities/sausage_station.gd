class_name SausageStation
extends Station
## 生肠冷柜：取一根生热狗肠。


func get_prompt(player: Player) -> Dictionary:
	if player and player.has_item():
		return {"text": "手上已有物品，先处理掉吧", "enabled": false}
	return {"text": "取一根生热狗肠", "enabled": true}


func interact(player: Player) -> void:
	if player == null:
		return
	if player.has_item():
		notify("手上已经拿着%s了。" % GameData.item_name(player.get_item()), Painter.CORAL_DARK)
		return
	player.set_item(GameData.make_raw_sausage())
	notify("拿到一根生热狗肠，去煎烤台吧。", Painter.TEAL)


func _draw_station_art() -> void:
	var w := footprint.x
	var h := footprint.y
	Painter.iso_box(self, Vector2.ZERO, w, h, 52, Color(0.996, 0.973, 0.925),
		Color(0.655, 0.867, 0.769), Color(0.420, 0.741, 0.647))
	# 台面上的展示托盘
	Painter.diamond(self, Vector2(0, -52), w * 0.78, h * 0.72, Color(0.831, 0.663, 0.475))
	Painter.diamond(self, Vector2(0, -52), w * 0.70, h * 0.62, Color(0.945, 0.843, 0.690))
	# 三根生肠
	for i in range(3):
		var center := Vector2(-38.0 + i * 38.0, -58.0 + absf(i - 1) * 3.0)
		Painter.shadow(self, center + Vector2(0, 4), 22, 5, Color(0.2, 0.12, 0.08, 0.13))
		Painter.capsule(self, center + Vector2(-17, 0), center + Vector2(17, 0),
			Color(0.953, 0.690, 0.661), 14.0, true)
		draw_line(center + Vector2(-9, -3), center + Vector2(7, -3), Color(1, 1, 1, 0.45), 2.0, true)
	# 玻璃罩
	var dome := PackedVector2Array()
	var center := Vector2(0, -54)
	for i in range(25):
		var angle := PI + PI * float(i) / 24.0
		dome.append(center + Vector2(cos(angle) * (w * 0.40), sin(angle) * 53.0))
	dome.append(center + Vector2(w * 0.40, 4))
	dome.append(center + Vector2(-w * 0.40, 4))
	draw_colored_polygon(dome, Color(0.690, 0.878, 0.902, 0.20))
	var dome_outline := dome.duplicate()
	dome_outline.append(dome[0])
	draw_polyline(dome_outline, Color(0.49, 0.65, 0.64, 0.7), 2.0, true)
	draw_line(center + Vector2(-w * 0.40, -3), center + Vector2(-w * 0.22, -34), Color(1, 1, 1, 0.55), 3.0, true)
	# 正面小标签
	Painter.panel(self, Rect2(-27, -31, 54, 25), 7, Color(0.996, 0.925, 0.784), Painter.INK, 1.8, false)
	Painter.draw_centered(self, "新鲜", Vector2(0, -13), 12, Painter.BROWN, true)
	# 冷柜底部小灯
	draw_circle(Vector2(-w * 0.30, -12), 3.0, Painter.MINT_LIGHT)
	draw_circle(Vector2(-w * 0.30, -12), 5.5, Color(0.62, 0.85, 0.75, 0.22))
