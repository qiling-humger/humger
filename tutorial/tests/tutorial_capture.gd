extends Node

var game: TutorialGame


func _ready() -> void:
	var world := "user://tutorial_capture_world.json"
	var state := "user://tutorial_capture_state.json"
	for path in [world, state]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var packed := load("res://tutorial/TutorialLevel.tscn") as PackedScene
	game = packed.instantiate() as TutorialGame
	game.save_path = world
	game.state_path = state
	add_child(game)
	await _frames(40)
	game.ui._toasts.clear()
	game.ui.queue_redraw()
	await _frames(20)
	print("START grid_visible=", game.terrain.is_grid_visible(),
		" overlap=", game.terrain.tile_overlap)
	await _shot("tutorial_start.png")

	game.inventory.add("wood", 30)
	game.inventory.add("stone", 20)
	game.inventory.add("grass", 12)
	game.player.position = game.snake_actor.position
	game._interact()
	game.shop_open = false
	game.player.position = game.grid.world_from_float(Vector2(8, 7))
	await _frames(10)
	game.ui._toasts.clear()
	game.ui.queue_redraw()
	game.toggle_build_mode()
	game.select_buildable(0)
	var center := game.grid.world_from_float(Vector2(8, 4.5))
	game.set_process(false)
	game.placement.update_preview(center)
	game.placement._process(0.0)
	await _frames(6)
	await _shot("tutorial_build.png")

	game.placement.try_place_at(center)
	game.exit_build_mode()
	game.terrain.set_build_mode(false)
	game.set_process(true)
	await _frames(20)
	game.ui._toasts.clear()
	game.ui.queue_redraw()
	await _frames(10)
	await _shot("tutorial_restaurant.png")
	for path in [world, state]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://tutorial/screenshots/" + name)
	print("CAPTURE ", name)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
