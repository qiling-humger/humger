class_name PauseScreen
extends Control
## 暂停菜单：继续 / 重开 / 退出。

signal resume_requested
signal restart_requested
signal quit_requested


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var resume := UiKit.make_button("继续营业", true, 260, 54)
	resume.position = Vector2(510, 292)
	resume.pressed.connect(func(): resume_requested.emit())
	add_child(resume)
	var restart := UiKit.make_button("重新开始", false, 260, 50)
	restart.position = Vector2(510, 362)
	restart.pressed.connect(func(): restart_requested.emit())
	add_child(restart)
	var quit := UiKit.make_button("退出游戏", false, 260, 50)
	quit.position = Vector2(510, 428)
	quit.pressed.connect(func(): quit_requested.emit())
	add_child(quit)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.14, 0.10, 0.08, 0.58))
	var card := Rect2(430, 140, 420, 400)
	Painter.panel(self, card, 28, Color(1.0, 0.973, 0.925), Painter.INK, 3.0, true)
	Painter.panel(self, Rect2(450, 154, 380, 7), 3, Painter.MINT, Color.TRANSPARENT, 0.0, false)
	# 小图标
	Painter.draw_food_icon(self, "hotdog", Vector2(640, 212), 0.95, "perfect", {
		"ketchup": true, "mustard": false
	})
	Painter.draw_centered(self, "暂停一下", Vector2(640, 264), 34, Painter.INK, true)
	Painter.draw_centered(self, "厨房的火已经关小了", Vector2(640, 285), 12,
		Color(0.52, 0.40, 0.31, 0.8))
	draw_line(Vector2(500, 505), Vector2(780, 505), Color(0.83, 0.70, 0.56, 0.5), 1.5, true)
	Painter.draw_centered(self, "ESC 也可以继续", Vector2(640, 524), 11,
		Color(0.56, 0.44, 0.34, 0.65))
