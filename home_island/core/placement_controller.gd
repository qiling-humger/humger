class_name MapPlacementController
extends Node2D
## 建造放置与搬动控制器。
## 建造模式：B 进入，1-4/鼠标选择物件，左键放置，Esc 退出。
## 搬动模式：非建造模式左键按住已放置物件，拖动到新格，松开确认。

var game: Node
var grid: IslandGrid
var entities: Node2D
var definitions: Array = []

var build_mode := false
var selected_index := 0
var has_preview := false
var preview_origin := Vector2i.ZERO
var preview_size := Vector2i.ONE
var preview_valid := false

var drag_object: IslandPlaceable
var drag_start_origin := Vector2i.ZERO


func setup(game_ref: Node, grid_ref: IslandGrid, entities_ref: Node2D, defs: Array) -> void:
	game = game_ref
	grid = grid_ref
	entities = entities_ref
	definitions = defs
	z_index = 80
	set_process(false)
	queue_redraw()


func current_def() -> Dictionary:
	if definitions.is_empty():
		return {}
	return definitions[clampi(selected_index, 0, definitions.size() - 1)]


func current_size() -> Vector2i:
	var def := current_def()
	return Vector2i(int(def.get("width", 1)), int(def.get("height", 1)))


func enter_build_mode() -> void:
	if build_mode:
		return
	if drag_object != null:
		cancel_drag()
	build_mode = true
	has_preview = true
	selected_index = clampi(selected_index, 0, maxi(0, definitions.size() - 1))
	if game.island_map:
		game.island_map.set_build_mode(true)
	queue_redraw()


func exit_build_mode() -> void:
	build_mode = false
	has_preview = false
	if game.island_map:
		game.island_map.set_build_mode(false)
	queue_redraw()


func select_buildable(index: int) -> void:
	if definitions.is_empty():
		return
	selected_index = clampi(index, 0, definitions.size() - 1)
	has_preview = true
	queue_redraw()


func _origin_for_cursor(world_pos: Vector2, size: Vector2i) -> Vector2i:
	var precise := grid.world_to_cell_float(world_pos)
	var origin_f := Vector2(
		precise.x - (float(size.x) - 1.0) * 0.5,
		precise.y - (float(size.y) - 1.0) * 0.5
	)
	return Vector2i(roundi(origin_f.x), roundi(origin_f.y))


func update_preview(world_pos: Vector2) -> void:
	if drag_object != null and is_instance_valid(drag_object):
		preview_size = drag_object.size
		preview_origin = _origin_for_cursor(world_pos, preview_size)
		preview_valid = grid.can_place(preview_origin, preview_size, drag_object.object_id) \
			and not _player_in_footprint(preview_origin, preview_size)
		has_preview = true
		queue_redraw()
		return
	if build_mode:
		preview_size = current_size()
		preview_origin = _origin_for_cursor(world_pos, preview_size)
		preview_valid = grid.can_place(preview_origin, preview_size) \
			and not _player_in_footprint(preview_origin, preview_size)
		has_preview = true
		queue_redraw()
		return
	has_preview = false
	queue_redraw()


func _player_in_footprint(origin: Vector2i, size: Vector2i) -> bool:
	if game.player == null:
		return false
	var player_cell := grid.world_to_cell(game.player.position)
	for cell in grid.footprint_cells(origin, size):
		if cell == player_cell:
			return true
	return false


func try_place_at(world_pos: Vector2) -> bool:
	if not build_mode:
		return false
	update_preview(world_pos)
	if not preview_valid:
		game.notify("这里放不下：水面、边界、已有物件或玩家脚下。", Painter.CORAL_DARK)
		return false
	var def := current_def()
	var placed: IslandPlaceable = game.spawn_placeable(def, preview_origin)
	if placed == null:
		game.notify("这里放不下。", Painter.CORAL_DARK)
		return false
	game.notify("已放置 %s（%d×%d）" % [str(def.get("name", "物件")),
		int(def.get("width", 1)), int(def.get("height", 1))], Painter.TEAL)
	return true


func begin_drag(world_pos: Vector2) -> bool:
	if build_mode or drag_object != null:
		return false
	var cell := grid.world_to_cell(world_pos)
	var found: IslandPlaceable = game.get_movable_at_cell(cell)
	if found == null:
		return false
	drag_object = found
	drag_start_origin = found.origin
	grid.release(found.object_id)
	found.set_dragging(true)
	update_preview(world_pos)
	game.notify("拖动到空白格，松开确认；Esc 取消。", Painter.BROWN)
	return true


func update_drag(world_pos: Vector2) -> void:
	if drag_object == null:
		return
	update_preview(world_pos)


func finish_drag(world_pos: Vector2) -> bool:
	if drag_object == null or not is_instance_valid(drag_object):
		return false
	update_preview(world_pos)
	var object := drag_object
	if preview_valid:
		object.set_origin(preview_origin)
		grid.reserve(object.get_cells(), object.object_id, object.blocking)
		object.set_dragging(false)
		game.notify("%s 已搬到新位置。" % str(object.def.get("name", "物件")), Painter.TEAL)
	else:
		object.set_origin(drag_start_origin)
		grid.reserve(object.get_cells(), object.object_id, object.blocking)
		object.set_dragging(false)
		game.notify("这里放不下，%s 已放回原处。" % str(object.def.get("name", "物件")), Painter.CORAL_DARK)
	drag_object = null
	has_preview = false
	preview_valid = false
	queue_redraw()
	return true


func cancel_drag() -> void:
	if drag_object == null or not is_instance_valid(drag_object):
		return
	drag_object.set_origin(drag_start_origin)
	grid.reserve(drag_object.get_cells(), drag_object.object_id, drag_object.blocking)
	drag_object.set_dragging(false)
	drag_object = null
	has_preview = false
	preview_valid = false
	queue_redraw()


func cancel() -> bool:
	if drag_object != null:
		cancel_drag()
		game.notify("已取消搬动。", Painter.BROWN)
		return true
	if build_mode:
		game.exit_build_mode()
		return true
	return false


func is_dragging() -> bool:
	return drag_object != null


func _draw() -> void:
	if not has_preview:
		return
	var color := Color(0.290, 0.729, 0.435, 0.34) if preview_valid \
		else Color(0.851, 0.325, 0.310, 0.34)
	var line_color := Color(0.196, 0.612, 0.349, 0.95) if preview_valid \
		else Color(0.760, 0.235, 0.220, 0.95)
	var cells := grid.footprint_cells(preview_origin, preview_size)
	for cell in cells:
		var points := grid.get_diamond(cell, 1.2)
		draw_colored_polygon(points, color)
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, line_color, 2.1, true)

	var center_sum := Vector2.ZERO
	for cell in cells:
		center_sum += grid.cell_to_world(cell)
	var center := center_sum / float(cells.size())
	var def_color := Color.from_string(str(current_def().get("color", "#C58A55")),
		Color(0.78, 0.58, 0.38))
	var ghost_color := def_color
	ghost_color.a = 0.52
	Painter.iso_box(self, center + Vector2(0, 12), 52.0 + float(preview_size.x - 1) * 22.0,
		26.0 + float(preview_size.y - 1) * 12.0, 24.0,
		ghost_color, Color(ghost_color.r * 0.9, ghost_color.g * 0.9, ghost_color.b * 0.9, 0.5),
		Color(ghost_color.r * 0.8, ghost_color.g * 0.8, ghost_color.b * 0.8, 0.5),
		line_color, 2.0, false)
	var label := "%d×%d" % [preview_size.x, preview_size.y]
	if preview_valid:
		Painter.draw_centered(self, label, center + Vector2(0, -46), 12,
			Color(0.15, 0.42, 0.23), true)
	else:
		Painter.draw_centered(self, label, center + Vector2(0, -46), 12,
			Color(0.62, 0.18, 0.16), true)
