class_name SauceStation
extends Station
## 酱料台：番茄酱 / 芥末酱。持有做好的热狗时按 E 挤酱。

@export_enum("ketchup", "mustard") var sauce_id := "ketchup"


func sauce_name() -> String:
	return "番茄酱" if sauce_id == "ketchup" else "芥末酱"


func sauce_color() -> Color:
	return Painter.TOMATO if sauce_id == "ketchup" else Painter.MUSTARD


func get_prompt(player: Player) -> Dictionary:
	if player == null:
		return {"text": "酱料台", "enabled": false}
	var item := player.get_item()
	if str(item.get("type", "")) != "hotdog":
		return {"text": "需要一份做好的热狗", "enabled": false}
	var sauces: Dictionary = item.get("sauces", {})
	if bool(sauces.get(sauce_id, false)):
		return {"text": "已经加过%s了" % sauce_name(), "enabled": false}
	return {"text": "挤%s" % sauce_name(), "enabled": true}


func interact(player: Player) -> void:
	if player == null:
		return
	var item := player.get_item()
	if str(item.get("type", "")) != "hotdog":
		notify("先把热狗组装好，再来挤酱。", Painter.BROWN)
		return
	var sauces: Dictionary = item.get("sauces", {})
	if bool(sauces.get(sauce_id, false)):
		notify("这份热狗已经有%s了。" % sauce_name(), Painter.BROWN)
		return
	sauces[sauce_id] = true
	item["sauces"] = sauces
	player.set_item(item)
	notify("挤上%s，香！" % sauce_name(), sauce_color().darkened(0.25))


func _draw_station_art() -> void:
	var w := footprint.x
	var h := footprint.y
	var color := sauce_color()
	Painter.iso_box(self, Vector2.ZERO, w, h, 42, Color(0.996, 0.961, 0.902),
		Color(0.96, 0.84, 0.69), Color(0.89, 0.73, 0.55))
	# 台面颜色块
	Painter.diamond(self, Vector2(0, -42), w * 0.82, h * 0.74, Color(1.0, 0.964, 0.902))
	# 酱料瓶
	Painter.draw_sauce_bottle(self, Vector2(0, -77), color, 1.02)
	# 小碟和挤出的酱
	draw_colored_polygon(Painter.ellipse_points(Vector2(30, -47), 19, 8), Color(0.986, 0.953, 0.892))
	draw_polyline(_closed(Painter.ellipse_points(Vector2(30, -47), 19, 8)), Painter.INK, 1.6, true)
	draw_colored_polygon(Painter.ellipse_points(Vector2(30, -48), 8, 3.2), color)
	# 前面板标签
	Painter.panel(self, Rect2(-33, -23, 66, 22), 6, Color(1.0, 0.97, 0.92), Painter.INK, 1.5, false)
	Painter.draw_centered(self, sauce_name(), Vector2(0, -8), 11, color.darkened(0.2), true)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
