class_name VisualSamplePlaceable
extends IslandPlaceable
## 可放置物件的 Sprite 视觉层。占格、搬动和回滚仍由 IslandPlaceable 负责。

var _sprite: Sprite2D


func setup(id_value: String, definition: Dictionary, origin_value: Vector2i,
		grid_ref: IslandGrid, game_ref: Node) -> void:
	super.setup(id_value, definition, origin_value, grid_ref, game_ref)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	_update_sprite()


func _update_sprite() -> void:
	var key := str(def.get("id", ""))
	var texture := game.get_asset_texture(key) as Texture2D
	if texture == null:
		return
	_sprite.texture = texture
	var center := get_footprint_center() - position
	var pad: float = game.get_asset_base_pad(key)
	var display_scale: float = game.get_asset_scale(key)
	_sprite.scale = Vector2(display_scale, display_scale)
	_sprite.position = center + Vector2(
		-float(texture.get_width()) * display_scale * 0.5,
		-float(texture.get_height()) * display_scale + pad * display_scale)


func _draw() -> void:
	var center := get_footprint_center() - position
	Painter.shadow(self, center + Vector2(0, 2),
		28.0 * float(size.x), 8.0 * float(size.y),
		Color(0.14, 0.20, 0.12, 0.15))
