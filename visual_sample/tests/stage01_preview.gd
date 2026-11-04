extends Node
## Stage 01 preview only. Loads the accepted logical sample scene, then swaps
## textures on runtime nodes to the new staging assets. No saved scene or game
## logic is modified.

var game
var stage := "res://assets/art_staging/stage_01_base"


func _ready() -> void:
	var packed := load("res://visual_sample/VisualSample.tscn") as PackedScene
	game = packed.instantiate()
	add_child(game)
	await _frames(30)
	await _apply_stage_assets()
	await _frames(300)
	if OS.get_cmdline_user_args().has("--capture"):
		await _capture()
		get_tree().quit(0)


func _apply_stage_assets() -> void:
	# Keep the existing logic but replace the old visual terrain with one large
	# AI-painted grass patch.
	var old_tiles = game.terrain.get("_tile_root")
	var old_base = game.terrain.get("_base_root")
	var old_coast = game.terrain.get("_coast_overlay")
	if old_tiles: old_tiles.visible = false
	if old_base: old_base.visible = false
	if old_coast: old_coast.visible = false

	var grass_tex := load(stage + "/environment/transparent_png/grass_stage01.png") as Texture2D
	if grass_tex:
		var grass := Sprite2D.new()
		grass.texture = grass_tex
		grass.centered = false
		grass.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var scale := 0.60
		var center: Vector2 = game.grid.cell_to_world(Vector2i(3, 4))
		grass.scale = Vector2(scale, scale)
		grass.position = center - Vector2(
			grass_tex.get_width() * scale * 0.5,
			grass_tex.get_height() * scale * 0.5)
		game.terrain.add_child(grass)

	game.player.camera.zoom = Vector2(1.0, 1.0)
	game.player.camera.reset_smoothing()

	for object in game.placed_objects:
		object.visible = false

	for node in game.resource_nodes:
		var sprite := node.get("_sprite") as Sprite2D
		if sprite == null:
			continue
		var key: String = node.node_type
		var path := stage + "/environment/transparent_png/" + key + "_stage01.png"
		var texture := load(path) as Texture2D
		if texture == null:
			continue
		var target_h := 260.0 if key == "tree" else (135.0 if key == "bush" else 110.0)
		var scale := target_h / float(texture.get_height())
		sprite.texture = texture
		sprite.scale = Vector2(scale, scale)
		sprite.position = Vector2(-texture.get_width() * scale * 0.5,
			-texture.get_height() * scale + 5.0)

	var old_player_sprite := game.player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if old_player_sprite:
		old_player_sprite.visible = false
	var rabbit_tex := load(stage + "/rabbit/transparent_png/rabbit_stage01.png") as Texture2D
	if rabbit_tex:
		var rabbit := Sprite2D.new()
		rabbit.texture = rabbit_tex
		rabbit.centered = false
		rabbit.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var scale := 200.0 / float(rabbit_tex.get_height())
		rabbit.scale = Vector2(scale, scale)
		rabbit.position = Vector2(-rabbit_tex.get_width() * scale * 0.5,
			-rabbit_tex.get_height() * scale + 6.0)
		game.player.add_child(rabbit)


func _capture() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := stage + "/preview/stage01_game.png"
	image.save_png(path)
	print("CAPTURE ", path)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
