extends Node
## Captures the three Home Island V1 review screenshots from the real scene.

var game: HomeIslandGame
var out_dir := "res://home_island/screenshots"


func _ready() -> void:
	var packed := load("res://home_island/HomeIsland.tscn") as PackedScene
	game = packed.instantiate() as HomeIslandGame
	game.persistence_enabled = false
	add_child(game)
	await _frames(300)
	await _shot("01_home_stage02.png")

	game.toggle_build_mode()
	game.select_buildable(1)
	var target := Vector2i(12, 9)
	if not game.grid.can_place(target, Vector2i(2, 1)):
		target = _find_empty(Vector2i(2, 1))
	var center := game.grid.world_from_float(Vector2(target.x + 0.5, target.y))
	game.placement.update_preview(center)
	game.placement._process(0.0)
	game.set_process(false)
	game.placement.set_process(false)
	await _frames(4)
	await _shot("02_build_stage02.png")

	game.set_process(true)
	game.placement.set_process(true)
	game.exit_build_mode()
	var tree: VisualSampleResource = null
	for node in game.resource_nodes:
		if node.node_id == "home_tree_2":
			tree = node
			break
	if tree == null:
		for node in game.resource_nodes:
			if node.node_type == "tree":
				tree = node
				break
	if tree:
		_move_next_to(tree)
		game._refresh_nearest()
		game.gather_nearest()
		game.gather_nearest()
		game.gather_nearest()
	await _frames(30)
	await _shot("03_gather_stage02.png")
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := out_dir + "/" + name
	image.save_png(path)
	print("CAPTURE ", path)


func _find_empty(size: Vector2i) -> Vector2i:
	var center := Vector2(7.5, 6.0)
	var best := Vector2i(6, 6)
	var best_distance := 99999.0
	var player_cell := game.grid.world_to_cell(game.player.position)
	for y in range(0, game.grid.rows - size.y + 1):
		for x in range(0, game.grid.columns - size.x + 1):
			var origin := Vector2i(x, y)
			if not game.grid.can_place(origin, size):
				continue
			if player_cell in game.grid.footprint_cells(origin, size):
				continue
			var distance := Vector2(x, y).distance_squared_to(center)
			if distance < best_distance:
				best_distance = distance
				best = origin
	return best


func _move_next_to(node: VisualSampleResource) -> void:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var cell: Vector2i = node.cell + d
		if game.grid.is_walkable_cell(cell):
			game.player.position = game.grid.cell_to_world(cell)
			return


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
