class_name IslandResourceNode
extends Node2D
## 地图资源节点：小树、草丛、落叶堆、石块。
## 采集次数用剩余次数表示；耗尽后保留可见残迹，不再进入交互。

var node_id := ""
var node_type := ""
var display_name := ""
var resource_id := ""
var amount := 1
var uses_left := 1
var blocking := false
var verb := "采集"
var cell := Vector2i.ZERO
var highlighted := false
var game: Node

var _time := 0.0
var _pulse := 0.0
var _pop := 0.0


func setup(id_value: String, type_value: String, cell_value: Vector2i,
		def: Dictionary, grid: IslandGrid, game_ref: Node) -> void:
	node_id = id_value
	node_type = type_value
	cell = cell_value
	display_name = str(def.get("name", "资源"))
	resource_id = str(def.get("resource", "wood"))
	amount = int(def.get("amount", 1))
	uses_left = int(def.get("uses", 1))
	blocking = bool(def.get("blocking", false))
	verb = str(def.get("verb", "采集"))
	game = game_ref
	position = grid.cell_to_world(cell)
	grid.reserve([cell], node_id, blocking)
	z_as_relative = true
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _pop > 0.0:
		_pop = maxf(0.0, _pop - delta * 3.4)
	if highlighted or _pop > 0.0:
		queue_redraw()


func is_depleted() -> bool:
	return uses_left <= 0


func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()


func gather() -> Dictionary:
	if uses_left <= 0:
		return {}
	uses_left -= 1
	_pulse = 1.0
	_pop = 1.0
	queue_redraw()
	return {
		"resource": resource_id,
		"amount": amount,
		"remaining": uses_left,
		"name": display_name,
	}


func prompt_data() -> Dictionary:
	return {
		"name": display_name,
		"verb": verb,
		"resource": resource_id,
		"amount": amount,
		"remaining": uses_left,
	}


func _draw() -> void:
	if _pop > 0.0:
		_pulse += 0.08
	var shadow_alpha := 0.16 if not is_depleted() else 0.08
	Painter.shadow(self, Vector2(0, 2), 23, 8, Color(0.16, 0.24, 0.15, shadow_alpha))
	if highlighted:
		_draw_highlight()
	match node_type:
		"tree":
			_draw_tree()
		"bush":
			_draw_bush()
		"leaf_pile":
			_draw_leaf_pile()
		"rock":
			_draw_rock()


func _draw_highlight() -> void:
	var glow := 1.5 + sin(_time * 5.0) * 1.2
	var points := Painter.ellipse_points(Vector2(0, 1), 27 + glow, 10 + glow * 0.5, 28)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, Color(0.98, 0.98, 0.84, 0.85), 2.2, true)


func _draw_tree() -> void:
	if is_depleted():
		_draw_stump()
		return
	# 树干
	var trunk := PackedVector2Array([
		Vector2(-7, 1), Vector2(7, 1), Vector2(5, -31), Vector2(-5, -31)
	])
	Painter.outline_polygon(self, trunk, Color(0.510, 0.337, 0.235), Painter.INK, 1.8)
	draw_line(Vector2(-1, -3), Vector2(0, -27), Color(0.373, 0.243, 0.180, 0.65), 1.5, true)
	# 树冠，三层圆团叠出蓬松感。
	var puffs := [
		{"p": Vector2(-19, -45), "r": 22.0, "c": Color(0.318, 0.596, 0.310)},
		{"p": Vector2(18, -48), "r": 20.0, "c": Color(0.318, 0.596, 0.310)},
		{"p": Vector2(0, -61), "r": 25.0, "c": Color(0.365, 0.659, 0.353)},
		{"p": Vector2(-12, -70), "r": 18.0, "c": Color(0.427, 0.706, 0.357)},
		{"p": Vector2(12, -70), "r": 17.0, "c": Color(0.427, 0.706, 0.357)},
	]
	for puff in puffs:
		var p: Vector2 = puff["p"]
		var r: float = puff["r"]
		draw_circle(p, r, puff["c"])
		draw_arc(p, r, 0, TAU, 24, Painter.INK, 1.7, true)
	# 左上高光
	draw_circle(Vector2(-16, -62), 8.0, Color(0.620, 0.831, 0.463, 0.55))
	# 小果子
	draw_circle(Vector2(-7, -49), 2.2, Painter.CORAL)
	draw_circle(Vector2(14, -38), 2.0, Painter.BUTTER)
	draw_circle(Vector2(-24, -31), 1.8, Painter.CORAL)


func _draw_stump() -> void:
	var stump := PackedVector2Array([
		Vector2(-9, 2), Vector2(9, 2), Vector2(7, -15), Vector2(-7, -15)
	])
	Painter.outline_polygon(self, stump, Color(0.510, 0.337, 0.235), Painter.INK, 1.7)
	draw_set_transform(Vector2(0, -15), 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 8.0, Color(0.741, 0.565, 0.373))
	draw_arc(Vector2.ZERO, 8.0, 0, TAU, 20, Painter.INK, 1.5, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_line(Vector2(-2, 1), Vector2(-3, -8), Color(0.373, 0.243, 0.180, 0.6), 1.4, true)


func _draw_bush() -> void:
	if is_depleted():
		for i in range(3):
			var x := -8.0 + float(i) * 7.0
			draw_line(Vector2(x, 2), Vector2(x + 1, -5), Color(0.42, 0.59, 0.31, 0.55), 1.6, true)
		return
	var centers := [Vector2(-12, -7), Vector2(0, -13), Vector2(13, -7)]
	for c in centers:
		draw_circle(c, 12.0, Color(0.396, 0.655, 0.337))
		draw_arc(c, 12.0, 0, TAU, 22, Painter.INK, 1.6, true)
	draw_circle(Vector2(-8, -20), 7.0, Color(0.514, 0.749, 0.384))
	draw_circle(Vector2(6, -19), 6.0, Color(0.514, 0.749, 0.384))
	# 草叶
	for i in range(4):
		var base := Vector2(-15 + i * 10, 1)
		var tip := base + Vector2(-3 + (i % 2) * 6, -16 - (i % 3) * 3)
		draw_line(base, tip, Color(0.294, 0.525, 0.263), 2.0, true)
	# 小花
	draw_circle(Vector2(-7, -19), 2.2, Painter.BUTTER)
	draw_circle(Vector2(8, -22), 2.0, Painter.CREAM)


func _draw_leaf_pile() -> void:
	if is_depleted():
		draw_circle(Vector2(-8, 2), 5.0, Color(0.627, 0.435, 0.247, 0.5))
		draw_circle(Vector2(7, 4), 4.0, Color(0.741, 0.565, 0.310, 0.45))
		return
	var leaf_colors := [Color(0.831, 0.506, 0.267), Color(0.914, 0.671, 0.302),
		Color(0.667, 0.365, 0.235), Color(0.898, 0.749, 0.353)]
	var positions := [Vector2(-14, -2), Vector2(2, -7), Vector2(13, -1),
		Vector2(-3, 1), Vector2(8, 4)]
	for i in range(positions.size()):
		var p: Vector2 = positions[i]
		var angle := -0.5 + float(i) * 0.7
		var leaf := PackedVector2Array([
			p + Vector2(-9, 0).rotated(angle),
			p + Vector2(0, -5).rotated(angle),
			p + Vector2(9, 0).rotated(angle),
			p + Vector2(0, 5).rotated(angle),
		])
		Painter.outline_polygon(self, leaf, leaf_colors[i % leaf_colors.size()],
			Color(0.42, 0.29, 0.19), 1.2)
		draw_line(p + Vector2(-7, 0).rotated(angle), p + Vector2(6, 0).rotated(angle),
			Color(0.42, 0.29, 0.19, 0.55), 1.0, true)
	# 一小片被风吹起的叶子
	draw_set_transform(Vector2(16, -16), -0.5, Vector2.ONE)
	Painter.outline_polygon(self, PackedVector2Array([
		Vector2(-5, 0), Vector2(0, -3), Vector2(5, 0), Vector2(0, 3)
	]), Color(0.91, 0.72, 0.36), Color(0.42, 0.29, 0.19), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_rock() -> void:
	if is_depleted():
		draw_circle(Vector2(-9, 2), 5.5, Color(0.55, 0.56, 0.53))
		draw_circle(Vector2(5, 4), 4.0, Color(0.63, 0.64, 0.60))
		return
	var rock := PackedVector2Array([
		Vector2(-21, 1), Vector2(-15, -15), Vector2(-2, -21),
		Vector2(15, -13), Vector2(22, 0), Vector2(9, 6), Vector2(-9, 6)
	])
	Painter.outline_polygon(self, rock, Color(0.573, 0.588, 0.565), Painter.INK, 1.9)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -11), Vector2(-5, -17), Vector2(3, -16), Vector2(-4, -7)
	]), Color(0.706, 0.722, 0.682, 0.75))
	draw_line(Vector2(4, -13), Vector2(12, -1), Color(0.42, 0.44, 0.41, 0.4), 1.4, true)
	draw_circle(Vector2(15, 2), 3.2, Color(0.45, 0.50, 0.42, 0.55))
