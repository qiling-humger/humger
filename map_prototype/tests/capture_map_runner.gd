extends Node
## 地图原型截图：正常地图、建造模式 3×3 预览。

var game: MapGame
var _saved := 0


func _ready() -> void:
	var packed := load("res://map_prototype/MapPrototype.tscn") as PackedScene
	game = packed.instantiate() as MapGame
	add_child(game)
	await _frames(45)
	await _capture("01_map.png")

	game.toggle_build_mode()
	game.select_buildable(3)
	game.set_process(false)
	game.placement.update_preview(game.grid.cell_to_world(Vector2i(11, 7)))
	await _frames(5)
	await _capture("02_build_3x3.png")

	game.placement.try_place_at(game.grid.cell_to_world(Vector2i(11, 7)))
	game.exit_build_mode()
	await _frames(10)
	await _capture("03_restaurant_placed.png")

	# 采集一点资源，验证顶部资源栏和 +N 反馈。
	game.set_process(true)
	game.player.position = game.grid.cell_to_world(Vector2i(8, 7))
	await _frames(45)
	game._refresh_nearest()
	game.gather_nearest()
	game.gather_nearest()
	game.gather_nearest()
	await _frames(80)
	await _capture("04_gathered.png")
	get_tree().quit(0 if _saved >= 4 else 1)


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "res://map_prototype/screenshots/" + file_name
	var err := image.save_png(path)
	if err == OK:
		_saved += 1
		print("CAPTURE ", path)
	else:
		push_error("截图失败: " + path)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
