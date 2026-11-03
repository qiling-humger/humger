class_name GrillStation
extends Station
## 煎烤台：放上生肠、按 E 取走火候最好的一根，并显示火候和烟雾。

var cooking: CookingSystem

const SLOT_CENTERS := [Vector2(-67, -65), Vector2(0, -59), Vector2(67, -53)]


func on_setup() -> void:
	if manager and "cooking_system" in manager:
		cooking = manager.cooking_system


func wants_animation() -> bool:
	return cooking != null and cooking.has_any()


func get_prompt(player: Player) -> Dictionary:
	if cooking == null:
		return {"text": "烤架还没准备好", "enabled": false}
	if player == null:
		return {"text": "煎烤台", "enabled": false}
	if player.item_type() == "raw_sausage":
		if cooking.has_empty_slot():
			return {"text": "把生肠放上烤架", "enabled": true}
		return {"text": "烤架已经满了", "enabled": false}
	if player.has_item():
		return {"text": "手上拿着别的物品", "enabled": false}
	if cooking.has_any():
		return {"text": "取出火候最好的一根", "enabled": true}
	return {"text": "需要一根生热狗肠", "enabled": false}


func interact(player: Player) -> void:
	if player == null or cooking == null:
		return
	if player.item_type() == "raw_sausage":
		if cooking.has_empty_slot():
			var index := cooking.place_raw()
			player.clear_item()
			if index >= 0:
				queue_redraw()
				notify("放上烤架了，盯紧火候！", Painter.TEAL)
		else:
			notify("三个烤位都满了，先取一根下来。", Painter.CORAL_DARK)
		return
	if player.has_item():
		notify("先把%s放下再来操作烤架。" % GameData.item_name(player.get_item()), Painter.CORAL_DARK)
		return
	if not cooking.has_any():
		notify("烤架是空的，先去生肠冷柜拿一根。", Painter.BROWN)
		return
	var item := cooking.take_best()
	if item.is_empty():
		return
	player.set_item(item)
	queue_redraw()
	var quality := str(item.get("quality", "raw"))
	notify(cooking.toast_for_quality(quality), _quality_color(quality))


func _quality_color(quality: String) -> Color:
	match quality:
		"perfect":
			return Painter.TEAL
		"just_cooked":
			return Color(0.55, 0.47, 0.20)
		"overcooked", "burnt":
			return Painter.CORAL_DARK
	return Painter.BROWN


func _draw_station_art() -> void:
	var w := footprint.x
	var h := footprint.y
	# 后挡板
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w * 0.45, -58), Vector2(w * 0.45, -58),
		Vector2(w * 0.45, -20), Vector2(-w * 0.45, -20)
	]), Color(0.851, 0.831, 0.808))
	draw_polyline(PackedVector2Array([
		Vector2(-w * 0.45, -58), Vector2(w * 0.45, -58),
		Vector2(w * 0.45, -20), Vector2(-w * 0.45, -20), Vector2(-w * 0.45, -58)
	]), Painter.INK, 2.2, true)
	Painter.iso_box(self, Vector2.ZERO, w, h, 58, Color(0.478, 0.459, 0.435),
		Color(0.776, 0.745, 0.706), Color(0.635, 0.604, 0.573))
	# 灶台火床
	Painter.diamond(self, Vector2(0, -58), w * 0.82, h * 0.76, Color(0.251, 0.235, 0.224), Painter.INK, 2.0)
	# 余温辉光
	var glow := 0.18 + sin(anim_t * 3.0) * 0.05
	draw_colored_polygon(Painter.ellipse_points(Vector2(0, -57), 62, 23),
		Color(0.94, 0.44, 0.19, glow * 0.42))
	# 烤网
	for i in range(5):
		var y := -82.0 + i * 11.0
		var half := 92.0 - absf(i - 2) * 12.0
		draw_line(Vector2(-half, y), Vector2(half, y), Color(0.58, 0.54, 0.49, 0.7), 1.6, true)
	for i in range(4):
		var x := -75.0 + i * 50.0
		draw_line(Vector2(x, -88), Vector2(x, -31), Color(0.58, 0.54, 0.49, 0.5), 1.4, true)
	# 三个烤位
	for i in range(3):
		var center: Vector2 = SLOT_CENTERS[i]
		var occupied := cooking != null and i < cooking.slots.size() and bool(cooking.slots[i].get("occupied", false))
		if not occupied:
			draw_colored_polygon(Painter.ellipse_points(center, 25, 9), Color(0.188, 0.173, 0.165))
			draw_polyline(_closed(Painter.ellipse_points(center, 25, 9)), Color(0.36, 0.33, 0.30), 1.4, true)
			draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), Color(0.45, 0.40, 0.35, 0.45), 1.2, true)
			continue
		var state := GameData.cook_state(float(cooking.slots[i].get("elapsed", 0.0)))
		var color := GameData.color(str(state.get("color", "#A8653C")), Painter.BROWN)
		# 火候进度条
		var ratio := cooking.progress_for_slot(i)
		Painter.panel(self, Rect2(center + Vector2(-22, 15), Vector2(44, 5)), 2.5,
			Color(0.2, 0.18, 0.16, 0.55), Color.TRANSPARENT, 0.0, false)
		if ratio > 0.01:
			Painter.panel(self, Rect2(center + Vector2(-21, 16), Vector2(42 * ratio, 3)), 1.5,
				_quality_bar_color(str(state.get("id", "raw"))), Color.TRANSPARENT, 0.0, false)
		# 烤肠
		Painter.capsule(self, center + Vector2(-19, 0), center + Vector2(19, 0), color, 14.0, true)
		draw_line(center + Vector2(-10, -3), center + Vector2(8, -3), Color(1, 0.92, 0.76, 0.34), 2.0, true)
		if str(state.get("id", "")) in ["overcooked", "burnt"]:
			draw_line(center + Vector2(-6, 4), center + Vector2(4, -4), Color(0.17, 0.12, 0.10, 0.7), 2.0, true)
			draw_line(center + Vector2(7, 4), center + Vector2(15, -4), Color(0.17, 0.12, 0.10, 0.7), 2.0, true)
		# 火候小字
		Painter.draw_centered(self, str(state.get("label", "")), center + Vector2(0, 29), 9,
			Color(0.97, 0.91, 0.80), true)
		# 烟雾
		_draw_smoke(center, str(state.get("id", "raw")), i)
	# 前面板旋钮和火焰标志
	for x in [-74.0, 74.0]:
		draw_circle(Vector2(x, -13), 8.5, Color(0.34, 0.32, 0.30))
		draw_arc(Vector2(x, -13), 8.5, 0.0, TAU, 18, Painter.INK, 1.8, true)
		draw_line(Vector2(x, -13), Vector2(x + 4, -19), Painter.CREAM, 2.0, true)
	_draw_flame(Vector2(0, -16))
	# 集油盒
	Painter.panel(self, Rect2(-32, -4, 64, 12), 3, Color(0.36, 0.33, 0.30), Painter.INK, 1.4, false)


func _quality_bar_color(id: String) -> Color:
	match id:
		"perfect":
			return Painter.MINT
		"just_cooked":
			return Painter.BUTTER
		"overcooked":
			return Painter.CORAL
		"burnt":
			return Color(0.25, 0.20, 0.18)
	return Painter.GRAY


func _draw_smoke(center: Vector2, state_id: String, seed_index: int) -> void:
	if state_id in ["raw", "heating"]:
		return
	for i in range(3):
		var t := fmod(anim_t * 0.55 + float(i) * 0.31 + seed_index * 0.17, 1.0)
		var x := center.x + sin(anim_t * 1.7 + i * 2.0 + seed_index) * 8.0
		var y := center.y - 10.0 - t * 48.0
		var radius := 5.0 + t * 9.0
		var alpha := (1.0 - t) * (0.18 if state_id != "burnt" else 0.28)
		var smoke_color := Color(1, 1, 1, alpha) if state_id != "burnt" else Color(0.25, 0.22, 0.20, alpha)
		draw_circle(Vector2(x, y), radius, smoke_color)


func _draw_flame(center: Vector2) -> void:
	var flicker := 1.0 + sin(anim_t * 8.0) * 0.10
	var points := PackedVector2Array([
		center + Vector2(0, -14 * flicker),
		center + Vector2(8, 2),
		center + Vector2(5, 9),
		center + Vector2(-5, 9),
		center + Vector2(-8, 2),
	])
	draw_colored_polygon(points, Color(0.96, 0.50, 0.20))
	draw_polyline(_closed(points), Painter.INK, 1.6, true)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -6), center + Vector2(4, 3), center + Vector2(0, 7), center + Vector2(-4, 3)
	]), Color(0.99, 0.80, 0.31))


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
