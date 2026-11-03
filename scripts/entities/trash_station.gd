class_name TrashStation
extends Station
## 垃圾桶：丢弃手上的失败品，避免玩家被错误物品卡住。


func get_prompt(player: Player) -> Dictionary:
	if player and player.has_item():
		return {"text": "丢掉%s" % GameData.item_name(player.get_item()), "enabled": true}
	return {"text": "垃圾桶", "enabled": false}


func interact(player: Player) -> void:
	if player == null:
		return
	if not player.has_item():
		notify("垃圾桶里空空如也。", Painter.BROWN)
		return
	var item := player.get_item()
	player.clear_item()
	notify("丢掉了%s。" % GameData.item_name(item), Painter.BROWN)


func _draw_station_art() -> void:
	# 脚踏式垃圾桶，侧面椭圆表现圆柱。
	Painter.shadow(self, Vector2(0, 2), 34, 11, Color(0.2, 0.14, 0.1, 0.16))
	var body_rect := Rect2(-27, -58, 54, 56)
	Painter.panel(self, body_rect, 10, Color(0.596, 0.725, 0.635), Painter.INK, 2.2, false)
	draw_line(Vector2(-27, -20), Vector2(27, -20), Color(1, 1, 1, 0.22), 2.0, true)
	draw_line(Vector2(-27, -12), Vector2(27, -12), Color(0.20, 0.31, 0.24, 0.28), 2.0, true)
	# 盖子
	Painter.panel(self, Rect2(-34, -69, 68, 16), 8, Color(0.690, 0.808, 0.722), Painter.INK, 2.2, false)
	Painter.panel(self, Rect2(-13, -73, 26, 8), 4, Color(0.498, 0.612, 0.529), Painter.INK, 1.5, false)
	# 回收标志
	draw_arc(Vector2(0, -34), 11, -0.2, PI + 0.4, 16, Color(0.31, 0.51, 0.39, 0.7), 2.0, true)
	draw_line(Vector2(7, -40), Vector2(12, -32), Color(0.31, 0.51, 0.39, 0.7), 2.0, true)
	# 踏板
	Painter.panel(self, Rect2(-20, -4, 40, 9), 3, Color(0.34, 0.38, 0.34), Painter.INK, 1.4, false)
