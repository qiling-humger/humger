class_name TutorialActor
extends Node2D
## Simple placeholder actors for the tutorial. These are not final art.

var kind := "customer"
var label_text := ""
var body_color := Color(0.85, 0.55, 0.4)
var order_text := ""
var state_text := ""


func setup(kind_value: String, label_value: String, color: Color) -> void:
	kind = kind_value
	label_text = label_value
	body_color = color
	queue_redraw()


func _draw() -> void:
	Painter.shadow(self, Vector2(0, 2), 24, 8, Color(0.14, 0.20, 0.13, 0.18))
	match kind:
		"snake":
			_draw_snake()
		"employee":
			_draw_employee()
		"big_carrot":
			_draw_big_carrot()
		"burrow":
			_draw_burrow()
		"mud":
			_draw_mud()
		"rabbit_customer":
			_draw_rabbit()
		"cat_customer":
			_draw_cat()
		_:
			_draw_customer()
	if not label_text.is_empty():
		Painter.draw_centered(self, label_text, Vector2(0, -74), 11,
			Color(0.30, 0.22, 0.17, 0.92), true)
	if not order_text.is_empty():
		var rect := Rect2(Vector2(-62, -132), Vector2(124, 32))
		Painter.panel(self, rect, 10, Color(1.0, 0.973, 0.925, 0.97),
			Color(0.62, 0.46, 0.34, 0.9), 1.4, true)
		Painter.draw_centered(self, order_text, rect.position + Vector2(62, 21), 11,
			Color(0.35, 0.24, 0.18), true)
	if not state_text.is_empty():
		Painter.draw_centered(self, state_text, Vector2(0, 28), 9,
			Color(0.32, 0.28, 0.22, 0.85), false)


func _draw_snake() -> void:
	var pts := PackedVector2Array()
	for i in range(18):
		var t := float(i) / 17.0
		pts.append(Vector2(-24 + t * 48, 12 - sin(t * PI * 1.3) * 22))
	draw_polyline(pts, Color(0.36, 0.62, 0.35), 10, true)
	draw_circle(Vector2(24, -20), 12, Color(0.44, 0.72, 0.40))
	draw_circle(Vector2(24, -20), 12, Color(0.20, 0.38, 0.20), false, 2.0)
	draw_circle(Vector2(29, -24), 2.2, Painter.INK)
	draw_line(Vector2(32, -16), Vector2(39, -13), Color(0.8, 0.3, 0.25), 2.0, true)
	draw_rect(Rect2(Vector2(-30, 8), Vector2(60, 10)), Color(0.70, 0.48, 0.28))


func _draw_employee() -> void:
	draw_circle(Vector2(0, -26), 24, body_color)
	draw_circle(Vector2(0, -26), 24, Color(0.80, 0.40, 0.32), false, 2.2)
	draw_circle(Vector2(-8, -30), 2.4, Painter.INK)
	draw_circle(Vector2(8, -30), 2.4, Painter.INK)
	draw_arc(Vector2(0, -22), 7, 0.15, PI - 0.15, 12, Painter.INK, 1.4, true)
	draw_rect(Rect2(Vector2(-23, 8), Vector2(46, 26)), Color(0.97, 0.84, 0.64))
	draw_rect(Rect2(Vector2(-17, 8), Vector2(34, 10)), Color(0.91, 0.49, 0.36))


func _draw_big_carrot() -> void:
	var body := PackedVector2Array([
		Vector2(0, -62), Vector2(26, -32), Vector2(19, -14),
		Vector2(0, 18), Vector2(-19, -14), Vector2(-26, -32)
	])
	draw_colored_polygon(body, Color(0.94, 0.48, 0.22))
	draw_polyline(body, Color(0.52, 0.22, 0.12), 2.2, true)
	for i in range(4):
		var y := -46.0 + i * 11.0
		draw_line(Vector2(-20, y), Vector2(20, y), Color(0.70, 0.30, 0.14, 0.55), 1.5, true)
	draw_circle(Vector2(-7, -40), 2.6, Painter.INK)
	draw_circle(Vector2(7, -40), 2.6, Painter.INK)
	draw_line(Vector2(0, -32), Vector2(0, -26), Painter.INK, 2.0, true)


func _draw_burrow() -> void:
	draw_colored_polygon(Painter.ellipse_points(Vector2(0, 2), 38, 15),
		Color(0.80, 0.65, 0.45, 0.75))
	draw_colored_polygon(Painter.ellipse_points(Vector2(0, -2), 24, 13),
		Color(0.40, 0.26, 0.18, 0.95))
	draw_circle(Vector2(0, -2), 8, Color(0.13, 0.10, 0.09, 0.9))


func _draw_mud() -> void:
	draw_colored_polygon(Painter.ellipse_points(Vector2(0, 0), 42, 18),
		Color(0.42, 0.27, 0.16, 0.55))
	draw_colored_polygon(Painter.ellipse_points(Vector2(-8, -2), 26, 11),
		Color(0.56, 0.38, 0.23, 0.75))
	draw_circle(Vector2(16, 2), 5, Color(0.35, 0.24, 0.15, 0.75))


func _draw_rabbit() -> void:
	draw_circle(Vector2(0, -24), 22, Color(0.98, 0.96, 0.91))
	draw_circle(Vector2(0, -24), 22, Color(0.55, 0.43, 0.36), false, 2.0)
	draw_colored_polygon(Painter.ellipse_points(Vector2(-11, -55), 7, 17),
		Color(0.98, 0.96, 0.91))
	draw_colored_polygon(Painter.ellipse_points(Vector2(11, -55), 7, 17),
		Color(0.98, 0.96, 0.91))
	draw_circle(Vector2(-8, -27), 2.4, Painter.INK)
	draw_circle(Vector2(8, -27), 2.4, Painter.INK)
	draw_circle(Vector2(0, -19), 2.2, Color(0.93, 0.55, 0.58))


func _draw_cat() -> void:
	draw_circle(Vector2(0, -24), 23, Color(0.96, 0.71, 0.39))
	draw_circle(Vector2(0, -24), 23, Color(0.50, 0.34, 0.20), false, 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20, -38), Vector2(-12, -60), Vector2(-2, -41)
	]), Color(0.96, 0.71, 0.39))
	draw_colored_polygon(PackedVector2Array([
		Vector2(20, -38), Vector2(12, -60), Vector2(2, -41)
	]), Color(0.96, 0.71, 0.39))
	draw_circle(Vector2(-8, -26), 2.2, Painter.INK)
	draw_circle(Vector2(8, -26), 2.2, Painter.INK)
	draw_line(Vector2(-7, -18), Vector2(0, -15), Painter.INK, 1.6, true)
	draw_line(Vector2(7, -18), Vector2(0, -15), Painter.INK, 1.6, true)


func _draw_customer() -> void:
	draw_circle(Vector2(0, -22), 22, body_color)
	draw_circle(Vector2(0, -22), 22, Color(0.50, 0.35, 0.25), false, 2.0)
	draw_circle(Vector2(-8, -25), 2.3, Painter.INK)
	draw_circle(Vector2(8, -25), 2.3, Painter.INK)
	draw_arc(Vector2(0, -16), 7, 0.15, PI - 0.15, 12, Painter.INK, 1.3, true)
