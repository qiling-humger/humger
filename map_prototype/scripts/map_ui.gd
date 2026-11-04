class_name MapUI
extends Control
## 家园岛原型 HUD：顶部资源栏、建造面板、交互提示和短提示。
## 全部用矢量绘制，保持现有项目的卡通纸片风格。

const TOP_BAR := Rect2(286, 16, 710, 68)
const TITLE_BAR := Rect2(18, 16, 250, 68)
const BUILD_PANEL := Rect2(1002, 104, 260, 532)
const PROMPT_RECT := Rect2(330, 648, 620, 46)

var game: Node
var _toasts: Array[Dictionary] = []
var _card_rects: Array[Rect2] = []
var _close_rect := Rect2(1234, 112, 20, 20)


func setup(game_ref: Node) -> void:
	game = game_ref
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(true)
	queue_redraw()


func add_toast(text: String, color: Color = Painter.INK) -> void:
	if text.strip_edges().is_empty():
		return
	_toasts.append({"text": text, "color": color, "life": 1.8, "max": 1.8})
	while _toasts.size() > 3:
		_toasts.pop_front()
	queue_redraw()


func _process(delta: float) -> void:
	if _toasts.is_empty():
		return
	for toast in _toasts:
		toast["life"] = float(toast["life"]) - delta
	_toasts = _toasts.filter(func(t): return float(t["life"]) > 0.0)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	if game == null or game.placement == null:
		return
	var point := mb.position
	if game.placement.build_mode:
		if _close_rect.has_point(point):
			game.exit_build_mode()
			get_viewport().set_input_as_handled()
			return
		for i in range(_card_rects.size()):
			if _card_rects[i].has_point(point):
				game.select_buildable(i)
				get_viewport().set_input_as_handled()
				return
		if BUILD_PANEL.has_point(point):
			get_viewport().set_input_as_handled()
			return
	# 点到顶部栏、底部提示时不要穿透到地图。
	if TOP_BAR.has_point(point) or TITLE_BAR.has_point(point) or PROMPT_RECT.has_point(point):
		get_viewport().set_input_as_handled()


func _draw() -> void:
	_draw_title_card()
	_draw_resource_bar()
	if game != null and game.placement != null and game.placement.build_mode:
		_draw_build_panel()
	_draw_prompt()
	_draw_toasts()


func _draw_title_card() -> void:
	Painter.panel(self, TITLE_BAR, 16, Color(1.0, 0.973, 0.925, 0.96),
		Color(0.75, 0.64, 0.53, 0.65), 1.6, true)
	# 小岛图标
	var c := TITLE_BAR.position + Vector2(31, 36)
	Painter.diamond(self, c + Vector2(0, 2), 30, 15, Painter.MINT_LIGHT,
		Color(0.39, 0.58, 0.44), 1.4)
	draw_circle(c + Vector2(-5, 0), 3.4, Painter.LETTUCE)
	draw_circle(c + Vector2(6, 1), 2.8, Painter.LETTUCE)
	draw_line(c + Vector2(0, 6), c + Vector2(0, 11), Painter.BROWN, 1.6, true)
	Painter.draw_text(self, "家园岛", TITLE_BAR.position + Vector2(57, 31), 20,
		Painter.INK, true)
	Painter.draw_text(self, "地图与建造原型", TITLE_BAR.position + Vector2(57, 50), 9,
		Color(0.49, 0.38, 0.30, 0.85), false)


func _draw_resource_bar() -> void:
	Painter.panel(self, TOP_BAR, 16, Color(1.0, 0.973, 0.925, 0.96),
		Color(0.75, 0.64, 0.53, 0.65), 1.6, true)
	var order: Array = game.inventory.order
	var types: Dictionary = game.config.get("resource_types", {})
	for i in range(order.size()):
		var id := str(order[i])
		var data: Dictionary = types.get(id, {})
		var slot_x := TOP_BAR.position.x + 28.0 + float(i) * 112.0
		var icon_center := Vector2(slot_x + 15, TOP_BAR.position.y + 35)
		_draw_resource_icon(str(data.get("icon", "stone")), icon_center)
		var label := str(data.get("name", id))
		Painter.draw_text(self, label, Vector2(slot_x + 34, TOP_BAR.position.y + 26), 9,
			Color(0.48, 0.37, 0.28, 0.86), false)
		Painter.draw_text(self, str(game.inventory.get_count(id)),
			Vector2(slot_x + 34, TOP_BAR.position.y + 51), 19, Painter.INK, true)
		if i < order.size() - 1:
			draw_line(Vector2(slot_x + 98, TOP_BAR.position.y + 16),
				Vector2(slot_x + 98, TOP_BAR.position.y + 52),
				Color(0.75, 0.65, 0.54, 0.22), 1.0)


func _draw_resource_icon(kind: String, center: Vector2) -> void:
	match kind:
		"log":
			draw_set_transform(center, -0.45, Vector2.ONE)
			draw_line(Vector2(-8, 2), Vector2(8, -2), Painter.BROWN_DARK, 7.0, true)
			draw_line(Vector2(-8, 2), Vector2(8, -2), Color(0.70, 0.48, 0.29), 4.2, true)
			draw_circle(Vector2(8, -2), 3.4, Color(0.77, 0.57, 0.35))
			draw_circle(Vector2(8, -2), 1.5, Color(0.52, 0.34, 0.21))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"grass":
			draw_line(center + Vector2(-7, 8), center + Vector2(-9, -5), Color(0.32, 0.54, 0.27), 2.4, true)
			draw_line(center + Vector2(0, 8), center + Vector2(1, -10), Color(0.42, 0.65, 0.31), 2.4, true)
			draw_line(center + Vector2(7, 8), center + Vector2(9, -4), Color(0.32, 0.54, 0.27), 2.4, true)
		"leaf":
			var leaf := PackedVector2Array([
				center + Vector2(-9, 5), center + Vector2(-4, -8),
				center + Vector2(9, -5), center + Vector2(3, 7)
			])
			Painter.outline_polygon(self, leaf, Painter.PEACH, Color(0.55, 0.34, 0.20), 1.2)
			draw_line(center + Vector2(-6, 4), center + Vector2(6, -5),
				Color(0.55, 0.34, 0.20, 0.55), 1.0, true)
		"stone":
			draw_circle(center + Vector2(-3, 2), 7.0, Color(0.62, 0.63, 0.59))
			draw_circle(center + Vector2(5, 3), 5.0, Color(0.71, 0.72, 0.67))
			draw_arc(center + Vector2(-3, 2), 7.0, 0, TAU, 18, Color(0.44, 0.45, 0.41), 1.2, true)
		"dirt":
			var mound := PackedVector2Array([
				center + Vector2(-10, 6), center + Vector2(-4, -5),
				center + Vector2(5, -7), center + Vector2(10, 6)
			])
			Painter.outline_polygon(self, mound, Color(0.74, 0.55, 0.36), Color(0.50, 0.35, 0.23), 1.2)
			draw_circle(center + Vector2(2, 1), 1.3, Color(0.48, 0.33, 0.22, 0.5))
		"coin":
			draw_circle(center, 8.0, Painter.BUTTER)
			draw_arc(center, 8.0, 0, TAU, 20, Color(0.71, 0.50, 0.20), 1.4, true)
			draw_circle(center, 4.5, Color(0.97, 0.85, 0.48))
			draw_line(center + Vector2(-2, -3), center + Vector2(-2, 3), Color(0.68, 0.47, 0.16), 1.3, true)


func _draw_build_panel() -> void:
	Painter.panel(self, BUILD_PANEL, 18, Color(1.0, 0.984, 0.949, 0.97),
		Color(0.74, 0.62, 0.51, 0.7), 1.8, true)
	Painter.draw_text(self, "建造模式", BUILD_PANEL.position + Vector2(18, 30), 18,
		Painter.INK, true)
	Painter.draw_text(self, "B / Esc 退出 · 原型免费", BUILD_PANEL.position + Vector2(18, 48), 9,
		Color(0.49, 0.38, 0.30, 0.82), false)
	# 关闭按钮
	draw_circle(_close_rect.get_center(), 12.0, Color(0.93, 0.82, 0.74))
	draw_arc(_close_rect.get_center(), 12.0, 0, TAU, 20, Color(0.55, 0.42, 0.33, 0.6), 1.2, true)
	draw_line(_close_rect.get_center() + Vector2(-4, -4), _close_rect.get_center() + Vector2(4, 4),
		Painter.INK_SOFT, 1.6, true)
	draw_line(_close_rect.get_center() + Vector2(4, -4), _close_rect.get_center() + Vector2(-4, 4),
		Painter.INK_SOFT, 1.6, true)
	draw_line(Vector2(BUILD_PANEL.position.x + 16, BUILD_PANEL.position.y + 60),
		Vector2(BUILD_PANEL.end.x - 16, BUILD_PANEL.position.y + 60),
		Color(0.75, 0.64, 0.53, 0.25), 1.0)

	_card_rects.clear()
	var defs: Array = game.placement.definitions
	var selected: int = game.placement.selected_index
	for i in range(defs.size()):
		var def: Dictionary = defs[i]
		var card := Rect2(BUILD_PANEL.position + Vector2(14, 72 + i * 94),
			Vector2(BUILD_PANEL.size.x - 28, 82))
		_card_rects.append(card)
		var is_selected := i == selected
		var fill := Color(1.0, 0.934, 0.851, 0.98) if is_selected \
			else Color(1.0, 0.984, 0.949, 0.92)
		var border := Painter.CORAL if is_selected else Color(0.78, 0.68, 0.56, 0.45)
		Painter.panel(self, card, 13, fill, border, 2.2 if is_selected else 1.2, false)
		var def_color := Color.from_string(str(def.get("color", "#C58A55")),
			Color(0.78, 0.58, 0.38))
		var icon_center := card.position + Vector2(31, 42)
		Painter.diamond(self, icon_center + Vector2(0, 8), 32, 16,
			Color(def_color, 0.33), border, 1.2)
		Painter.iso_box(self, icon_center + Vector2(0, 13), 27, 14, 16,
			def_color, def_color.darkened(0.12), def_color.darkened(0.24),
			Painter.INK, 1.4, false)
		Painter.draw_text(self, str(def.get("name", "物件")),
			card.position + Vector2(55, 27), 14, Painter.INK, true)
		Painter.draw_text(self, "%d×%d  ·  %s" % [int(def.get("width", 1)),
			int(def.get("height", 1)), str(def.get("description", ""))],
			card.position + Vector2(55, 46), 9, Color(0.49, 0.38, 0.30, 0.84), false)
		Painter.draw_text(self, "数字键 %d" % (i + 1),
			card.position + Vector2(55, 64), 9, Color(0.61, 0.45, 0.33, 0.7), false)
		if is_selected:
			draw_circle(card.position + Vector2(card.size.x - 19, 19), 5.0, Painter.CORAL)
		# 保留卡片下方留白，避免四张卡片贴在一起。
		if i < defs.size() - 1:
			draw_line(Vector2(card.position.x + 8, card.end.y + 5),
				Vector2(card.end.x - 8, card.end.y + 5),
				Color(0.75, 0.64, 0.53, 0.16), 1.0)
	Painter.draw_text(self, "左键在地图上放置 · 数字键切换",
		BUILD_PANEL.position + Vector2(18, BUILD_PANEL.size.y - 16), 9,
		Color(0.49, 0.38, 0.30, 0.75), false)


func _draw_prompt() -> void:
	var prompt := ""
	var key := ""
	var accent := Painter.INK
	if game.placement.is_dragging():
		prompt = "拖动到空白格  ·  松开确认  ·  Esc 取消"
		accent = Painter.TEAL
	elif game.placement.build_mode:
		prompt = "左键放置  ·  1-4 选择物件  ·  B / Esc 退出"
		accent = Painter.BROWN
	elif game.nearest_resource != null and is_instance_valid(game.nearest_resource):
		var info: Dictionary = game.nearest_resource.prompt_data()
		var res_name := str(game.config.get("resource_types", {}).get(
			str(info.get("resource", "")), {}).get("name", "资源"))
		prompt = "%s  ·  %s +%d" % [str(info.get("verb", "采集")),
			res_name, int(info.get("amount", 0))]
		key = "E"
	else:
		prompt = "WASD 移动  ·  E 采集  ·  B 建造  ·  拖动已放置物件搬家"
	var fill := Color(1.0, 0.973, 0.925, 0.94)
	Painter.panel(self, PROMPT_RECT, 15, fill, Color(0.75, 0.64, 0.53, 0.55), 1.5, true)
	if key != "":
		Painter.keycap(self, Vector2(PROMPT_RECT.position.x + 29, PROMPT_RECT.get_center().y),
			key, 28)
		Painter.draw_text(self, prompt, Vector2(PROMPT_RECT.position.x + 52,
			PROMPT_RECT.get_center().y + 5), 13, accent, true)
	else:
		Painter.draw_centered(self, prompt, Vector2(PROMPT_RECT.get_center().x,
			PROMPT_RECT.get_center().y + 5), 12, accent, false)


func _draw_toasts() -> void:
	for i in range(_toasts.size()):
		var toast: Dictionary = _toasts[i]
		var life := float(toast.get("life", 0.0))
		var max_life := float(toast.get("max", 1.0))
		var alpha := clampf(life / minf(0.35, max_life), 0.0, 1.0)
		var text := str(toast.get("text", ""))
		var color: Color = toast.get("color", Painter.INK)
		var width := Painter.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 38.0
		var rect := Rect2(640 - width * 0.5, 98 + i * 36, width, 29)
		Painter.panel(self, rect, 12, Color(1.0, 0.984, 0.949, 0.93 * alpha),
			Color(color, 0.45 * alpha), 1.2, false)
		Painter.draw_centered(self, text, Vector2(640, rect.position.y + 20), 12,
			Color(color, alpha), true)
