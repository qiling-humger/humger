class_name HomeIslandUI
extends VisualSampleUI
## Home-island title and persistent save/demolish hint.


func _draw_title_card() -> void:
	Painter.panel(self, TITLE_BAR, 16, Color(1.0, 0.973, 0.925, 0.96),
		Color(0.75, 0.64, 0.53, 0.65), 1.6, true)
	var c := TITLE_BAR.position + Vector2(31, 36)
	Painter.diamond(self, c + Vector2(0, 2), 30, 15, Painter.MINT_LIGHT,
		Color(0.39, 0.58, 0.44), 1.4)
	draw_circle(c + Vector2(-5, 0), 3.4, Painter.LETTUCE)
	draw_circle(c + Vector2(6, 1), 2.8, Painter.LETTUCE)
	draw_line(c + Vector2(0, 6), c + Vector2(0, 11), Painter.BROWN, 1.6, true)
	Painter.draw_text(self, "家园岛", TITLE_BAR.position + Vector2(57, 31), 20,
		Painter.INK, true)
	var size_text := "可玩原型 V1 · 16×12"
	if game != null and game.grid != null:
		size_text = "可玩原型 V1 · %d×%d" % [game.grid.columns, game.grid.rows]
	Painter.draw_text(self, size_text, TITLE_BAR.position + Vector2(57, 50), 9,
		Color(0.49, 0.38, 0.30, 0.85), false)


func _draw() -> void:
	super._draw()
	Painter.draw_text(self, "F5 保存  ·  F9 读取  ·  右键拆除",
		Vector2(18, 708), 9, Color(0.36, 0.28, 0.21, 0.72), false)
