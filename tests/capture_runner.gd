extends Node
## 实机渲染截图工具（非验收逻辑用）。
## 用法：Godot 非 headless 运行 tests/CaptureRunner.tscn

var manager: GameManager


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var packed: PackedScene = load("res://scenes/Main.tscn")
	manager = packed.instantiate() as GameManager
	add_child(manager)
	await _frames(12)
	await _capture("01_title.png")

	manager.start_shift()
	await _frames(8)
	manager.customer_queue.clear_all()
	manager.customer_queue.spawn_customer_now("classic", "ketchup")
	manager.customer_queue.spawn_customer_now("double", "both")
	manager.player.position = Vector2(885, 470)
	manager.player.set_item(GameData.make_hotdog(
		[GameData.make_cooked_sausage("perfect", 9.6)],
		{"ketchup": true, "mustard": false}
	))
	manager.assembly_station.board_sausages = [GameData.make_cooked_sausage("just_cooked", 6.8)]
	manager.cooking_system.set_slot_time(0, 9.6)
	manager.cooking_system.set_slot_time(1, 6.8)
	manager.cooking_system.set_slot_time(2, 13.6)
	manager.economy_system.coins = 86
	manager.economy_system.satisfaction = 92
	manager.economy_system.stats["served"] = 3
	manager.economy_system.stats["perfect"] = 2
	manager.economy_system.stats["quality_points"] = 7
	manager.economy_system.stats["quality_count"] = 2
	manager.time_left = 132.0
	await get_tree().create_timer(1.15).timeout
	manager.ui.hud.clear_toasts()
	await _frames(10)
	await _capture("02_gameplay.png")

	manager.toggle_pause()
	await _frames(8)
	await _capture("03_pause.png")

	manager.resume_game()
	await _frames(2)
	manager.end_shift("shift_end")
	await _frames(8)
	await _capture("04_results.png")

	manager.customer_queue.stop()
	get_tree().paused = false
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://screenshots/" + file_name)
	var error := image.save_png(path)
	print("CAPTURE ", path, " -> ", error)
