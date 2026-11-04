class_name VisualSamplePlaceable
extends IslandPlaceable
## 可放置物件的 Sprite 视觉层。占格、搬动、旋转和回滚仍由 IslandPlaceable 负责。
##
## All placement visuals use one rule: the lowest opaque pixel sits on the
## footprint's ground anchor. The pivot is the footprint center, so 1x1, 2x1
## and rotated 1x2 objects rotate around the same bottom-center point.

var _pivot: Node2D
var _sprite: Sprite2D
var _bottom_pad := 0.0


func setup(id_value: String, definition: Dictionary, origin_value: Vector2i,
		grid_ref: IslandGrid, game_ref: Node, rotation_value := 0) -> void:
	super.setup(id_value, definition, origin_value, grid_ref, game_ref, rotation_value)
	_pivot = Node2D.new()
	_pivot.name = "AnchorPivot"
	add_child(_pivot)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_pivot.add_child(_sprite)
	_update_sprite()


func _visual_transform_changed() -> void:
	_update_sprite()


func _update_sprite() -> void:
	if _pivot == null or _sprite == null:
		return
	var key := str(def.get("id", ""))
	var texture := game.get_asset_texture_for_rotation(key, rotation_quarters) as Texture2D
	if texture == null:
		return
	var center := get_footprint_center() - position
	var display_scale: float = game.get_asset_scale(key)
	_bottom_pad = VisualAnchor.bottom_pad(texture, game.get_asset_base_pad(key))
	var alternate: bool = posmod(rotation_quarters, 2) == 1 and game.has_rotated_texture(key)
	var non_square := base_size.x != base_size.y
	var visual_rotation := 0.0
	if non_square and posmod(rotation_quarters, 2) == 1 and not alternate:
		visual_rotation = float(rotation_quarters) * PI * 0.5
	_pivot.position = center
	_pivot.rotation = visual_rotation
	_sprite.texture = texture
	_sprite.scale = Vector2(display_scale, display_scale)
	_sprite.rotation = 0.0
	# Bottom-center of the opaque pixels is at the pivot (0, 0).
	_sprite.position = Vector2(
		-float(texture.get_width()) * display_scale * 0.5,
		-float(texture.get_height()) * display_scale + _bottom_pad * display_scale)


func _draw() -> void:
	var center := get_footprint_center() - position
	# Shadow follows the rotated footprint, but stays on the ground anchor.
	Painter.shadow(self, center + Vector2(0, 2),
		28.0 * float(size.x), 8.0 * float(size.y),
		Color(0.14, 0.20, 0.12, 0.15))
