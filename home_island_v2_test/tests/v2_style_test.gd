extends Node
## Independent checks for the V2 style-test scene and build-mode baseline.

var game: HomeIslandGame
var checks := 0
var failures := 0


func _ready() -> void:
	print("\n========== V2 Style Test ==========")
	var packed := load("res://home_island_v2_test/HomeIslandV2Test.tscn") as PackedScene
	game = packed.instantiate() as HomeIslandGame
	add_child(game)
	await _frames(15)
	await _run()
	print("\n========== V2 Style Test: %d checks, %d failed ==========" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _run() -> void:
	_check(game != null, "V2 test scene instantiates")
	_check(game.grid.columns == 16 and game.grid.rows == 12, "16x12 island")
	_check(game.grid.get_land_count() >= 90, "land count")
	_check(game.terrain.land_tile_count == game.grid.get_land_count(), "one ground sprite per land cell")
	_check(not game.terrain.is_grid_visible(), "normal grid hidden")
	_check(game.resource_nodes.size() == 7, "tree/rock resource count")
	_check(game.placed_objects.size() == 1, "one initial V2 table")
	var table: VisualSamplePlaceable = game.placed_objects[0]
	_check(table.size == Vector2i(2, 1), "table is 2x1")
	_check(game.get_asset_texture("tree") != null, "V2 tree texture loaded")
	_check(game.get_asset_texture("rock") != null, "V2 rock texture loaded")
	_check(game.get_asset_texture("table") != null, "V2 table texture loaded")
	_check(game.asset_catalog.get("terrain", {}).get("grass", "").contains("art_style_v2_test"),
		"V2 grass texture path")
	var sprite: AnimatedSprite2D = game.player.get_node("AnimatedSprite2D")
	_check(sprite.sprite_frames.has_animation("walk_down")
		and sprite.sprite_frames.get_frame_count("walk_down") == 4,
		"rabbit animation system retained")

	game.toggle_build_mode()
	_check(game.placement.build_mode, "build mode enters")
	_check(game.terrain.is_grid_visible(), "grid appears in build mode")
	game.select_buildable(0)
	var target := Vector2i(11, 8)
	var center := game.grid.world_from_float(Vector2(target.x + 0.5, target.y))
	game.placement.update_preview(center)
	_check(game.placement.preview_valid, "V2 table preview valid")
	var before := game.placed_objects.size()
	_check(game.placement.try_place_at(center), "V2 table places")
	_check(game.placed_objects.size() == before + 1, "table count increases")
	game.exit_build_mode()
	_check(not game.terrain.is_grid_visible(), "grid hides after build")


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


func _check(condition: bool, title: String) -> void:
	checks += 1
	if condition:
		print("  [PASS] ", title)
	else:
		failures += 1
		print("  [FAIL] ", title)
