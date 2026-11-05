extends Node

var checks := 0
var failures := 0
var room: RestaurantInterior


func _ready() -> void:
	print("\n========== Restaurant Interior Test ==========")
	room = (load("res://tutorial/RestaurantInterior.tscn") as PackedScene).instantiate() as RestaurantInterior
	add_child(room)
	await _frames(10)
	_run()
	print("\n========== Restaurant Interior Test: %d checks, %d failed ==========" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _run() -> void:
	_check(room.COLS == 10 and room.ROWS == 7, "餐厅内部为 10×7 网格")
	_check(room.furniture.size() == 13, "厨房/桌椅家具共 13 件")
	var kinds := {}
	for piece in room.furniture:
		kinds[piece.kind] = true
	for required in ["mixer", "knife", "cutting_board", "sink", "shelf",
			"plate", "dishwasher", "table", "chair"]:
		_check(kinds.has(required), "包含家具：%s" % required)
	var mixer: RestaurantFurniture = _find("mixer")
	_check(mixer != null and mixer.cell == Vector2i(1, 1), "搅拌器初始在厨房区")
	_check(room._can_place(mixer, Vector2i(8, 1)), "搅拌器可以移动到空白格")
	room._move_to(mixer, Vector2i(8, 1))
	_check(mixer.cell == Vector2i(8, 1), "搅拌器移动后坐标更新")
	_check(not room._can_place(mixer, Vector2i(2, 3)), "不能与餐桌重叠")
	var table: RestaurantFurniture = _find("table")
	_check(table != null and table.footprint == Vector2i(2, 1), "餐桌为 2×1")
	room._move_to(mixer, Vector2i(1, 1))
	_check(room._can_place(mixer, Vector2i(1, 1)), "搅拌器可以回到原位")


func _find(kind: String) -> RestaurantFurniture:
	for piece in room.furniture:
		if piece.kind == kind:
			return piece
	return null


func _check(ok: bool, name: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("  [FAIL] ", name)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
