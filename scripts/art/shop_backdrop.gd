extends Node2D
## 热狗店静态背景：两面 45° 斜墙、奶油色菱形地板、等候区、入口垫、墙面装饰。
## 所有家具由 Entities 层的设备节点绘制，这里只负责空间基底。

const LEFT := Vector2(80, 385)
const TOP := Vector2(640, 120)
const RIGHT := Vector2(1200, 385)
const BOTTOM := Vector2(640, 650)
const WALL_H := 128.0
const FLOOR_U := RIGHT - TOP
const FLOOR_V := LEFT - TOP

const BG_TOP := Color(0.988, 0.953, 0.902)
const BG_BOTTOM := Color(0.945, 0.865, 0.760)
const WALL_LEFT := Color(0.952, 0.855, 0.733)
const WALL_RIGHT := Color(0.992, 0.921, 0.815)
const WALL_TOP_TRIM := Color(0.835, 0.690, 0.545)
const BASE_TRIM := Color(0.800, 0.659, 0.522)
const FLOOR_A := Color(0.988, 0.937, 0.855)
const FLOOR_B := Color(0.969, 0.898, 0.796)
const FLOOR_LINE := Color(0.878, 0.780, 0.660, 0.42)
const FLOOR_EDGE := Color(0.663, 0.510, 0.392)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	_draw_room_backdrop()
	_draw_walls()
	_draw_floor()
	_draw_rugs()
	_draw_wall_decor()
	_draw_storage_crates()
	_draw_entrance()
	_draw_floor_labels()


func _draw_room_backdrop() -> void:
	# 柔和的暖色渐变，避免大片纯色。
	var steps := 24
	for i in range(steps):
		var t := float(i) / float(steps)
		var color := BG_TOP.lerp(BG_BOTTOM, t)
		draw_rect(Rect2(0, 720.0 * t, 1280, 720.0 / steps + 1.0), color)
	# 远景店铺剪影，增加景深。
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 330), Vector2(150, 330), Vector2(150, 300), Vector2(270, 300),
		Vector2(270, 340), Vector2(430, 340), Vector2(430, 305), Vector2(530, 305),
		Vector2(530, 360), Vector2(0, 360),
	]), Color(0.778, 0.648, 0.545, 0.10))
	# 顶部柔光。
	draw_circle(Vector2(640, 40), 330, Color(1.0, 0.965, 0.840, 0.18))


func _draw_walls() -> void:
	var left_base := PackedVector2Array([LEFT, TOP, TOP - Vector2(0, WALL_H), LEFT - Vector2(0, WALL_H)])
	var right_base := PackedVector2Array([TOP, RIGHT, RIGHT - Vector2(0, WALL_H), TOP - Vector2(0, WALL_H)])
	draw_colored_polygon(left_base, WALL_LEFT)
	draw_polyline(_closed(left_base), Painter.INK, 3.0, true)
	draw_colored_polygon(right_base, WALL_RIGHT)
	draw_polyline(_closed(right_base), Painter.INK, 3.0, true)

	# 墙纸细条。
	for i in range(1, 14):
		var t := float(i) / 14.0
		var left_bottom := LEFT.lerp(TOP, t)
		draw_line(left_bottom, left_bottom - Vector2(0, WALL_H), Color(0.72, 0.58, 0.45, 0.10), 2.0, true)
		var right_bottom := TOP.lerp(RIGHT, t)
		draw_line(right_bottom, right_bottom - Vector2(0, WALL_H), Color(0.72, 0.58, 0.45, 0.08), 2.0, true)

	# 上沿木条与踢脚线。
	draw_line(TOP, TOP - Vector2(0, WALL_H), Painter.INK, 4.0, true)
	draw_line(LEFT - Vector2(0, WALL_H), TOP - Vector2(0, WALL_H), WALL_TOP_TRIM, 10.0, true)
	draw_line(TOP - Vector2(0, WALL_H), RIGHT - Vector2(0, WALL_H), WALL_TOP_TRIM, 10.0, true)
	draw_line(LEFT, TOP, BASE_TRIM, 14.0, true)
	draw_line(TOP, RIGHT, BASE_TRIM, 14.0, true)
	draw_line(LEFT, TOP, Painter.INK_SOFT, 2.0, true)
	draw_line(TOP, RIGHT, Painter.INK_SOFT, 2.0, true)

	# 墙角阴影。
	draw_colored_polygon(PackedVector2Array([
		TOP + Vector2(-30, 0), TOP + Vector2(0, 26), TOP + Vector2(-6, 0),
	]), Color(0.42, 0.30, 0.22, 0.12))

	# 左墙窗户。
	_draw_wall_window(LEFT, TOP, 0.16, 0.37, 62.0, 55.0)
	# 右墙窗户。
	_draw_wall_window(TOP, RIGHT, 0.61, 0.80, 64.0, 58.0)

	# 右墙店招。
	_draw_hanging_sign()

	# 左墙小挂钟。
	_draw_wall_clock(Vector2(268, 258), 30.0)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result


func _wall_point(a: Vector2, b: Vector2, t: float, up: float) -> Vector2:
	return a.lerp(b, t) - Vector2(0, up)


func _draw_wall_window(a: Vector2, b: Vector2, t0: float, t1: float, up: float, height: float) -> void:
	var p00 := _wall_point(a, b, t0, up)
	var p10 := _wall_point(a, b, t1, up)
	var p11 := _wall_point(a, b, t1, up + height)
	var p01 := _wall_point(a, b, t0, up + height)
	var frame := PackedVector2Array([p00, p10, p11, p01])
	# 外框阴影
	var shadow_poly := PackedVector2Array([p00 + Vector2(5, 5), p10 + Vector2(5, 5), p11 + Vector2(5, 5), p01 + Vector2(5, 5)])
	draw_colored_polygon(shadow_poly, Color(0.4, 0.28, 0.2, 0.10))
	draw_colored_polygon(frame, Color(0.78, 0.905, 0.908))
	draw_polyline(_closed(frame), Painter.INK, 3.0, true)
	# 玻璃
	var inset_u := (p10 - p00) * 0.09
	var inset_v := (p01 - p00) * 0.10
	var inner := PackedVector2Array([
		p00 + inset_u + inset_v,
		p10 - inset_u + inset_v,
		p11 - inset_u - inset_v,
		p01 + inset_u - inset_v,
	])
	draw_colored_polygon(inner, Color(0.800, 0.914, 0.925))
	# 窗外淡淡的远山和太阳，让玻璃不是死色。
	var mid := p00.lerp(p11, 0.5)
	draw_circle(mid + Vector2(12, -6), 14, Color(1.0, 0.918, 0.690, 0.8))
	draw_colored_polygon(PackedVector2Array([
		inner[0], inner[1], mid + Vector2(28, 4), mid + Vector2(-18, 8)
	]), Color(0.663, 0.835, 0.733, 0.45))
	# 窗棂
	draw_line(p00.lerp(p10, 0.5), p01.lerp(p11, 0.5), Painter.CREAM, 4.0, true)
	draw_line(p00.lerp(p01, 0.5), p10.lerp(p11, 0.5), Painter.CREAM, 4.0, true)
	# 高光
	draw_line(inner[0] + Vector2(10, 8), inner[0] + Vector2(38, -8), Color(1, 1, 1, 0.45), 4.0, true)
	# 窗台
	var sill := PackedVector2Array([
		p00 + Vector2(0, 4), p10 + Vector2(0, 4), p10 + Vector2(0, 12), p00 + Vector2(0, 12)
	])
	draw_colored_polygon(sill, Painter.CREAM)
	draw_polyline(_closed(sill), Painter.INK, 2.0, true)


func _draw_hanging_sign() -> void:
	var origin := Vector2(892, 242)
	draw_set_transform(origin, 0.42, Vector2(1.0, 0.92))
	# 吊绳
	draw_line(Vector2(-74, -82), Vector2(-62, -50), Painter.BROWN_DARK, 3.0, true)
	draw_line(Vector2(74, -82), Vector2(62, -50), Painter.BROWN_DARK, 3.0, true)
	Painter.panel(self, Rect2(-100, -48, 200, 64), 12, Color(1.0, 0.955, 0.850), Painter.INK, 2.6, true)
	draw_line(Vector2(-86, -38), Vector2(86, -38), Color(0.95, 0.75, 0.52, 0.6), 3.0, true)
	Painter.draw_centered(self, "热狗小站", Vector2(0, -4), 25, Painter.INK, true)
	Painter.draw_food_icon(self, "hotdog", Vector2(0, 19), 0.58, "perfect", {"ketchup": true, "mustard": false})
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_wall_clock(center: Vector2, radius: float) -> void:
	# 墙是斜面，用椭圆时钟近似挂在左墙上的透视。
	draw_set_transform(center, -0.26, Vector2(1.0, 0.82))
	draw_circle(Vector2.ZERO, radius, Painter.CREAM)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Painter.INK, 3.0, true)
	draw_arc(Vector2.ZERO, radius - 6, 0.0, TAU, 36, Painter.PEACH, 2.0, true)
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var a := Vector2(cos(angle), sin(angle)) * (radius - 11)
		var b := Vector2(cos(angle), sin(angle)) * (radius - 7)
		draw_line(a, b, Painter.INK_SOFT, 1.8, true)
	draw_line(Vector2.ZERO, Vector2(0, -radius * 0.48), Painter.INK, 2.6, true)
	draw_line(Vector2.ZERO, Vector2(radius * 0.35, radius * 0.18), Painter.INK, 2.2, true)
	draw_circle(Vector2.ZERO, 3.1, Painter.CORAL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_wall_shelf(center: Vector2, angle: float) -> void:
	draw_set_transform(center, angle, Vector2(1.0, 0.85))
	# 两层木架
	for row in range(2):
		var y := -10.0 + row * 35.0
		Painter.panel(self, Rect2(-80, y, 160, 12), 4, Color(0.80, 0.60, 0.40), Painter.INK, 2.0, true)
		# 罐子
		for i in range(3):
			var x := -54.0 + i * 54.0
			var jar_color: Color = [Painter.MINT, Painter.BUTTER, Painter.PEACH][i]
			Painter.panel(self, Rect2(x - 13, y - 24, 26, 24), 7, jar_color, Painter.INK, 1.8, false)
			draw_rect(Rect2(x - 8, y - 21, 16, 5), Color(1, 1, 1, 0.35), true)
			draw_line(Vector2(x - 13, y - 8), Vector2(x + 13, y - 8), Color(1, 1, 1, 0.25), 1.5, true)
	# 小盆栽
	Painter.panel(self, Rect2(52, -30, 22, 16), 4, Painter.CORAL, Painter.INK, 1.6, false)
	draw_circle(Vector2(63, -38), 10, Painter.LETTUCE)
	draw_circle(Vector2(55, -43), 8, Painter.MINT)
	draw_circle(Vector2(70, -44), 7, Painter.LETTUCE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_floor() -> void:
	# 地板底色
	Painter.diamond(self, (TOP + BOTTOM) * 0.5, 1120, 530, Color(0.95, 0.87, 0.77))
	var cells := 12
	for u in range(cells):
		for v in range(cells):
			var p0 := TOP + FLOOR_U * (float(u) / cells) + FLOOR_V * (float(v) / cells)
			var p1 := TOP + FLOOR_U * (float(u + 1) / cells) + FLOOR_V * (float(v) / cells)
			var p2 := TOP + FLOOR_U * (float(u + 1) / cells) + FLOOR_V * (float(v + 1) / cells)
			var p3 := TOP + FLOOR_U * (float(u) / cells) + FLOOR_V * (float(v + 1) / cells)
			var cell_color := FLOOR_A if (u + v) % 2 == 0 else FLOOR_B
			draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), cell_color)
			draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), FLOOR_LINE, 1.1, true)
	# 外沿和地脚阴影
	var floor_outline := PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT])
	draw_polyline(_closed(floor_outline), FLOOR_EDGE, 4.0, true)
	draw_polyline(PackedVector2Array([TOP, RIGHT, BOTTOM, LEFT]), Color(1, 1, 1, 0.22), 1.4, true)
	# 墙根柔和阴影
	draw_colored_polygon(PackedVector2Array([
		LEFT, TOP, TOP + Vector2(0, 18), LEFT + Vector2(0, 18)
	]), Color(0.35, 0.24, 0.18, 0.10))
	draw_colored_polygon(PackedVector2Array([
		TOP, RIGHT, RIGHT + Vector2(0, 18), TOP + Vector2(0, 18)
	]), Color(0.35, 0.24, 0.18, 0.08))


func _draw_rugs() -> void:
	# 等候区地毯：与地板同一透视的菱形。
	var rug_center := Vector2(958, 462)
	Painter.diamond(self, rug_center, 220, 112, Color(0.816, 0.914, 0.855), Painter.INK, 2.4)
	Painter.diamond(self, rug_center, 194, 98, Color(0.890, 0.955, 0.905), Color.TRANSPARENT)
	Painter.diamond(self, rug_center, 166, 84, Color(0.816, 0.914, 0.855), Color.TRANSPARENT)
	var queue_count: int = GameData.config().get("queue_slots", []).size()
	for i in range(queue_count):
		var point := _queue_slot(i)
		# 等待位小圆垫（透视压扁）
		var mat_points := Painter.ellipse_points(point + Vector2(0, 2), 31, 13)
		draw_colored_polygon(mat_points, Color(1, 1, 1, 0.40))
		var mat_outline := mat_points.duplicate()
		mat_outline.append(mat_points[0])
		draw_polyline(mat_outline, Color(0.55, 0.72, 0.63, 0.40), 1.5, true)
		# 小爪印
		draw_circle(point + Vector2(-6, 4), 3.0, Color(0.55, 0.72, 0.63, 0.42))
		draw_circle(point + Vector2(6, 4), 3.0, Color(0.55, 0.72, 0.63, 0.42))
		draw_circle(point + Vector2(0, -2), 4.0, Color(0.55, 0.72, 0.63, 0.42))

	# 入口脚垫
	var mat_center := Vector2(640, 589)
	Painter.diamond(self, mat_center, 174, 76, Color(0.921, 0.690, 0.549), Painter.INK, 2.4)
	Painter.diamond(self, mat_center, 148, 62, Color(0.996, 0.839, 0.671), Color.TRANSPARENT)
	for i in range(3):
		var y := -14.0 + i * 14.0
		draw_line(mat_center + Vector2(-46, y), mat_center + Vector2(46, y), Color(0.80, 0.53, 0.39, 0.35), 2.0, true)


func _queue_slot(index: int) -> Vector2:
	var slots: Array = GameData.section("customers").get("queue_slots", [])
	# 兼容：配置里队列位置在 customers 之外时也找得到。
	if slots.is_empty():
		slots = GameData.config().get("queue_slots", [])
	if index < slots.size():
		return Vector2(float(slots[index].get("x", 950)), float(slots[index].get("y", 460)))
	return Vector2(950 + index * 30, 460 + index * 24)


func _draw_wall_decor() -> void:
	# 左墙菜单板，带透视旋转。
	draw_set_transform(Vector2(420, 266), -0.438, Vector2(1.0, 0.9))
	Painter.panel(self, Rect2(-72, -55, 144, 104), 10, Color(0.286, 0.400, 0.337), Painter.INK, 2.6, true)
	Painter.draw_centered(self, "今日菜单", Vector2(0, -29), 17, Color(1.0, 0.956, 0.854), true)
	draw_line(Vector2(-54, -16), Vector2(54, -16), Color(0.98, 0.90, 0.76, 0.55), 1.5, true)
	Painter.draw_text(self, "经典热狗", Vector2(6, 12), 11, Color(1, 0.97, 0.9), false, HORIZONTAL_ALIGNMENT_LEFT, 80)
	Painter.draw_text(self, "¥22", Vector2(6, 27), 10, Color(1.0, 0.84, 0.48), true, HORIZONTAL_ALIGNMENT_LEFT, 80)
	# 最后画图标：draw_food_icon 会重置画布变换。
	Painter.draw_food_icon(self, "hotdog", Vector2(-27, 13), 0.55, "perfect", {"ketchup": true, "mustard": false})
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_storage_crates() -> void:
	# 左后角的食材储存堆头：木箱、麻袋与手写小牌，补足“食材储存区”的空间语义。
	Painter.shadow(self, Vector2(171, 382), 78, 17, Color(0.2, 0.13, 0.09, 0.13))
	Painter.iso_box(self, Vector2(164, 368), 82, 44, 26, Color(0.859, 0.678, 0.471),
		Color(0.655, 0.447, 0.271), Color(0.545, 0.357, 0.220))
	# 箱板纹理
	draw_line(Vector2(132, 352), Vector2(196, 374), Color(0.36, 0.22, 0.13, 0.35), 1.5, true)
	draw_line(Vector2(132, 361), Vector2(196, 383), Color(0.36, 0.22, 0.13, 0.28), 1.5, true)
	# 上层小箱
	Painter.iso_box(self, Vector2(151, 334), 58, 32, 20, Color(0.902, 0.749, 0.545),
		Color(0.729, 0.518, 0.325), Color(0.612, 0.420, 0.267))
	draw_line(Vector2(133, 322), Vector2(169, 335), Color(0.36, 0.22, 0.13, 0.35), 1.3, true)
	# 麻袋
	draw_colored_polygon(Painter.ellipse_points(Vector2(215, 356), 22, 29), Color(0.878, 0.773, 0.596))
	draw_polyline(_closed(Painter.ellipse_points(Vector2(215, 356), 22, 29)), Painter.INK, 2.0, true)
	draw_colored_polygon(Painter.ellipse_points(Vector2(215, 331), 13, 6), Color(0.945, 0.847, 0.667))
	draw_arc(Vector2(215, 331), 13, 0.0, PI, 12, Painter.INK, 1.6, true)
	draw_line(Vector2(215, 330), Vector2(215, 321), Painter.BROWN_DARK, 2.2, true)
	draw_line(Vector2(208, 327), Vector2(222, 327), Painter.BROWN_DARK, 2.0, true)
	# 小木牌
	Painter.panel(self, Rect2(134, 381, 74, 22), 6, Color(1.0, 0.918, 0.769), Painter.INK, 1.6, false)
	Painter.draw_text(self, "食材储存", Vector2(139, 396), 10, Painter.BROWN, true,
		HORIZONTAL_ALIGNMENT_LEFT, 66)
	# 墙上手写牌
	draw_set_transform(Vector2(179, 300), -0.438, Vector2(1.0, 0.9))
	Painter.panel(self, Rect2(-46, -18, 92, 36), 7, Color(0.925, 0.965, 0.906), Painter.INK, 1.8, true)
	Painter.draw_centered(self, "新鲜食材", Vector2(0, 6), 12, Painter.TEAL, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_entrance() -> void:
	# 前侧入口：地垫上方一个轻巧的门框提示牌。
	var center := Vector2(640, 612)
	Painter.draw_centered(self, "入 口", center + Vector2(0, 30), 14, Color(0.57, 0.42, 0.31, 0.72), true)
	# 两串小彩旗
	var flag_colors := [Painter.CORAL, Painter.BUTTER, Painter.MINT, Painter.PEACH]
	for side in [-1.0, 1.0]:
		var origin := Vector2(640 + side * 128, 642)
		for i in range(4):
			var p := origin + Vector2(side * i * 18, -i * 4)
			var tri := PackedVector2Array([p, p + Vector2(side * 14, -2), p + Vector2(side * 7, 12)])
			draw_colored_polygon(tri, flag_colors[i])
			draw_polyline(_closed(tri), Painter.INK_SOFT, 1.2, true)


func _draw_floor_labels() -> void:
	Painter.draw_centered(self, "等候区", Vector2(958, 505), 12, Color(0.38, 0.49, 0.42, 0.65), true)
	# 淡淡的厨房分区标记
	Painter.draw_centered(self, "厨 房 区", Vector2(650, 470), 11, Color(0.55, 0.41, 0.30, 0.35), true)
