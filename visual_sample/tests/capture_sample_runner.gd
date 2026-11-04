extends Node

var game: VisualSampleGame
var _saved := 0


func _ready() -> void:
	var packed := load("res://visual_sample/VisualSample.tscn") as PackedScene
	game = packed.instantiate() as VisualSampleGame
	add_child(game)
	await _frames(60)
	print("GRID_VISIBLE_NORMAL=", game.terrain.is_grid_visible())
	await _capture("01_sample.png")

	game.toggle_build_mode()
	game.select_buildable(1)
	game.set_process(false)
	var origin := _find_empty(Vector2i(2, 1))
	var world := game.grid.world_from_float(Vector2(origin.x + 0.5, origin.y))
	game.placement.update_preview(world)
	await _frames(6)
	await _capture("02_sample_build.png")

	game.exit_build_mode()
	game.set_process(true)
	await _frames(6)
	game.player.position = game.grid.cell_to_world(Vector2i(2, 4))
	await _frames(45)
	game._refresh_nearest()
	game.gather_nearest()
	game.gather_nearest()
	game.gather_nearest()
	await _frames(60)
	await _capture("03_sample_gather.png")
	get_tree().quit(0 if _saved >= 3 else 1)


func _find_empty(size: Vector2i) -> Vector2i:
	var center := Vector2(3.5, 3.5)
	var player_cell := game.grid.world_to_cell(game.player.position)
	var best := Vector2i(3, 2)
	var best_distance := 99999.0
	for y in range(1, game.grid.rows - size.y):
		for x in range(1, game.grid.columns - size.x):
			var origin := Vector2i(x, y)
			if not game.grid.can_place(origin, size):
				continue
			var blocks_player := false
			for cell in game.grid.footprint_cells(origin, size):
				if cell == player_cell:
					blocks_player = true
					break
			if blocks_player:
				continue
			var distance := Vector2(x, y).distance_squared_to(center)
			if distance < best_distance:
				best_distance = distance
				best = origin
	return best


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "res://visual_sample/screenshots/" + file_name
	if image.save_png(path) == OK:
		_saved += 1
		print("CAPTURE ", path)
	else:
		push_error("截图失败: " + path)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
