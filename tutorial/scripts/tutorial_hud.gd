class_name TutorialHUD
extends Control
## Tutorial-only objective/coin/shop overlay. The normal HUD remains underneath.

var game: TutorialGame


func setup(game_ref: TutorialGame) -> void:
	game = game_ref
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game == null:
		return
	_draw_day_card()
	_draw_objective_card()
	if game.day == 4 and (game.mud > 0 or game.water_count > 0 or game.big_carrot_active):
		_draw_day4_resources()
	if game.shop_open:
		_draw_shop()
	if game.completed:
		_draw_completion()


func _draw_day_card() -> void:
	var rect := Rect2(Vector2(24, 88), Vector2(300, 42))
	Painter.panel(self, rect, 12, Color(1.0, 0.973, 0.925, 0.95),
		Color(0.73, 0.61, 0.49, 0.7), 1.2, true)
	Painter.draw_text(self, "第 %d 天" % game.day, rect.position + Vector2(14, 27), 16,
		Painter.BROWN_DARK, true)
	Painter.draw_text(self, "金币 %d" % game.wallet, rect.position + Vector2(150, 27), 14,
		Color(0.66, 0.42, 0.16), true)


func _draw_objective_card() -> void:
	var rect := Rect2(Vector2(24, 142), Vector2(320, 88))
	Painter.panel(self, rect, 13, Color(1.0, 0.985, 0.94, 0.96),
		Color(0.74, 0.62, 0.50, 0.65), 1.3, true)
	Painter.draw_text(self, "当前目标", rect.position + Vector2(14, 22), 11,
		Color(0.55, 0.42, 0.32), false)
	Painter.draw_text(self, game.objective_text, rect.position + Vector2(14, 44), 14,
		Painter.BROWN_DARK, true)
	Painter.draw_text(self, game.hint_text, rect.position + Vector2(14, 68), 10,
		Color(0.46, 0.37, 0.28, 0.9), false)


func _draw_day4_resources() -> void:
	var rect := Rect2(Vector2(24, 240), Vector2(240, 36))
	Painter.panel(self, rect, 10, Color(1.0, 0.97, 0.90, 0.94),
		Color(0.65, 0.48, 0.32, 0.65), 1.1, true)
	Painter.draw_text(self, "泥土 %d/10   水 %d/6" % [game.mud, game.water_count],
		rect.position + Vector2(12, 24), 12, Painter.BROWN_DARK, true)


func _draw_shop() -> void:
	var rect := Rect2(Vector2(450, 220), Vector2(380, 210))
	Painter.panel(self, rect, 16, Color(1.0, 0.973, 0.925, 0.98),
		Color(0.48, 0.35, 0.24), 1.8, true)
	Painter.draw_text(self, "蛇商人的摊位", rect.position + Vector2(20, 30), 18,
		Painter.BROWN_DARK, true)
	Painter.draw_text(self, "1  胡萝卜    6 金币", rect.position + Vector2(24, 72), 14,
		Painter.BROWN_DARK, false)
	Painter.draw_text(self, "2  猫粮      12 金币", rect.position + Vector2(24, 108), 14,
		Painter.BROWN_DARK, false)
	Painter.draw_text(self, "Esc 离开", rect.position + Vector2(24, 164), 11,
		Color(0.55, 0.42, 0.32), false)
	Painter.draw_text(self, "金币 %d" % game.wallet, rect.position + Vector2(255, 164), 12,
		Color(0.66, 0.42, 0.16), true)


func _draw_completion() -> void:
	var rect := Rect2(Vector2(350, 230), Vector2(580, 220))
	Painter.panel(self, rect, 20, Color(1.0, 0.973, 0.925, 0.98),
		Color(0.42, 0.32, 0.22), 2.0, true)
	Painter.draw_centered(self, "启航！", rect.position + Vector2(290, 70), 36,
		Painter.CORAL_DARK, true)
	Painter.draw_centered(self, "新手关完成 · 汉堡物语", rect.position + Vector2(290, 118), 18,
		Painter.BROWN_DARK, true)
	Painter.draw_centered(self, "按 F5 保存进度", rect.position + Vector2(290, 160), 12,
		Color(0.45, 0.35, 0.27), false)
