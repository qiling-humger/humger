class_name StartScreen
extends Control
## 开场界面：展示玩法、操作和目标。暖色卡片 + 手绘热狗插画。

signal start_requested

var _button: Button
var _anim := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button = UiKit.make_button("开始营业", true, 280, 60)
	_button.position = Vector2(500, 530)
	_button.size = Vector2(280, 60)
	_button.pressed.connect(_on_start)
	add_child(_button)
	set_process(true)


func _process(delta: float) -> void:
	_anim += delta
	if visible:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_start()


func _on_start() -> void:
	start_requested.emit()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.17, 0.12, 0.09, 0.56))
	# 卡片外的一点暖光
	draw_circle(Vector2(640, 340), 440, Color(0.98, 0.78, 0.50, 0.07))
	var card := Rect2(210, 44, 860, 632)
	Painter.panel(self, card, 30, Color(1.0, 0.973, 0.925), Painter.INK, 3.0, true)
	# 顶部色带
	Painter.panel(self, Rect2(230, 58, 820, 8), 4, Painter.MINT, Color.TRANSPARENT, 0.0, false)
	# 小旗子装饰
	for i in range(10):
		var x := 300.0 + i * 76.0
		var color: Color = [Painter.CORAL, Painter.BUTTER, Painter.MINT, Painter.PEACH][i % 4]
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 70), Vector2(x + 14, 78), Vector2(x, 86)
		]), Color(color.r, color.g, color.b, 0.7))
	# 标题
	Painter.draw_centered(self, "汉堡物语", Vector2(640, 164), 58, Painter.INK, true)
	Painter.draw_centered(self, "热狗小站 · 第一阶段试营业", Vector2(640, 197), 18,
		Color(0.53, 0.38, 0.28))
	# 中央分隔线
	draw_line(Vector2(350, 218), Vector2(930, 218), Color(0.83, 0.70, 0.56, 0.55), 2.0, true)
	_draw_illustration(Vector2(390, 352))
	_draw_instructions()
	# 营业目标卡片
	Painter.panel(self, Rect2(598, 420, 404, 86), 15, Color(0.922, 0.968, 0.937),
		Color(0.49, 0.66, 0.56), 2.0, false)
	Painter.draw_text(self, "营业目标", Vector2(618, 447), 15, Painter.TEAL, true,
		HORIZONTAL_ALIGNMENT_LEFT, 120)
	Painter.draw_text(self, "在 3 分钟内做出正确热狗，赚取金币，", Vector2(618, 469), 14,
		Color(0.32, 0.42, 0.35), false, HORIZONTAL_ALIGNMENT_LEFT, 372)
	Painter.draw_text(self, "别让满意度归零。", Vector2(618, 489), 14,
		Color(0.32, 0.42, 0.35), false, HORIZONTAL_ALIGNMENT_LEFT, 372)
	# 按钮下的提示
	Painter.draw_centered(self, "点击按钮，或按 Enter / 空格开始", Vector2(640, 620), 12,
		Color(0.55, 0.43, 0.34, 0.78))
	Painter.draw_centered(self, "Godot 4  ·  MVP BUILD 0.1", Vector2(640, 654), 10,
		Color(0.62, 0.52, 0.44, 0.55))
	# 四角小圆点
	for corner in [Vector2(244, 84), Vector2(1036, 84), Vector2(244, 646), Vector2(1036, 646)]:
		draw_circle(corner, 4.0, Color(0.90, 0.51, 0.41, 0.8))


func _draw_illustration(center: Vector2) -> void:
	# 盘子和阴影
	Painter.shadow(self, center + Vector2(0, 92), 145, 28, Color(0.2, 0.13, 0.09, 0.12))
	draw_colored_polygon(Painter.ellipse_points(center + Vector2(0, 76), 135, 38), Color(0.847, 0.914, 0.874))
	draw_polyline(_closed(Painter.ellipse_points(center + Vector2(0, 76), 135, 38)), Painter.INK, 2.4, true)
	draw_colored_polygon(Painter.ellipse_points(center + Vector2(0, 72), 116, 29), Color(0.969, 0.937, 0.859))
	# 蒸汽
	for i in range(3):
		var offset := Vector2(-56 + i * 56, -56 - sin(_anim * 1.3 + i) * 8.0)
		var points := PackedVector2Array()
		for k in range(8):
			var t := float(k) / 7.0
			points.append(offset + Vector2(sin(t * PI * 1.4 + i) * 9.0, -t * 42.0))
		draw_polyline(points, Color(0.99, 0.96, 0.88, 0.62), 7.0, true)
	# 大热狗
	Painter.draw_food_icon(self, "hotdog", center, 3.05, "perfect", {"ketchup": true, "mustard": true})
	# 小星星
	Painter.star(self, center + Vector2(-118, -55), 14, Painter.BUTTER)
	Painter.star(self, center + Vector2(120, -70), 10, Painter.CORAL)
	draw_circle(center + Vector2(108, 12), 6.0, Painter.MINT)
	draw_circle(center + Vector2(-110, 18), 4.0, Painter.PEACH)
	Painter.draw_centered(self, "刚出炉的完美热狗", Vector2(center.x, center.y + 122), 14,
		Color(0.48, 0.35, 0.25), true)


func _draw_instructions() -> void:
	var rows := [
		{"key": "WASD", "title": "移动", "desc": "在店里走到设备旁边"},
		{"key": "E", "title": "互动", "desc": "靠近按 E，或直接点设备"},
		{"key": "ESC", "title": "暂停", "desc": "随时喘口气，查看菜单"},
	]
	var y := 252.0
	for row in rows:
		var key_rect := Rect2(620, y - 24, 66, 36)
		Painter.panel(self, key_rect, 9, Painter.CREAM, Painter.INK, 2.0, true)
		Painter.draw_centered(self, str(row["key"]), Vector2(key_rect.position.x + 33, y), 12, Painter.INK, true)
		Painter.draw_text(self, str(row["title"]), Vector2(706, y - 5), 18, Painter.INK, true,
			HORIZONTAL_ALIGNMENT_LEFT, 80)
		Painter.draw_text(self, str(row["desc"]), Vector2(706, y + 15), 12,
			Color(0.49, 0.38, 0.30, 0.85), false, HORIZONTAL_ALIGNMENT_LEFT, 250)
		y += 55.0


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
