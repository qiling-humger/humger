class_name IslandWater
extends Node2D
## 地图外围海水。用缓慢移动的波纹和浅色高光营造轻松的海岛氛围。

const WATER_DEEP := Color(0.365, 0.706, 0.706)
const WATER_LIGHT := Color(0.506, 0.804, 0.784)
const FOAM := Color(0.925, 0.988, 0.957)

var _time := 0.0


func _ready() -> void:
	z_index = -20
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-2400, -1600, 4800, 3200), WATER_DEEP)
	# 大面积的柔和色带，让海面不只是一块死色。
	for i in range(7):
		var y := -1100.0 + float(i) * 330.0 + sin(_time * 0.18 + float(i)) * 10.0
		draw_rect(Rect2(-2300, y, 4600, 160), Color(0.58, 0.84, 0.81, 0.12))

	# 岛屿下方的浅水阴影。
	draw_colored_polygon(
		Painter.ellipse_points(Vector2(0, 54), 690, 348, 48),
		Color(0.20, 0.48, 0.46, 0.10)
	)
	draw_colored_polygon(
		Painter.ellipse_points(Vector2(0, 30), 590, 300, 48),
		Color(0.75, 0.94, 0.88, 0.08)
	)

	# 稀疏波纹，避免满屏噪声。
	for i in range(20):
		var px := -1420.0 + float(i) * 149.0 + sin(_time * 0.25 + float(i) * 1.7) * 9.0
		for j in range(6):
			var py := -640.0 + float(j) * 224.0 + float((i * 7 + j * 13) % 31)
			var r := 10.0 + float((i + j) % 4) * 3.0
			var alpha := 0.10 + 0.04 * sin(_time * 0.8 + float(i + j))
			draw_arc(Vector2(px, py), r, PI * 0.12, PI * 0.88, 12,
				Color(FOAM, alpha), 2.0, true)

	# 小亮点，像水面反光。
	for k in range(18):
		var hx := -1200.0 + float((k * 137) % 2400)
		var hy := -700.0 + float((k * 223) % 1400)
		var twinkle := 0.12 + 0.08 * sin(_time * 1.2 + float(k))
		draw_circle(Vector2(hx, hy), 2.2 + float(k % 3), Color(1, 1, 1, twinkle))
