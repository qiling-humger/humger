extends Node
## Headless logic pass for the five-day tutorial. Real interaction is tested
## separately by the tutorial input/capture scenes.

var game: TutorialGame
var checks := 0
var failures := 0
const TEST_WORLD := "user://tutorial_test_world.json"
const TEST_STATE := "user://tutorial_test_state.json"


func _ready() -> void:
	print("\n========== Tutorial Logic Test ==========")
	_remove(TEST_WORLD)
	_remove(TEST_STATE)
	game = (load("res://tutorial/TutorialLevel.tscn") as PackedScene).instantiate() as TutorialGame
	game.save_path = TEST_WORLD
	game.state_path = TEST_STATE
	add_child(game)
	await _frames(12)
	await _run()
	for path in [TEST_WORLD, TEST_STATE]:
		_remove(path)
	print("\n========== Tutorial Logic Test: %d checks, %d failed ==========" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _run() -> void:
	_check(game.day == 1, "新手关从第 1 天开始")
	_check(game.objective_text.contains("蛇商"), "第 1 天先引导找蛇商")
	game.inventory.add("wood", 30)
	game.inventory.add("stone", 20)
	game.inventory.add("grass", 12)
	game.player.position = game.snake_actor.position
	_check(game._interact(), "E 与蛇商交互")
	_check(game.snake_met and game.has_carrot == 1, "蛇商送免费胡萝卜")
	game.shop_open = false

	var restaurant_def: Dictionary = game.find_def("restaurant")
	var restaurant: VisualSamplePlaceable = game.spawn_placeable(
		restaurant_def, Vector2i(7, 4), 0)
	_check(restaurant != null, "餐厅建成")
	_check(game.restaurant_built and game.customer_actor != null, "餐厅开业后顾客出现")
	_check(game.inventory.get_count("wood") == 22, "餐厅扣除木材")

	game.player.position = restaurant.get_footprint_center()
	_check(game._interact(), "餐厅 E 做汤")
	_check(game.held_dish == "胡萝卜浓汤", "做出胡萝卜浓汤")
	game.player.position = game.customer_actor.position
	_check(game._interact(), "第一笔订单交付")
	_check(game.wallet == 18 and game.first_sale, "第一笔收入 18 金币")
	game.player.position = game.burrow_actor.position
	game._sleep()
	_check(game.day == 2 and game.customer_actor != null, "睡觉进入第 2 天")

	# Day 2: buy carrot, cook and serve the rabbit.
	game.player.position = game.snake_actor.position
	game._interact()
	game._buy_carrot()
	game.shop_open = false
	_check(game.wallet == 12 and game.has_carrot == 1, "向蛇商购买胡萝卜")
	game.player.position = game.restaurant_object.get_footprint_center()
	game._interact()
	game.player.position = game.customer_actor.position
	game._interact()
	_check(game.wallet == 36 and game.rabbit_meat == 1, "第 2 天兔子订单 + 兔肉")
	game.player.position = game.burrow_actor.position
	game._sleep()
	_check(game.day == 3 and game.customer_actor != null, "进入第 3 天")

	# Day 3: hire/assign waiter, cook with rabbit meat, employee delivers.
	game.player.position = game.snake_actor.position
	game._interact()
	game.shop_open = false
	_check(game.employee_hired and game.employee_actor != null, "蛇商介绍员工")
	game.player.position = game.employee_actor.position
	game._interact()
	_check(game.employee_assigned, "员工分配到服务员")
	game.player.position = game.restaurant_object.get_footprint_center()
	game._interact()
	game._interact()
	await get_tree().create_timer(3.5).timeout
	print("  [DETAIL] employee=", game.employee_busy, " dish_counter=", game.dish_on_counter,
		" active=", game.active_order, " customer=", game.customer_actor != null,
		" emp=", game.employee_actor != null, " wallet=", game.wallet,
		" day_sale=", game.day_sale, " state=", game.employee_actor.state_text if game.employee_actor else "none")
	_check(game.day_sale and game.wallet == 66, "阿水自动送餐并结算")
	game.carrot_hunts = 2
	game.player.position = game.burrow_actor.position
	game._sleep()
	_check(game.day == 4 and game.big_carrot_active, "第 4 天大胡萝卜事件触发")
	game.mud = 10
	game.water_count = 6
	game.player.position = game.big_carrot_actor.position
	print("  [DETAIL] big=", game.big_carrot_active, " actor=", game.big_carrot_actor != null,
		" mud=", game.mud, " water=", game.water_count,
		" player=", game.player.position, " carrot=", game.big_carrot_actor.position if game.big_carrot_actor else "none")
	game._interact()
	print("  [DETAIL] after resolve=", game.big_carrot_resolved, " active=", game.big_carrot_active)
	_check(game.big_carrot_resolved and not game.big_carrot_active,
		"泥土和水解决大胡萝卜事件")

	# Day 4: enough materials, event resolved, sleep.
	_check(game._has_boat_materials(), "第 4 天造船材料足够")
	game.player.position = game.burrow_actor.position
	game._sleep()
	_check(game.day == 5, "进入第 5 天")

	# Day 5: build boat and finish.
	var boat_def: Dictionary = game.find_def("boat")
	var boat_origin := _find_empty(Vector2i(3, 2))
	_check(boat_origin.x >= 0, "找到船坞放置点")
	var boat: VisualSamplePlaceable = game.spawn_placeable(boat_def, boat_origin, 0)
	_check(boat != null and game.boat_built, "小船建成")
	game.player.position = boat.get_footprint_center()
	game._interact()
	_check(game.completed, "登船完成新手关")


func _find_empty(size: Vector2i) -> Vector2i:
	for y in range(0, game.grid.rows):
		for x in range(0, game.grid.columns):
			var origin := Vector2i(x, y)
			if game.grid.can_place(origin, size):
				return origin
	return Vector2i(-1, -1)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, title: String) -> void:
	checks += 1
	if condition:
		print("  [PASS] ", title)
	else:
		failures += 1
		print("  [FAIL] ", title)
