class_name Station
extends Node2D
## 所有交互设备的基类：靠近高亮、地面交互点、头顶分区牌、阻挡矩形。
## 具体设备继承并实现 _draw_station_art / get_prompt / interact。

@export var station_id := ""
@export var display_name := ""
@export var interaction_offset := Vector2(0, 76)
@export var interaction_radius := 132.0
@export var footprint := Vector2(170, 86)
@export var label_offset := Vector2(0, -150)
@export var show_label := true

var manager: Node
var highlighted := false
var anim_t := 0.0


func _ready() -> void:
	add_to_group("stations")
	if station_id == "grill":
		add_to_group("station_grill")
	set_process(true)
	queue_redraw()


func setup(manager_node: Node) -> void:
	manager = manager_node
	on_setup()
	queue_redraw()


func on_setup() -> void:
	pass


func _process(delta: float) -> void:
	anim_t += delta
	if highlighted or wants_animation():
		queue_redraw()


func wants_animation() -> bool:
	return false


func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()


func get_interaction_position() -> Vector2:
	return global_position + interaction_offset


func get_obstacle_rect() -> Rect2:
	return Rect2(global_position + footprint * -0.5, footprint).grow(18.0)


func get_click_rect() -> Rect2:
	# 世界里没有 CollisionShape，鼠标点击用一个覆盖设备本体的宽松矩形。
	# 顶部留出 170px，能点中柜台上的热狗、面包、酱瓶等高处展示物。
	var width := maxf(footprint.x, 96.0) + 40.0
	var height := footprint.y + 198.0
	return Rect2(global_position + Vector2(-width * 0.5, -170.0),
		Vector2(width, height))


func contains_click_point(point: Vector2) -> bool:
	return get_click_rect().has_point(point)


func get_prompt(_player: Player) -> Dictionary:
	return {"text": "查看 " + display_name, "enabled": true}


func interact(_player: Player) -> void:
	notify("这里暂时没有反应。")


func notify(text: String, color: Color = Painter.INK) -> void:
	if manager and manager.has_method("notify"):
		manager.notify(text, color)


func _draw() -> void:
	if highlighted:
		_draw_focus_ring()
	_draw_station_art()
	if show_label:
		_draw_label()
	if highlighted:
		_draw_key_hint()


func _draw_station_art() -> void:
	Painter.iso_box(self, Vector2.ZERO, footprint.x, footprint.y, 44,
		Painter.CREAM, Painter.MINT, Painter.TEAL)


func _draw_focus_ring() -> void:
	var pulse := 1.0 + sin(anim_t * 5.5) * 0.08
	var center := interaction_offset + Vector2(0, 4)
	var rx := 38.0 * pulse
	var ry := 17.0 * pulse
	var points := Painter.ellipse_points(center, rx, ry, 30)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, Color(0.31, 0.66, 0.56, 0.26), 7.0, true)
	draw_polyline(closed, Color(0.31, 0.66, 0.56, 0.82), 2.2, true)
	for i in range(4):
		var angle := TAU * float(i) / 4.0 + anim_t * 0.8
		var p := center + Vector2(cos(angle) * rx, sin(angle) * ry)
		draw_circle(p, 2.4, Painter.CORAL)


func _draw_label() -> void:
	if display_name.is_empty():
		return
	var font_size := 13
	var width := float(display_name.length()) * 13.0 + 26.0
	var rect := Rect2(label_offset + Vector2(-width * 0.5, -14), Vector2(width, 28))
	var fill := Color(1.0, 0.984, 0.949, 0.95)
	var border := Painter.INK if not highlighted else Painter.CORAL_DARK
	Painter.panel(self, rect, 10, fill, border, 2.0 if not highlighted else 2.6, true)
	Painter.draw_centered(self, display_name, label_offset + Vector2(0, 5), font_size, Painter.INK)
	# 小尾巴
	draw_colored_polygon(PackedVector2Array([
		label_offset + Vector2(-5, 14), label_offset + Vector2(5, 14), label_offset + Vector2(0, 21)
	]), fill)
	draw_line(label_offset + Vector2(-5, 14), label_offset + Vector2(0, 21), border, 1.5, true)
	draw_line(label_offset + Vector2(5, 14), label_offset + Vector2(0, 21), border, 1.5, true)


func _draw_key_hint() -> void:
	var center := interaction_offset + Vector2(0, -24)
	Painter.keycap(self, center, "E", 26.0)
