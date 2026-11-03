class_name GameHUD
extends Control
## 游戏中 HUD：全部采用矢量绘制，圆角卡片、清楚图标、统一字体。
## 重要信息分布在四角，中央与厨房动线尽量留空。

var manager: GameManager
var player: Player
var economy: EconomySystem
var cooking: CookingSystem
var queue: CustomerQueue
var interaction: InteractionSystem
var order_system: OrderSystem

var _toasts: Array[Dictionary] = []
var _anim := 0.0


func setup(manager_node: GameManager, player_node: Player, economy_node: EconomySystem,
		cooking_node: CookingSystem, queue_node: CustomerQueue, interaction_node: InteractionSystem,
		order_sys: OrderSystem) -> void:
	manager = manager_node
	player = player_node
	economy = economy_node
	cooking = cooking_node
	queue = queue_node
	interaction = interaction_node
	order_system = order_sys
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	manager.toast_requested.connect(add_toast)
	economy.coins_changed.connect(func(_v): queue_redraw())
	economy.satisfaction_changed.connect(func(_v): queue_redraw())
	economy.stats_changed.connect(func(_v): queue_redraw())
	player.inventory_changed.connect(func(_v): queue_redraw())
	set_process(true)
	queue_redraw()


func add_toast(text: String, color: Color) -> void:
	if text.strip_edges().is_empty():
		return
	_toasts.append({"text": text, "color": color, "life": 3.1, "max": 3.1})
	while _toasts.size() > 2:
		_toasts.pop_front()
	queue_redraw()


func clear_toasts() -> void:
	_toasts.clear()
	queue_redraw()


func _process(delta: float) -> void:
	_anim += delta
	if not visible:
		return
	var changed := false
	for toast in _toasts:
		toast["life"] = float(toast["life"]) - delta
		if float(toast["life"]) <= 0.0:
			changed = true
	if changed:
		_toasts = _toasts.filter(func(t): return float(t["life"]) > 0.0)
	queue_redraw()


func _draw() -> void:
	_draw_brand_card()
	_draw_order_card()
	_draw_status_card()
	_draw_held_card()
	_draw_cooking_card()
	_draw_interaction_prompt()
	_draw_toasts()


func _card(rect: Rect2, fill := Color(1.0, 0.978, 0.937, 0.965), border := Painter.INK) -> void:
	Painter.panel(self, rect, 18, fill, border, 2.2, true)


func _draw_brand_card() -> void:
	var rect := Rect2(22, 18, 300, 82)
	_card(rect)
	draw_circle(Vector2(62, 59), 27, Painter.PEACH)
	draw_circle(Vector2(62, 59), 27, Color.TRANSPARENT) # 保持位置，无填充
	draw_arc(Vector2(62, 59), 27, 0.0, TAU, 30, Painter.INK, 2.0, true)
	Painter.draw_food_icon(self, "hotdog", Vector2(62, 59), 0.72, "perfect", {"ketchup": true})
	Painter.draw_text(self, "汉堡物语", Vector2(100, 47), 18, Painter.INK, true,
		HORIZONTAL_ALIGNMENT_LEFT, 118)
	draw_circle(Vector2(106, 64), 3.0, Painter.TEAL)
	Painter.draw_text(self, "营业中 · 第 1 日", Vector2(115, 68), 10,
		Color(0.45, 0.35, 0.27, 0.8), false, HORIZONTAL_ALIGNMENT_LEFT, 110)
	# 分隔线
	draw_line(Vector2(216, 38), Vector2(216, 80), Color(0.84, 0.73, 0.60, 0.55), 1.4, true)
	Painter.draw_text(self, "金币", Vector2(234, 40), 9, Color(0.52, 0.40, 0.30, 0.75), false,
		HORIZONTAL_ALIGNMENT_LEFT, 70)
	Painter.coin(self, Vector2(241, 64), 13)
	Painter.draw_text(self, str(economy.coins), Vector2(260, 72), 22, Painter.INK, true,
		HORIZONTAL_ALIGNMENT_LEFT, 56)


func _draw_order_card() -> void:
	var rect := Rect2(340, 16, 460, 146)
	_card(rect)
	# 顶部标签
	Painter.panel(self, Rect2(358, 29, 82, 22), 7, Painter.MINT_LIGHT, Color.TRANSPARENT, 0.0, false)
	draw_circle(Vector2(370, 40), 3.2, Painter.TEAL)
	Painter.draw_text(self, "当前订单", Vector2(379, 44), 11, Painter.TEAL, true,
		HORIZONTAL_ALIGNMENT_LEFT, 64)
	var front := queue.get_front() if queue else null
	if front == null:
		_draw_empty_order(rect)
		return
	var order := front.order
	var patience := front.patience_left
	var ratio := front.patience_ratio()
	# 顾客头像
	draw_circle(Vector2(390, 82), 29, Color(0.965, 0.925, 0.855))
	draw_arc(Vector2(390, 82), 29, 0.0, TAU, 28, Color(0.80, 0.69, 0.56), 1.5, true)
	Painter.draw_avatar(self, Vector2(390, 82), str(front.profile.get("species", "cat")),
		GameData.color(str(front.profile.get("fur", "#F4C98F"))),
		GameData.color(str(front.profile.get("accent", "#D89462"))),
		GameData.color(str(front.profile.get("shirt", "#9DD8C0"))), 0.52)
	Painter.draw_text(self, str(front.profile.get("name", "顾客")), Vector2(428, 64), 16,
		Painter.INK, true, HORIZONTAL_ALIGNMENT_LEFT, 100)
	Painter.draw_text(self, "第 1 位顾客", Vector2(428, 81), 9, Color(0.50, 0.39, 0.30, 0.75),
		false, HORIZONTAL_ALIGNMENT_LEFT, 100)
	# 订单内容
	Painter.draw_text(self, str(order.get("recipe_name", "热狗")), Vector2(548, 69), 22,
		Painter.INK, true, HORIZONTAL_ALIGNMENT_LEFT, 168)
	var sauce_name := str(order.get("sauce_name", "原味"))
	var sauce_color := GameData.color(str(order.get("sauce_color", "#D9534F")), Painter.TOMATO)
	draw_circle(Vector2(554, 84), 4.5, sauce_color)
	Painter.draw_text(self, sauce_name, Vector2(564, 89), 12, Color(0.40, 0.29, 0.21), false,
		HORIZONTAL_ALIGNMENT_LEFT, 150)
	# 右侧食物预览
	draw_circle(Vector2(742, 82), 40, Color(0.988, 0.949, 0.874))
	Painter.draw_food_icon(self, "hotdog", Vector2(742, 81), 1.12, "perfect", {
		"ketchup": bool(order.get("ketchup", false)),
		"mustard": bool(order.get("mustard", false)),
	})
	# 耐心
	var bar_color := Painter.MINT
	if ratio < 0.55:
		bar_color = Painter.BUTTER
	if ratio < 0.28:
		bar_color = Painter.CORAL
	Painter.heart(self, Vector2(360, 130), 15, bar_color)
	Painter.draw_text(self, "耐心", Vector2(371, 135), 10, Color(0.48, 0.37, 0.28), true,
		HORIZONTAL_ALIGNMENT_LEFT, 32)
	Painter.panel(self, Rect2(404, 123, 358, 13), 6, Color(0.886, 0.839, 0.777, 0.9),
		Color(0.76, 0.65, 0.53), 1.2, false)
	var fill_width := 354.0 * ratio
	if fill_width > 2.0:
		Painter.panel(self, Rect2(406, 125, fill_width, 9), 4, bar_color, Color.TRANSPARENT, 0.0, false)
	Painter.draw_text(self, "%d%%" % int(round(ratio * 100.0)), Vector2(764, 134), 10,
		Color(0.48, 0.37, 0.28), true, HORIZONTAL_ALIGNMENT_LEFT, 28)
	Painter.draw_text(self, "%ds" % int(ceil(patience)), Vector2(571, 116), 10,
		Color(0.50, 0.39, 0.30, 0.7), false, HORIZONTAL_ALIGNMENT_RIGHT, 80)


func _draw_empty_order(rect: Rect2) -> void:
	draw_circle(Vector2(390, 82), 29, Color(0.945, 0.905, 0.840))
	draw_arc(Vector2(390, 82), 29, 0.0, TAU, 26, Color(0.78, 0.68, 0.55), 1.5, true)
	draw_circle(Vector2(382, 78), 2.6, Color(0.66, 0.57, 0.48))
	draw_circle(Vector2(398, 78), 2.6, Color(0.66, 0.57, 0.48))
	draw_arc(Vector2(390, 88), 6.0, 0.2, PI - 0.2, 12, Color(0.66, 0.57, 0.48), 1.6, true)
	Painter.draw_text(self, "下一位顾客正在路上", Vector2(432, 72), 18, Painter.INK, true,
		HORIZONTAL_ALIGNMENT_LEFT, 280)
	var dots := ".".repeat(1 + int(_anim * 2.0) % 3)
	Painter.draw_text(self, "先准备好食材，别让烤架空着" + dots, Vector2(432, 94), 11,
		Color(0.51, 0.40, 0.31, 0.78), false, HORIZONTAL_ALIGNMENT_LEFT, 280)
	Painter.panel(self, Rect2(404, 123, 358, 13), 6, Color(0.886, 0.839, 0.777, 0.7),
		Color(0.80, 0.70, 0.58), 1.2, false)
	Painter.draw_text(self, "等候中", Vector2(764, 134), 10, Color(0.50, 0.39, 0.30, 0.6), false,
		HORIZONTAL_ALIGNMENT_LEFT, 30)


func _draw_status_card() -> void:
	var rect := Rect2(818, 16, 440, 146)
	_card(rect)
	# 时间
	Painter.draw_text(self, "营业时间", Vector2(842, 40), 10, Color(0.51, 0.40, 0.31, 0.8), false,
		HORIZONTAL_ALIGNMENT_LEFT, 100)
	Painter.draw_text(self, GameData.format_time(manager.time_left), Vector2(842, 71), 27,
		Painter.INK, true, HORIZONTAL_ALIGNMENT_LEFT, 120)
	var time_ratio := clampf(manager.time_left / maxf(1.0, manager.shift_duration), 0.0, 1.0)
	Painter.panel(self, Rect2(842, 80, 142, 6), 3, Color(0.88, 0.82, 0.74), Color.TRANSPARENT, 0.0, false)
	if time_ratio > 0.0:
		var time_color := Painter.TEAL if time_ratio > 0.25 else Painter.CORAL
		Painter.panel(self, Rect2(842, 80, 142 * time_ratio, 6), 3, time_color, Color.TRANSPARENT, 0.0, false)
	# 满意度
	Painter.heart(self, Vector2(1003, 54), 18, Painter.CORAL)
	Painter.draw_text(self, "满意度", Vector2(1023, 42), 10, Color(0.51, 0.40, 0.31, 0.8), false,
		HORIZONTAL_ALIGNMENT_LEFT, 76)
	Painter.draw_text(self, str(economy.satisfaction), Vector2(1023, 72), 27, Painter.INK, true,
		HORIZONTAL_ALIGNMENT_LEFT, 60)
	Painter.draw_text(self, "%", Vector2(1074, 68), 12, Color(0.50, 0.39, 0.30), true,
		HORIZONTAL_ALIGNMENT_LEFT, 20)
	# 接待
	Painter.draw_text(self, "已接待", Vector2(1145, 42), 10, Color(0.51, 0.40, 0.31, 0.8), false,
		HORIZONTAL_ALIGNMENT_LEFT, 70)
	Painter.draw_text(self, str(economy.stats.get("served", 0)), Vector2(1145, 72), 27,
		Painter.INK, true, HORIZONTAL_ALIGNMENT_LEFT, 50)
	Painter.draw_text(self, "位", Vector2(1192, 68), 11, Color(0.50, 0.39, 0.30), false,
		HORIZONTAL_ALIGNMENT_LEFT, 24)
	# 分隔线
	draw_line(Vector2(834, 94), Vector2(1242, 94), Color(0.85, 0.76, 0.65, 0.5), 1.2, true)
	Painter.draw_text(self, "等候区", Vector2(834, 120), 10, Color(0.51, 0.40, 0.31, 0.8), true,
		HORIZONTAL_ALIGNMENT_LEFT, 52)
	var max_queue := maxi(1, int(GameData.section("customers").get("max_queue", 2)))
	var gap := 8.0
	var chip_width := (348.0 - gap * float(max_queue - 1)) / float(max_queue)
	for i in range(max_queue):
		_draw_queue_chip(i, Vector2(888 + i * (chip_width + gap), 100), chip_width)


func _draw_queue_chip(index: int, pos: Vector2, chip_width: float) -> void:
	var rect := Rect2(pos, Vector2(chip_width, 48))
	var customer: Customer = queue.customers[index] if index < queue.customers.size() else null
	if customer == null:
		Painter.panel(self, rect, 9, Color(0.961, 0.925, 0.867, 0.68), Color(0.85, 0.77, 0.66), 1.1, false)
		draw_circle(pos + Vector2(20, 25), 12, Color(0.90, 0.86, 0.79, 0.7))
		Painter.draw_text(self, "空位", pos + Vector2(39, 29), 10, Color(0.60, 0.51, 0.43, 0.65), false,
			HORIZONTAL_ALIGNMENT_LEFT, chip_width - 46)
		return
	var border := Painter.CORAL if index == 0 else Color(0.86, 0.78, 0.67)
	Painter.panel(self, rect, 9, Color(1, 0.984, 0.949, 0.94), border, 1.4, false)
	Painter.draw_avatar(self, pos + Vector2(20, 26), str(customer.profile.get("species", "cat")),
		GameData.color(str(customer.profile.get("fur", "#F4C98F"))),
		GameData.color(str(customer.profile.get("accent", "#D89462"))),
		GameData.color(str(customer.profile.get("shirt", "#9DD8C0"))), 0.29)
	Painter.draw_text(self, str(customer.profile.get("name", "顾客")), pos + Vector2(38, 20), 9,
		Painter.INK, true, HORIZONTAL_ALIGNMENT_LEFT, chip_width - 46)
	var ratio := customer.patience_ratio()
	var color := Painter.MINT
	if ratio < 0.55:
		color = Painter.BUTTER
	if ratio < 0.28:
		color = Painter.CORAL
	var bar_width := chip_width - 54.0
	Painter.panel(self, Rect2(pos + Vector2(38, 26), Vector2(bar_width, 6)), 3, Color(0.88, 0.82, 0.74),
		Color.TRANSPARENT, 0.0, false)
	if ratio > 0.0:
		Painter.panel(self, Rect2(pos + Vector2(38, 26), Vector2(bar_width * ratio, 6)), 3, color,
			Color.TRANSPARENT, 0.0, false)
	Painter.draw_text(self, "%ds" % int(ceil(customer.patience_left)), pos + Vector2(38, 43), 8,
		Color(0.55, 0.44, 0.35, 0.75), false, HORIZONTAL_ALIGNMENT_LEFT, chip_width - 46)


func _draw_held_card() -> void:
	var rect := Rect2(22, 590, 300, 108)
	_card(rect)
	Painter.draw_text(self, "手持物品", Vector2(38, 609), 10, Color(0.51, 0.40, 0.31, 0.8), true,
		HORIZONTAL_ALIGNMENT_LEFT, 90)
	var item := player.get_item()
	if item.is_empty():
		draw_circle(Vector2(70, 650), 24, Color(0.945, 0.910, 0.850))
		draw_arc(Vector2(70, 650), 24, 0.0, TAU, 26, Color(0.79, 0.69, 0.58), 1.5, true)
		Painter.draw_text(self, "空手", Vector2(102, 645), 17, Painter.INK, true,
			HORIZONTAL_ALIGNMENT_LEFT, 100)
		Painter.draw_text(self, "靠近设备按 E 互动", Vector2(102, 665), 10,
			Color(0.51, 0.40, 0.31, 0.75), false, HORIZONTAL_ALIGNMENT_LEFT, 190)
		return
	draw_circle(Vector2(70, 650), 26, Color(1.0, 0.961, 0.898))
	draw_arc(Vector2(70, 650), 26, 0.0, TAU, 28, Color(0.80, 0.68, 0.54), 1.5, true)
	Painter.draw_item_icon(self, item, Vector2(70, 650), 0.95)
	var title := GameData.item_name(item)
	var hint := ""
	if str(item.get("type", "")) == "hotdog":
		title = GameData.hotdog_name(item)
		var state := GameData.cook_state_by_id(str(item.get("quality", "raw")))
		hint = "%s · %s" % [str(state.get("label", "")), GameData.hotdog_sauce_label(item)]
	elif str(item.get("type", "")) == "raw_sausage":
		hint = "拿去煎烤台"
	elif str(item.get("type", "")) == "cooked_sausage":
		hint = "拿去组装台"
	elif str(item.get("type", "")) == "bun":
		hint = "去组装台合上热狗"
	Painter.draw_text(self, title, Vector2(104, 644), 16, Painter.INK, true,
		HORIZONTAL_ALIGNMENT_LEFT, 202)
	Painter.draw_text(self, hint, Vector2(104, 665), 10, Color(0.46, 0.35, 0.26, 0.82), false,
		HORIZONTAL_ALIGNMENT_LEFT, 202)
	# 酱料点
	if str(item.get("type", "")) == "hotdog":
		var sauces: Dictionary = item.get("sauces", {})
		var dot_x := 104.0
		if bool(sauces.get("ketchup", false)):
			draw_circle(Vector2(dot_x, 676), 3.5, Painter.TOMATO)
			dot_x += 14.0
		if bool(sauces.get("mustard", false)):
			draw_circle(Vector2(dot_x, 676), 3.5, Painter.MUSTARD)


func _draw_cooking_card() -> void:
	var rect := Rect2(900, 540, 358, 158)
	_card(rect)
	# 火焰小图标
	_draw_small_flame(Vector2(922, 557))
	Painter.draw_text(self, "煎烤台", Vector2(936, 563), 14, Painter.INK, true,
		HORIZONTAL_ALIGNMENT_LEFT, 100)
	var occupied := cooking.occupied_count()
	var status := "空闲" if occupied == 0 else "%d/%d 根在烤" % [occupied, cooking.max_slots]
	Painter.draw_text(self, status, Vector2(1148, 563), 10,
		Color(0.51, 0.39, 0.30, 0.8), false, HORIZONTAL_ALIGNMENT_RIGHT, 96)
	draw_line(Vector2(914, 573), Vector2(1244, 573), Color(0.85, 0.76, 0.65, 0.5), 1.1, true)
	for i in range(cooking.max_slots):
		_draw_cook_row(i, Rect2(914, 582 + i * 37, 330, 31))


func _draw_cook_row(index: int, rect: Rect2) -> void:
	var slot: Dictionary = cooking.slots[index]
	var occupied := bool(slot.get("occupied", false))
	var fill := Color(0.984, 0.953, 0.904) if occupied else Color(0.957, 0.925, 0.870, 0.7)
	Painter.panel(self, rect, 8, fill, Color(0.89, 0.81, 0.70), 0.8, false)
	draw_circle(rect.position + Vector2(13, 15), 8, Color(0.85, 0.78, 0.67) if occupied else Color(0.91, 0.87, 0.81))
	Painter.draw_centered(self, str(index + 1), rect.position + Vector2(13, 19), 9,
		Painter.BROWN if occupied else Color(0.65, 0.56, 0.48), true)
	if not occupied:
		Painter.draw_text(self, "空烤位", rect.position + Vector2(37, 20), 10,
			Color(0.63, 0.54, 0.45, 0.6), false, HORIZONTAL_ALIGNMENT_LEFT, 80)
		return
	var state := GameData.cook_state(float(slot.get("elapsed", 0.0)))
	var state_id := str(state.get("id", "raw"))
	var state_color := GameData.color(str(state.get("color", "#A8653C")), Painter.BROWN)
	# 火候窗口刻度
	var bar_bg := Rect2(rect.position + Vector2(31, 12), Vector2(184, 8))
	Painter.panel(self, bar_bg, 4, Color(0.874, 0.831, 0.764), Color.TRANSPARENT, 0.0, false)
	# 完美窗口浅色带
	var perfect_start := 8.0 / 14.5
	var perfect_end := 11.5 / 14.5
	Painter.panel(self, Rect2(bar_bg.position.x + bar_bg.size.x * perfect_start, bar_bg.position.y,
		bar_bg.size.x * (perfect_end - perfect_start), 8), 3, Color(0.79, 0.92, 0.83),
		Color.TRANSPARENT, 0.0, false)
	var ratio := cooking.progress_for_slot(index)
	if ratio > 0.01:
		Painter.panel(self, Rect2(bar_bg.position, Vector2(bar_bg.size.x * ratio, 8)), 4,
			state_color, Color.TRANSPARENT, 0.0, false)
	Painter.draw_text(self, str(state.get("label", "未知")), rect.position + Vector2(224, 20), 10,
		state_color.darkened(0.15), true, HORIZONTAL_ALIGNMENT_LEFT, 70)
	# 品质提示小圆点
	var dot_color := Painter.MINT if state_id == "perfect" else state_color
	draw_circle(rect.position + Vector2(302, 16), 3.2, dot_color)


func _draw_small_flame(center: Vector2) -> void:
	var flicker := 1.0 + sin(_anim * 8.0) * 0.08
	var points := PackedVector2Array([
		center + Vector2(0, -8 * flicker), center + Vector2(5, 1), center + Vector2(3, 6),
		center + Vector2(-3, 6), center + Vector2(-5, 1)
	])
	draw_colored_polygon(points, Painter.CORAL)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[0]]),
		Painter.INK, 1.2, true)
	draw_circle(center + Vector2(0, 3), 1.8, Painter.BUTTER)


func _draw_interaction_prompt() -> void:
	var prompt: Dictionary = interaction.current_prompt
	var text := str(prompt.get("text", ""))
	if text.is_empty():
		# 空闲时的底部操作条
		var width := 310.0
		var rect := Rect2(640 - width * 0.5, 651, width, 33)
		Painter.panel(self, rect, 12, Color(1.0, 0.973, 0.925, 0.82), Color(0.77, 0.67, 0.56, 0.55), 1.4, true)
		Painter.draw_centered(self, "WASD 移动   ·   E 互动   ·   ESC 暂停", Vector2(640, 673), 11,
			Color(0.48, 0.37, 0.28, 0.85))
		return
	var enabled := bool(prompt.get("enabled", true))
	var font_size := 13
	var text_width := Painter.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var width := clampf(text_width + 104.0, 320.0, 500.0)
	var rect := Rect2(640 - width * 0.5, 642, width, 50)
	var accent := Painter.CORAL if enabled else Color(0.72, 0.65, 0.57)
	Painter.panel(self, rect, 15, Color(1.0, 0.980, 0.941, 0.97), accent, 2.2, true)
	Painter.keycap(self, Vector2(rect.position.x + 30, 667), "E", 28)
	Painter.draw_text(self, text, Vector2(rect.position.x + 54, 672), font_size,
		Painter.INK if enabled else Color(0.55, 0.46, 0.38), true, HORIZONTAL_ALIGNMENT_LEFT,
		width - 64)
	if not enabled:
		Painter.draw_centered(self, "!", Vector2(rect.end.x - 17, 671), 14, Color(0.72, 0.55, 0.40), true)


func _draw_toasts() -> void:
	for i in range(_toasts.size()):
		var toast: Dictionary = _toasts[i]
		var text := str(toast.get("text", ""))
		var color: Color = toast.get("color", Painter.INK)
		var life := float(toast.get("life", 0.0))
		var max_life := float(toast.get("max", 1.0))
		var alpha := clampf(life / 0.55, 0.0, 1.0)
		var fade_in := clampf((max_life - life) / 0.18, 0.0, 1.0)
		alpha *= fade_in
		var font_size := 12
		var text_width := Painter.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var width := minf(760.0, text_width + 66.0)
		var rect := Rect2(640 - width * 0.5, 176 + i * 38, width, 32)
		var fill := Color(1.0, 0.980, 0.941, 0.92 * alpha)
		Painter.panel(self, rect, 11, fill, Color(color.r, color.g, color.b, 0.55 * alpha), 1.4, false)
		draw_circle(rect.position + Vector2(18, 16), 3.8, Color(color.r, color.g, color.b, alpha))
		Painter.draw_text(self, text, Vector2(rect.position.x + 30, rect.position.y + 21), font_size,
			Color(Painter.INK.r, Painter.INK.g, Painter.INK.b, alpha), true,
			HORIZONTAL_ALIGNMENT_LEFT, width - 40)
