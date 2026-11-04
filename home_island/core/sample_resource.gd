class_name VisualSampleResource
extends IslandResourceNode
## 资源节点的 Sprite 版视觉层。采集次数、占格和碰撞仍由 IslandResourceNode 负责。

var _sprite: Sprite2D


func setup(id_value: String, type_value: String, cell_value: Vector2i,
		def: Dictionary, grid: IslandGrid, game_ref: Node) -> void:
	super.setup(id_value, type_value, cell_value, def, grid, game_ref)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	_apply_texture(type_value, game.get_asset_base_pad(type_value))


func _apply_texture(key: String, base_pad: float) -> void:
	var texture := game.get_asset_texture(key) as Texture2D
	if texture == null:
		return
	var display_scale: float = game.get_asset_scale(key)
	_sprite.texture = texture
	_sprite.scale = Vector2(display_scale, display_scale)
	_sprite.position = Vector2(
		-float(texture.get_width()) * display_scale * 0.5,
		-float(texture.get_height()) * display_scale + base_pad * display_scale)
	_sprite.modulate = Color.WHITE
	_sprite.visible = true


func _show_depleted_visual() -> void:
	if node_type == "tree" and game.has_asset("stump"):
		_apply_texture("stump", game.get_asset_base_pad("stump"))
	else:
		_sprite.modulate = Color(1, 1, 1, 0.42)
		var base_scale: float = game.get_asset_scale(node_type)
		var shrink := base_scale * 0.80
		_sprite.scale = Vector2(shrink, shrink)
		var tex_h := float(_sprite.texture.get_height()) if _sprite.texture else 0.0
		var pad: float = game.get_asset_base_pad(node_type)
		_sprite.position.y = -tex_h * shrink + pad * shrink


func restore_uses(value: int) -> void:
	uses_left = maxi(0, value)
	if uses_left <= 0:
		_show_depleted_visual()
	else:
		_apply_texture(node_type, game.get_asset_base_pad(node_type))


func gather() -> Dictionary:
	var info := super.gather()
	if not info.is_empty() and is_depleted():
		_show_depleted_visual()
	return info


func _draw() -> void:
	var shadow_rx := 30.0
	if node_type == "tree":
		shadow_rx = 34.0
	elif node_type == "bush":
		shadow_rx = 22.0
	elif node_type == "rock":
		shadow_rx = 24.0
	Painter.shadow(self, Vector2(0, 2), shadow_rx, 8.0,
		Color(0.14, 0.22, 0.13, 0.16))
	if highlighted:
		var points := Painter.ellipse_points(Vector2(0, 2), 29, 11, 30)
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, Color(0.99, 0.97, 0.77, 0.9), 2.4, true)
