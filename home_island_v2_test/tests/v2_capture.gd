extends Node
## Windowed screenshots for the V2 style test.

var game: HomeIslandGame
var out_dir := "res://home_island_v2_test/screenshots"


func _ready() -> void:
	var packed := load("res://home_island_v2_test/HomeIslandV2Test.tscn") as PackedScene
	game = packed.instantiate() as HomeIslandGame
	add_child(game)
	await _frames(30)
	game.ui._toasts.clear()
	game.ui.queue_redraw()
	await _frames(30)
	await _shot("05_normal_grounded.png")

	game.toggle_build_mode()
	game.select_buildable(0)
	var target := Vector2i(7, 8)
	var center := game.grid.world_from_float(Vector2(target.x, target.y + 0.5))
	# Freeze the game's mouse-follow preview so the screenshot frame is deterministic.
	game.set_process(false)
	game.placement.update_preview(center)
	game.placement.rotate_preview(1)
	game.placement.update_preview(center)
	game.placement._process(0.0)
	await _frames(4)
	print("BUILD ghost=", game.placement.get("_ghost").visible,
		" preview=", game.placement.preview_valid,
		" origin=", game.placement.preview_origin,
		" grid=", game.terrain.is_grid_visible())
	await _shot("06_build_rotated.png")

	game.placement.try_place_at(center)
	game.exit_build_mode()
	game.terrain.set_build_mode(false)
	var grid_overlay := game.terrain.get("_grid_overlay") as Node2D
	if grid_overlay:
		grid_overlay.visible = false
		grid_overlay.queue_redraw()
	game.placement.has_preview = false
	game.placement._process(0.0)
	await _frames(20)
	print("NORMAL grid=", game.terrain.is_grid_visible(),
		" objects=", game.placed_objects.size())
	await _shot("07_placed_rotated.png")
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := out_dir + "/" + name
	image.save_png(path)
	print("CAPTURE ", path)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
