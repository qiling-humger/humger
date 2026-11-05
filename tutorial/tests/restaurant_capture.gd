extends Node


func _ready() -> void:
	var scene := (load("res://tutorial/RestaurantInterior.tscn") as PackedScene).instantiate()
	add_child(scene)
	await _frames(30)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://tutorial/screenshots/restaurant_interior.png")
	print("CAPTURE restaurant_interior")
	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
