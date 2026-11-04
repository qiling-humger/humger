class_name VisualSampleUI
extends MapUI
## 只改样板标题，资源栏、建造面板和提示继续复用现有 MapUI 逻辑。


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
	Painter.draw_text(self, "视觉样板 · 8×8", TITLE_BAR.position + Vector2(57, 50), 9,
		Color(0.49, 0.38, 0.30, 0.85), false)
