class_name VisualSamplePlacement
extends MapPlacementController
## 在现有放置逻辑上增加半透明 Sprite 预览，其余占格/搬动/回滚完全复用父类。

var _ghost: Sprite2D
var _ghost_pivot: Node2D


func setup(game_ref: Node, grid_ref: IslandGrid, entities_ref: Node2D, defs: Array) -> void:
	super.setup(game_ref, grid_ref, entities_ref, defs)
	_ghost_pivot = Node2D.new()
	_ghost_pivot.name = "GhostAnchor"
	add_child(_ghost_pivot)
	_ghost = Sprite2D.new()
	_ghost.name = "Ghost"
	_ghost.centered = false
	_ghost.z_index = 2
	_ghost.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_ghost.visible = false
	_ghost_pivot.add_child(_ghost)
	set_process(true)


func _process(_delta: float) -> void:
	if not has_preview:
		_ghost.visible = false
		return
	var key := ""
	if drag_object != null and is_instance_valid(drag_object):
		key = str(drag_object.def.get("id", ""))
	else:
		key = str(current_def().get("id", ""))
	var rotation := drag_object.rotation_quarters if drag_object != null else preview_rotation
	var texture := game.get_asset_texture_for_rotation(key, rotation) as Texture2D
	if texture == null:
		_ghost.visible = false
		return
	var cells := grid.footprint_cells(preview_origin, preview_size)
	var center := Vector2.ZERO
	for cell in cells:
		center += grid.cell_to_world(cell)
	center /= float(cells.size())
	var pad := VisualAnchor.bottom_pad(texture, game.get_asset_base_pad(key))
	var display_scale: float = game.get_asset_scale(key)
	var alternate: bool = posmod(rotation, 2) == 1 and game.has_rotated_texture(key)
	var base_size: Vector2i = drag_object.base_size if drag_object != null \
		else Vector2i(int(current_def().get("width", 1)), int(current_def().get("height", 1)))
	var visual_rotation := 0.0
	if base_size.x != base_size.y and posmod(rotation, 2) == 1 and not alternate:
		visual_rotation = float(rotation) * PI * 0.5
	_ghost_pivot.position = center
	_ghost_pivot.rotation = visual_rotation
	_ghost.texture = texture
	_ghost.scale = Vector2(display_scale, display_scale)
	_ghost.rotation = 0.0
	_ghost.position = Vector2(
		-float(texture.get_width()) * display_scale * 0.5,
		-float(texture.get_height()) * display_scale + pad * display_scale)
	_ghost.modulate = Color(1, 1, 1, 0.55) if preview_valid else Color(1, 0.62, 0.60, 0.45)
	_ghost.visible = true


func _draw() -> void:
	if not has_preview:
		return
	var color := Color(0.290, 0.729, 0.435, 0.28) if preview_valid \
		else Color(0.851, 0.325, 0.310, 0.28)
	var line_color := Color(0.196, 0.612, 0.349, 0.92) if preview_valid \
		else Color(0.760, 0.235, 0.220, 0.92)
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
	var label := "%d×%d" % [preview_size.x, preview_size.y]
	Painter.draw_centered(self, label, center + Vector2(0, -52), 12,
		Color(0.15, 0.42, 0.23) if preview_valid else Color(0.62, 0.18, 0.16), true)
