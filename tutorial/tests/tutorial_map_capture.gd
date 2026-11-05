extends Node


func _ready() -> void:
	var packed := load("res://tutorial/TutorialLevel.tscn") as PackedScene
	var game := packed.instantiate() as TutorialGame
	game.persistence_enabled = false
	add_child(game)
	await _frames(25)
	game.player.position = game.grid.world_from_float(Vector2(11.5, 9.5))
	game.player.camera.zoom = Vector2(0.62, 0.62)
	game.player.camera.position = Vector2(0, -20)
	game.player.camera.reset_smoothing()
	await _frames(20)
	game.ui._toasts.clear()
	game.ui.queue_redraw()
	await _frames(10)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://tutorial/screenshots/map_24x20_v2.png")
	print("CAPTURE map_24x20_v2")
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
