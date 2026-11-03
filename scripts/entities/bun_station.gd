class_name BunStation
extends Station
## 面包篮：取一个热狗面包。


func get_prompt(player: Player) -> Dictionary:
	if player and player.has_item():
		return {"text": "手上已有物品", "enabled": false}
	return {"text": "拿一个热狗面包", "enabled": true}


func interact(player: Player) -> void:
	if player == null:
		return
	if player.has_item():
		notify("手上已经拿着%s了。" % GameData.item_name(player.get_item()), Painter.CORAL_DARK)
		return
	player.set_item(GameData.make_bun())
	notify("拿到一个松软的面包。", Painter.TEAL)


func _draw_station_art() -> void:
	var w := footprint.x
	var h := footprint.y
	Painter.iso_box(self, Vector2.ZERO, w, h, 36, Color(0.957, 0.851, 0.706),
		Color(0.749, 0.557, 0.376), Color(0.639, 0.443, 0.286))
	# 桌面格纹布
	Painter.diamond(self, Vector2(0, -36), w * 0.80, h * 0.70, Color(0.984, 0.925, 0.831))
	# 编织篮
	var basket_center := Vector2(0, -53)
	draw_colored_polygon(Painter.ellipse_points(basket_center, 48, 19), Color(0.686, 0.447, 0.251))
	draw_polyline(_closed(Painter.ellipse_points(basket_center, 48, 19)), Painter.INK, 2.2, true)
	for i in range(5):
		draw_arc(basket_center + Vector2(0, i * 2.5), 45 - i * 7, 0.15, PI - 0.15, 18,
			Color(0.89, 0.72, 0.49, 0.65), 1.7, true)
	# 面包
	var bun_positions := [Vector2(-24, -60), Vector2(0, -66), Vector2(24, -58)]
	for pos in bun_positions:
		Painter.shadow(self, pos + Vector2(0, 10), 20, 6, Color(0.2, 0.13, 0.08, 0.12))
		draw_colored_polygon(Painter.ellipse_points(pos, 21, 12), Color(0.941, 0.659, 0.337))
		draw_polyline(_closed(Painter.ellipse_points(pos, 21, 12)), Painter.INK, 2.0, true)
		draw_arc(pos + Vector2(0, -2), 14, 0.25, PI - 0.25, 12, Color(0.996, 0.847, 0.612), 2.2, true)
	# 小木牌
	Painter.panel(self, Rect2(-32, -27, 64, 22), 6, Color(0.988, 0.902, 0.741), Painter.INK, 1.6, false)
	Painter.draw_centered(self, "每日现烤", Vector2(0, -11), 10, Painter.BROWN, true)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
