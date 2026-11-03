class_name ResultsScreen
extends Control
## 结算界面：评级、金币、接待数、品质、失误与重开。

signal restart_requested
signal title_requested

var data: Dictionary = {}
var _anim := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var restart := UiKit.make_button("再开一局", true, 240, 58)
	restart.position = Vector2(376, 590)
	restart.pressed.connect(func(): restart_requested.emit())
	add_child(restart)
	var title := UiKit.make_button("回到标题", false, 210, 54)
	title.position = Vector2(654, 592)
	title.pressed.connect(func(): title_requested.emit())
	add_child(title)
	set_process(true)


func set_results(result_data: Dictionary) -> void:
	data = result_data.duplicate(true)
	queue_redraw()


func _process(delta: float) -> void:
	_anim += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.14, 0.10, 0.08, 0.63))
	var card := Rect2(280, 44, 720, 632)
	Painter.panel(self, card, 30, Color(1.0, 0.973, 0.925), Painter.INK, 3.0, true)
	Painter.panel(self, Rect2(300, 58, 680, 8), 4, Painter.CORAL, Color.TRANSPARENT, 0.0, false)
	# 彩纸装饰
	var confetti_colors := [Painter.CORAL, Painter.BUTTER, Painter.MINT, Painter.PEACH]
	for i in range(26):
		var x := 300.0 + fmod(float(i) * 137.0, 660.0)
		var y := 80.0 + fmod(float(i) * 73.0, 70.0) + sin(_anim * 1.5 + i) * 3.0
		var color: Color = confetti_colors[i % 4]
		draw_rect(Rect2(Vector2(x, y), Vector2(5, 9)), Color(color.r, color.g, color.b, 0.55))
	var reason := str(data.get("reason", "shift_end"))
	var title_text := "今日营业结束" if reason != "satisfaction" else "提前打烊了"
	var subtitle := "辛苦了，来看看今天的成绩吧。"
	if reason == "satisfaction":
		subtitle = "满意度跌到谷底，厨房需要休息一下。"
	Painter.draw_centered(self, title_text, Vector2(640, 142), 38, Painter.INK, true)
	Painter.draw_centered(self, subtitle, Vector2(640, 168), 13, Color(0.53, 0.40, 0.31, 0.85))
	draw_line(Vector2(320, 186), Vector2(960, 186), Color(0.85, 0.72, 0.58, 0.5), 1.5, true)
	_draw_rank(Vector2(422, 300))
	_draw_stats()
	# 分隔线 + 按钮提示
	draw_line(Vector2(324, 552), Vector2(956, 552), Color(0.85, 0.72, 0.58, 0.5), 1.5, true)
	Painter.draw_centered(self, "期待下一次开张。", Vector2(640, 578), 12,
		Color(0.56, 0.44, 0.34, 0.72))


func _draw_rank(center: Vector2) -> void:
	var rank := str(data.get("rank", "C"))
	var rank_color := Painter.GRAY
	match rank:
		"S":
			rank_color = Painter.BUTTER
		"A":
			rank_color = Painter.MINT
		"B":
			rank_color = Painter.PEACH
		"C":
			rank_color = Painter.GRAY
	draw_circle(center + Vector2(0, 6), 82, Color(0.25, 0.17, 0.12, 0.10))
	draw_circle(center, 82, Color(1, 1, 1, 0.68))
	draw_arc(center, 82, 0.0, TAU, 48, Painter.INK, 3.0, true)
	draw_arc(center, 72, 0.0, TAU, 48, rank_color, 6.0, true)
	Painter.draw_centered(self, rank, center + Vector2(0, 26), 72, rank_color.darkened(0.15), true)
	Painter.draw_centered(self, "本日评级", center + Vector2(0, 60), 12, Color(0.46, 0.35, 0.26), true)
	# 星星随评级增加
	var stars := 1
	match rank:
		"S":
			stars = 5
		"A":
			stars = 4
		"B":
			stars = 3
		"C":
			stars = 2
	for i in range(5):
		var pos := center + Vector2(-46 + i * 23, 96)
		Painter.star(self, pos, 10.0, Painter.BUTTER if i < stars else Color(0.82, 0.77, 0.68))
	Painter.draw_centered(self, "经营评分  %d" % int(data.get("score", 0)), center + Vector2(0, 126), 12,
		Color(0.48, 0.35, 0.25), true)


func _draw_stats() -> void:
	var panel := Rect2(550, 212, 380, 318)
	Painter.panel(self, panel, 18, Color(0.984, 0.949, 0.894), Color(0.83, 0.70, 0.56), 1.6, false)
	var stats := [
		{"label": "今日金币", "value": "¥%d" % int(data.get("coins", 0)), "color": Painter.BUTTER.darkened(0.22)},
		{"label": "接待顾客", "value": "%d 位" % int(data.get("served", 0)), "color": Painter.TEAL},
		{"label": "完美火候", "value": "%d 份" % int(data.get("perfect", 0)), "color": Painter.CORAL},
		{"label": "失误 / 流失", "value": "%d / %d" % [int(data.get("wrong", 0)), int(data.get("lost", 0))], "color": Painter.BROWN},
		{"label": "最终满意度", "value": "%d%%" % int(data.get("satisfaction", 0)), "color": Painter.TOMATO},
		{"label": "平均品质", "value": "%.1f / 4" % float(data.get("average_quality", 0.0)), "color": Painter.MINT.darkened(0.25)},
	]
	var y := 246.0
	for i in range(stats.size()):
		var row: Dictionary = stats[i]
		if i % 2 == 0 and i > 0:
			draw_line(Vector2(574, y - 22), Vector2(906, y - 22), Color(0.87, 0.78, 0.65, 0.45), 1.0, true)
		Painter.draw_text(self, str(row["label"]), Vector2(576, y), 12, Color(0.48, 0.37, 0.28), false,
			HORIZONTAL_ALIGNMENT_LEFT, 150)
		Painter.draw_text(self, str(row["value"]), Vector2(750, y + 1), 16, row["color"], true,
			HORIZONTAL_ALIGNMENT_RIGHT, 152)
		y += 47.0
	# 底部小字
	Painter.draw_text(self, "营业时长  %s" % GameData.format_time(float(data.get("time_played", 0.0))),
		Vector2(576, 500), 11, Color(0.54, 0.43, 0.34, 0.72), false, HORIZONTAL_ALIGNMENT_LEFT, 240)
