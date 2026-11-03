class_name AssemblyStation
extends Station
## 组装台：先放烤好的肠，再拿面包合上，最后取走成品热狗。

var board_sausages: Array[Dictionary] = []
var board_hotdog: Dictionary = {}
var board_bun := false


func on_setup() -> void:
	reset_board()


func reset_board() -> void:
	board_sausages.clear()
	board_hotdog.clear()
	board_bun = false
	queue_redraw()


func get_prompt(player: Player) -> Dictionary:
	if player == null:
		return {"text": "组装台", "enabled": false}
	if not board_hotdog.is_empty():
		if not player.has_item():
			return {"text": "拿起做好的热狗", "enabled": true}
		return {"text": "组装台上已经有一份热狗", "enabled": false}
	if player.item_type() == "cooked_sausage":
		if board_sausages.size() >= 2:
			return {"text": "这里最多放两根肠", "enabled": false}
		return {"text": "把烤肠放到组装台", "enabled": true}
	if player.item_type() == "bun":
		if board_bun:
			return {"text": "台上已经有一个面包了", "enabled": false}
		return {"text": "把面包放到组装台", "enabled": true}
	if player.has_item():
		return {"text": "这里需要烤肠或面包", "enabled": false}
	if board_bun and not board_sausages.is_empty():
		return {"text": "合上热狗", "enabled": true}
	if not board_sausages.is_empty():
		return {"text": "取回一根烤肠", "enabled": true}
	if board_bun:
		return {"text": "取回面包", "enabled": true}
	return {"text": "需要烤好的热狗肠", "enabled": false}


func interact(player: Player) -> void:
	if player == null:
		return
	if not board_hotdog.is_empty():
		if player.has_item():
			notify("先把%s处理掉，才能拿起热狗。" % GameData.item_name(player.get_item()), Painter.CORAL_DARK)
			return
		var hotdog := board_hotdog.duplicate(true)
		board_hotdog.clear()
		player.set_item(hotdog)
		queue_redraw()
		notify("热狗组装好了，去加酱或者直接交付。", Painter.TEAL)
		return
	if player.item_type() == "cooked_sausage":
		if board_sausages.size() >= 2:
			notify("组装台最多放两根肠。", Painter.CORAL_DARK)
			return
		board_sausages.append(player.get_item())
		player.clear_item()
		queue_redraw()
		if board_bun:
			notify("烤肠放上案板了（%d/2）。空手按 E 可以合上。" % board_sausages.size())
		else:
			notify("烤肠放上案板了（%d/2）。" % board_sausages.size(), Painter.TEAL)
		return
	if player.item_type() == "bun":
		if board_bun:
			notify("台上已经有一个面包了。", Painter.BROWN)
			return
		if board_sausages.is_empty():
			# 支持“先拿面包”的顺手流程：面包可以先放台上等烤肠。
			board_bun = true
			player.clear_item()
			queue_redraw()
			notify("面包先放台上了，去拿烤肠吧。", Painter.TEAL)
			return
		board_hotdog = GameData.make_hotdog(board_sausages, {"ketchup": false, "mustard": false})
		board_sausages.clear()
		player.clear_item()
		queue_redraw()
		notify("面包合上了，现在去挤酱吧。", Painter.TEAL)
		return
	if player.has_item():
		notify("组装台需要的是烤肠或面包。", Painter.BROWN)
		return
	if board_bun and not board_sausages.is_empty():
		board_hotdog = GameData.make_hotdog(board_sausages, {"ketchup": false, "mustard": false})
		board_sausages.clear()
		board_bun = false
		queue_redraw()
		notify("面包合上了，现在去挤酱吧。", Painter.TEAL)
		return
	if not board_sausages.is_empty():
		var returned: Dictionary = board_sausages.pop_back()
		player.set_item(returned)
		queue_redraw()
		notify("取回一根烤肠。", Painter.BROWN)
		return
	if board_bun:
		board_bun = false
		player.set_item(GameData.make_bun())
		queue_redraw()
		notify("取回面包。", Painter.BROWN)
		return
	notify("案板还是空的，先去煎烤台做一根烤肠。", Painter.BROWN)


func _draw_station_art() -> void:
	var w := footprint.x
	var h := footprint.y
	Painter.iso_box(self, Vector2.ZERO, w, h, 48, Color(0.824, 0.639, 0.435),
		Color(0.655, 0.443, 0.278), Color(0.545, 0.353, 0.224))
	# 案板
	Painter.diamond(self, Vector2(0, -48), w * 0.82, h * 0.76, Color(0.949, 0.796, 0.588))
	Painter.diamond(self, Vector2(0, -48), w * 0.74, h * 0.68, Color(0.996, 0.894, 0.714))
	# 油纸
	var paper := Painter.ellipse_points(Vector2(0, -51), 60, 24)
	draw_colored_polygon(paper, Color(1, 0.992, 0.961, 0.85))
	draw_polyline(_closed(paper), Color(0.73, 0.60, 0.44, 0.5), 1.2, true)
	if not board_hotdog.is_empty():
		Painter.draw_item_icon(self, board_hotdog, Vector2(0, -65), 0.92)
	elif not board_sausages.is_empty():
		if board_bun:
			Painter.draw_item_icon(self, GameData.make_bun(), Vector2(0, -69), 0.78)
		for i in range(board_sausages.size()):
			var center := Vector2(-26.0 + i * 52.0, -55.0 + (i % 2) * 3.0)
			Painter.draw_item_icon(self, board_sausages[i], center, 0.70)
		if board_bun:
			Painter.draw_centered(self, "按 E 合上", Vector2(0, -30), 8, Color(0.38, 0.27, 0.18, 0.65))
	elif board_bun:
		Painter.draw_item_icon(self, GameData.make_bun(), Vector2(0, -65), 0.95)
		Painter.draw_centered(self, "等烤肠", Vector2(0, -45), 9, Color(0.45, 0.34, 0.24, 0.55))
	else:
		# 空案板：淡淡虚线圈
		var points := Painter.ellipse_points(Vector2(0, -53), 38, 15, 24)
		for i in range(0, points.size(), 2):
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			draw_line(a, b, Color(0.56, 0.43, 0.30, 0.35), 1.4, true)
		Painter.draw_centered(self, "放上食材", Vector2(0, -49), 9, Color(0.45, 0.34, 0.24, 0.55))
	# 旁边的小工具
	draw_line(Vector2(62, -46), Vector2(84, -66), Painter.INK, 5.0, true)
	draw_line(Vector2(62, -46), Vector2(84, -66), Painter.GRAY, 3.0, true)
	draw_rect(Rect2(55, -48, 16, 6), Painter.BROWN_DARK)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
