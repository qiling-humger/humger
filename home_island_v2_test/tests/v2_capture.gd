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
	await _shot("01_normal.png")

	game.toggle_build_mode()
	game.select_buildable(0)
	var target := Vector2i(11, 8)
	var center := game.grid.world_from_float(Vector2(target.x + 0.5, target.y))
	game.placement.update_preview(center)
	game.placement._process(0.0)
	game.set_process(false)
	game.placement.set_process(false)
	await _frames(4)
	await _shot("02_build.png")
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
