class_name TutorialGame
extends HomeIslandGame
## Five-day tutorial controller built on the existing island/build systems.
## All actors here are intentionally simple placeholders; final art is out of scope.

const STATE_PATH := "user://tutorial_state.json"
const MUD_CELL := Vector2i(4, 10)
const WATER_CELL := Vector2i(14, 10)

var state_path := STATE_PATH

@onready var hud: TutorialHUD = $TutorialHUD/HUD

var day := 1
var wallet := 0
var snake_met := false
var has_carrot := 0
var rabbit_meat := 0
var cat_food := 0
var mud := 0
var water_count := 0
var held_dish := ""
var dish_on_counter := false
var restaurant_built := false
var restaurant_object: VisualSamplePlaceable
var boat_object: VisualSamplePlaceable
var boat_built := false
var first_sale := false
var day_sale := false
var day_income := 0
var orders_completed := 0
var employee_hired := false
var employee_assigned := false
var employee_busy := false
var carrot_hunts := 0
var big_carrot_active := false
var big_carrot_resolved := false
var shop_open := false
var completed := false
var post_meal_carrot := false
var _loading := false
var _hint_timer := 0.0

var snake_actor: TutorialActor
var burrow_actor: TutorialActor
var customer_actor: TutorialActor
var employee_actor: TutorialActor
var big_carrot_actor: TutorialActor
var wild_carrot_actor: TutorialActor
var active_order := ""
var active_customer_kind := ""
var employee_home := Vector2.ZERO


func _ready() -> void:
	super._ready()
	player.camera.zoom = Vector2(1.26, 1.26)
	player.camera.position = Vector2(0, -30)
	player.camera.reset_smoothing()
	terrain.set_build_mode(false)
	# Tutorial uses a clean flat ground plane; per-cell grass edges are a
	# placeholder artifact and read as a grid even when the build grid is hidden.
	if terrain._tile_root:
		terrain._tile_root.visible = false
	_setup_markers()
	hud.setup(self)
	if FileAccess.file_exists(save_path) and FileAccess.file_exists(state_path):
		load_game(save_path)
	else:
		_start_day(1, true)
	ui.add_toast("WASD 移动 · E 交互 · B 建造 · 跟着左侧目标走。", Painter.BROWN)


func _welcome_toast_text() -> String:
	return ""


func _process(delta: float) -> void:
	super._process(delta)
	_hint_timer += delta
	_refresh_objective()


func _setup_markers() -> void:
	snake_actor = _make_actor("snake", "蛇商人", Color(0.45, 0.70, 0.44),
		grid.cell_to_world(Vector2i(12, 5)))
	snake_actor.scale = Vector2(1.2, 1.2)
	burrow_actor = _make_actor("burrow", "兔窝", Color(0.72, 0.54, 0.34),
		grid.cell_to_world(Vector2i(7, 9)))


func _make_actor(kind: String, label: String, color: Color, pos: Vector2) -> TutorialActor:
	var actor := TutorialActor.new()
	actor.setup(kind, label, color)
	actor.position = pos
	entities.add_child(actor)
	return actor


func _start_day(new_day: int, fresh := false) -> void:
	day = new_day
	day_sale = false
	day_income = 0
	held_dish = ""
	dish_on_counter = false
	shop_open = false
	post_meal_carrot = false
	_clear_actor(customer_actor)
	customer_actor = null
	_clear_actor(wild_carrot_actor)
	wild_carrot_actor = null
	big_carrot_active = false
	big_carrot_resolved = false
	if fresh:
		first_sale = false
	_restore_resources()
	_apply_day_build_defs()
	if restaurant_built:
		restaurant_object = _find_restaurant()
	if day >= 2 and restaurant_built:
		_spawn_day_customer()
	if day == 3 and employee_hired:
		_spawn_employee()
	if day == 4 and carrot_hunts >= 2:
		_spawn_big_carrot()
	_refresh_objective()
	save_game()
	ui.add_toast("第 %d 天开始。" % day, Painter.BROWN)


func _restore_resources() -> void:
	for node in resource_nodes:
		if not is_instance_valid(node):
			continue
		if node.node_type == "bush":
			node.restore_uses(2)
		else:
			node.restore_uses(3)


func _apply_day_build_defs() -> void:
	var wanted := "boat" if day >= 5 else "restaurant"
	var filtered: Array = []
	for def_value in config.get("placeables", []):
		if str(def_value.get("id", "")) == wanted:
			filtered.append(def_value)
	placement.definitions = filtered
	placement.selected_index = 0


func _spawn_day_customer() -> void:
	if not restaurant_built or customer_actor != null:
		return
	var kind := ""
	var order := ""
	match day:
		2:
			kind = "rabbit_customer"
			order = "胡萝卜浓汤"
		3:
			kind = "cat_customer"
			order = "兔肉料理 / 猫粮"
		_:
			return
	_spawn_customer(kind, order)


func _spawn_customer(kind: String, order: String) -> void:
	if restaurant_object == null:
		return
	var pos := restaurant_object.get_footprint_center() + Vector2(0, 54)
	customer_actor = _make_actor(kind, "顾客", Color(0.92, 0.68, 0.40), pos)
	customer_actor.order_text = order
	active_order = order
	active_customer_kind = kind
	post_meal_carrot = false
	ui.add_toast("顾客来了：%s" % order, Painter.BROWN)


func _on_restaurant_built(obj: VisualSamplePlaceable) -> void:
	restaurant_object = obj
	restaurant_built = true
	ui.add_toast("简易餐厅建好了，已自动开业。", Painter.TEAL)
	if day == 1:
		_spawn_customer("carrot_customer", "胡萝卜浓汤")
	_refresh_objective()
	save_game()


func _on_boat_built(obj: VisualSamplePlaceable) -> void:
	boat_object = obj
	boat_built = true
	ui.add_toast("小船建好了！走到船边按 E 启航。", Painter.TEAL)
	_refresh_objective()
	save_game()


func _find_restaurant() -> VisualSamplePlaceable:
	for obj in placed_objects:
		if is_instance_valid(obj) and str(obj.def.get("id", "")) == "restaurant":
			return obj
	return null


func _find_boat() -> VisualSamplePlaceable:
	for obj in placed_objects:
		if is_instance_valid(obj) and str(obj.def.get("id", "")) == "boat":
			return obj
	return null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var key := key_event.keycode
		if key == 0:
			key = key_event.physical_keycode
		if shop_open:
			if key == KEY_1:
				_buy_carrot()
				get_viewport().set_input_as_handled()
				return
			if key == KEY_2:
				_buy_cat_food()
				get_viewport().set_input_as_handled()
				return
			if key == KEY_ESCAPE:
				shop_open = false
				get_viewport().set_input_as_handled()
				return
		if key == KEY_E and not placement.build_mode and not placement.is_dragging():
			if _interact():
				get_viewport().set_input_as_handled()
				return
		if key == KEY_H:
			ui.add_toast(hint_text, Painter.BROWN)
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)


func _interact() -> bool:
	var p := player.position
	if post_meal_carrot and customer_actor != null and _near(p, customer_actor.position, 120):
		carrot_hunts += 1
		has_carrot += 1
		ui.add_toast("捕捉胡萝卜顾客 +1（第 4 天会有后果）。", Painter.BROWN)
		_clear_actor(customer_actor)
		customer_actor = null
		post_meal_carrot = false
		_refresh_objective()
		return true
	if wild_carrot_actor != null and _near(p, wild_carrot_actor.position, 120):
		carrot_hunts += 1
		has_carrot += 1
		_clear_actor(wild_carrot_actor)
		wild_carrot_actor = null
		ui.add_toast("捕捉胡萝卜顾客 +1。", Painter.BROWN)
		_refresh_objective()
		return true
	if big_carrot_active and big_carrot_actor != null \
			and _near(p, big_carrot_actor.position, 140):
		_resolve_big_carrot()
		return true
	if _near(p, snake_actor.position, 120):
		_talk_snake()
		return true
	if _near(p, burrow_actor.position, 105):
		_sleep()
		return true
	if employee_hired and not employee_assigned and employee_actor != null \
			and _near(p, employee_actor.position, 120):
		employee_assigned = true
		employee_actor.label_text = "阿水 · 服务员"
		employee_actor.state_text = "已上岗"
		employee_actor.queue_redraw()
		ui.add_toast("阿水已分配到服务员岗位。", Painter.TEAL)
		_refresh_objective()
		save_game()
		return true
	if customer_actor != null and _near(p, customer_actor.position, 120):
		if not held_dish.is_empty() and not (day == 3 and employee_assigned):
			_serve_customer()
			return true
		# Let the restaurant branch below cook or place the dish on the counter.
		if restaurant_object == null \
				or not _near(p, restaurant_object.get_footprint_center(), 150):
			ui.add_toast("顾客还在等餐。去餐厅做菜。", Painter.BROWN)
			return true
	if boat_built and boat_object != null \
			and _near(p, boat_object.get_footprint_center(), 150):
		_complete_tutorial()
		return true
	if restaurant_object != null and _near(p, restaurant_object.get_footprint_center(), 150):
		if not held_dish.is_empty() and employee_assigned:
			_place_on_counter()
		elif held_dish.is_empty():
			_cook()
		else:
			ui.add_toast("走到顾客身边交付。", Painter.BROWN)
		return true
	if day == 4:
		if _near(p, grid.cell_to_world(MUD_CELL), 120):
			mud += 1
			ui.add_toast("挖到泥土 +1。", Painter.BROWN)
			_refresh_objective()
			return true
		if _near(p, grid.cell_to_world(WATER_CELL), 120):
			water_count += 1
			ui.add_toast("取到水 +1。", Painter.TEAL)
			_refresh_objective()
			return true
	return false


func _talk_snake() -> void:
	if not snake_met:
		snake_met = true
		if day == 1:
			has_carrot += 1
			ui.add_toast("蛇商人：送你 1 根胡萝卜试用。1 键购买胡萝卜。", Painter.TEAL)
		else:
			ui.add_toast("蛇商人：想买点什么？", Painter.BROWN)
	if day == 3 and not employee_hired:
		employee_hired = true
		_spawn_employee()
		ui.add_toast("蛇商人带来小水獭阿水，新手期免费。", Painter.TEAL)
	shop_open = true
	_refresh_objective()
	save_game()


func _buy_carrot() -> void:
	if wallet < 6:
		ui.add_toast("金币不够，需要 6 金币。", Painter.CORAL_DARK)
		return
	wallet -= 6
	has_carrot += 1
	ui.add_toast("买了 1 根胡萝卜。", Painter.TEAL)


func _buy_cat_food() -> void:
	if day < 3:
		ui.add_toast("猫粮第 3 天才解锁。", Painter.BROWN)
		return
	if wallet < 12:
		ui.add_toast("金币不够，需要 12 金币。", Painter.CORAL_DARK)
		return
	wallet -= 12
	cat_food += 1
	ui.add_toast("买了 1 份猫粮。", Painter.TEAL)


func _cook() -> void:
	if not held_dish.is_empty():
		ui.add_toast("手里已经有菜了。", Painter.BROWN)
		return
	if day <= 2:
		if has_carrot <= 0 or inventory.get_count("grass") <= 0:
			ui.add_toast("缺 1 胡萝卜 + 1 草，去蛇商或采集。", Painter.CORAL_DARK)
			return
		has_carrot -= 1
		inventory.remove("grass", 1)
		held_dish = "胡萝卜浓汤"
	elif day == 3:
		if cat_food > 0:
			cat_food -= 1
			held_dish = "猫粮"
		elif rabbit_meat > 0:
			rabbit_meat -= 1
			held_dish = "兔肉料理"
		else:
			ui.add_toast("缺兔肉或猫粮。", Painter.CORAL_DARK)
			return
	else:
		return
	ui.add_toast("做好了：%s" % held_dish, Painter.TEAL)
	_refresh_objective()


func _serve_customer() -> void:
	if customer_actor == null:
		return
	if held_dish.is_empty() and not dish_on_counter:
		return
	var reward := 18
	if day == 2:
		reward = 24
	elif day == 3:
		reward = 30
	wallet += reward
	day_income += reward
	orders_completed += 1
	day_sale = true
	if day == 1:
		first_sale = true
	if active_customer_kind == "rabbit_customer" and day == 2:
		rabbit_meat += 1
		ui.add_toast("兔子顾客留下了一份兔肉。", Painter.BROWN)
	var kind := active_customer_kind
	_clear_actor(customer_actor)
	customer_actor = null
	active_order = ""
	active_customer_kind = ""
	held_dish = ""
	dish_on_counter = false
	ui.add_toast("订单完成，获得 %d 金币。" % reward, Painter.TEAL)
	if day == 1 and kind == "carrot_customer":
		# The served carrot customer can be captured after the tutorial order.
		_spawn_post_meal_carrot()
	elif day == 2:
		_spawn_wild_carrot()
	_refresh_objective()
	save_game()


func _spawn_post_meal_carrot() -> void:
	# Reuse the customer position as an optional capture target.
	if restaurant_object == null:
		return
	var pos := restaurant_object.get_footprint_center() + Vector2(70, 54)
	customer_actor = _make_actor("carrot_customer", "胡萝卜顾客", Color(0.94, 0.50, 0.24), pos)
	customer_actor.order_text = "E 捕捉"
	post_meal_carrot = true


func _spawn_wild_carrot() -> void:
	if restaurant_object == null or carrot_hunts >= 2:
		return
	var pos := restaurant_object.get_footprint_center() + Vector2(-70, 54)
	wild_carrot_actor = _make_actor("carrot_customer", "胡萝卜顾客", Color(0.94, 0.50, 0.24), pos)
	wild_carrot_actor.order_text = "E 捕捉"


func _place_on_counter() -> void:
	held_dish = ""
	dish_on_counter = true
	employee_actor.state_text = "去取餐"
	employee_actor.queue_redraw()
	_run_employee_delivery()


func _run_employee_delivery() -> void:
	if employee_busy or employee_actor == null or customer_actor == null:
		return
	employee_busy = true
	employee_actor.state_text = "取餐中"
	employee_actor.queue_redraw()
	var t := create_tween()
	t.tween_property(employee_actor, "position", customer_actor.position + Vector2(-34, 0), 1.2)
	await t.finished
	if customer_actor == null:
		employee_busy = false
		return
	employee_actor.state_text = "送餐中"
	employee_actor.queue_redraw()
	await get_tree().create_timer(0.7).timeout
	_serve_customer()
	employee_actor.state_text = "返回"
	employee_actor.queue_redraw()
	var back := create_tween()
	back.tween_property(employee_actor, "position", employee_home, 1.0)
	await back.finished
	employee_actor.state_text = "等待下一单"
	employee_actor.queue_redraw()
	employee_busy = false


func _spawn_employee() -> void:
	if employee_actor != null or restaurant_object == null:
		return
	employee_home = restaurant_object.get_footprint_center() + Vector2(-92, 30)
	employee_actor = _make_actor("employee", "阿水", Color(0.48, 0.68, 0.82), employee_home)
	employee_actor.state_text = "未分配岗位"
	employee_actor.queue_redraw()


func _spawn_big_carrot() -> void:
	if big_carrot_actor != null or restaurant_object == null:
		return
	big_carrot_active = true
	var pos := restaurant_object.get_footprint_center() + Vector2(94, 44)
	big_carrot_actor = _make_actor("big_carrot", "大胡萝卜", Color(0.94, 0.48, 0.22), pos)
	ui.add_toast("一只大胡萝卜找上门来算账了。", Painter.CORAL_DARK)


func _resolve_big_carrot() -> void:
	if mud < 10 or water_count < 6:
		ui.add_toast("大胡萝卜要求 10 泥土 + 6 水。", Painter.CORAL_DARK)
		return
	mud -= 10
	water_count -= 6
	big_carrot_active = false
	big_carrot_resolved = true
	_clear_actor(big_carrot_actor)
	big_carrot_actor = null
	ui.add_toast("大胡萝卜收下泥土和水，离开了。", Painter.TEAL)
	_refresh_objective()
	save_game()


func _sleep() -> void:
	var missing := _sleep_blocker()
	if not missing.is_empty():
		ui.add_toast(missing, Painter.CORAL_DARK)
		return
	if day >= 5:
		return
	ui.add_toast("第 %d 天结束，今日收入 %d 金币。" % [day, day_income], Painter.TEAL)
	_start_day(day + 1)


func _sleep_blocker() -> String:
	match day:
		1:
			if not first_sale:
				return "先完成第一笔订单，再去睡觉。"
		2:
			if not day_sale:
				return "先完成兔子顾客的订单。"
		3:
			if not employee_assigned:
				return "先把阿水分配到服务员岗位。"
			if not day_sale:
				return "先完成猫猫订单。"
		4:
			if big_carrot_active and not big_carrot_resolved:
				return "先处理大胡萝卜。"
			if not _has_boat_materials():
				return "造船材料还不够：20木 8石 6草。"
		5:
			if not completed:
				return "先建造小船并登船。"
	return ""


func _has_boat_materials() -> bool:
	return inventory.get_count("wood") >= 20 \
		and inventory.get_count("stone") >= 8 \
		and inventory.get_count("grass") >= 6


func _complete_tutorial() -> void:
	completed = true
	ui.add_toast("启航！新手关完成。", Painter.TEAL)
	_refresh_objective()
	save_game()


func _refresh_objective() -> void:
	if hint_text.is_empty() or _hint_timer > 4.0:
		_hint_timer = 0.0
		hint_text = _compute_hint()
	objective_text = _compute_objective()
	if hud:
		hud.queue_redraw()


var objective_text := ""
var hint_text := ""


func _compute_objective() -> String:
	if completed:
		return "新手关完成"
	match day:
		1:
			if not snake_met:
				return "去东边找蛇商人（E）"
			if has_carrot <= 0 and not day_sale:
				return "在蛇商处拿/买胡萝卜"
			if not restaurant_built:
				if inventory.get_count("wood") < 8 or inventory.get_count("stone") < 4 \
						or inventory.get_count("grass") < 2:
					return "采集 8木 / 4石 / 2草"
				return "按 B 建造简易餐厅"
			if not day_sale:
				if held_dish.is_empty():
					return "在餐厅按 E 做胡萝卜浓汤"
				return "把汤送给胡萝卜顾客"
			return "回兔窝睡觉"
		2:
			if not day_sale:
				if has_carrot <= 0:
					return "去蛇商买胡萝卜"
				if held_dish.is_empty():
					return "在餐厅做胡萝卜浓汤"
				return "把汤送给兔子顾客"
			return "回兔窝睡觉"
		3:
			if not employee_hired:
				return "找蛇商人招募阿水"
			if not employee_assigned:
				return "靠近阿水，按 E 分配服务员"
			if not day_sale:
				if held_dish.is_empty():
					return "准备兔肉或猫粮，并在餐厅做菜"
				return "把菜放到取餐台，让阿水送餐"
			return "回兔窝睡觉"
		4:
			if big_carrot_active and not big_carrot_resolved:
				return "处理大胡萝卜：10泥土 + 6水"
			if not _has_boat_materials():
				return "采集 20木 / 8石 / 6草"
			return "回兔窝睡觉"
		5:
			if not boat_built:
				return "去东南船坞按 B 造小船"
			return "靠近小船按 E 启航"
	return ""


func _compute_hint() -> String:
	match day:
		1:
			return "WASD 移动 · 靠近资源按 E · B 打开建造"
		2:
			return "蛇商在岛东侧；做菜后走到顾客身边按 E"
		3:
			return "玩家做菜，阿水负责送餐；E 分配岗位"
		4:
			return "泥地在西南，取水点在东南；员工会继续工作"
		5:
			return "船坞在东南；按 B 选小船"
	return "E 交互"


func _near(a: Vector2, b: Vector2, radius: float) -> bool:
	return a.distance_to(b) <= radius


func _clear_actor(actor: TutorialActor) -> void:
	if actor != null and is_instance_valid(actor):
		actor.queue_free()


func _can_afford(cost: Dictionary) -> bool:
	for key in cost.keys():
		if inventory.get_count(str(key)) < int(cost[key]):
			return false
	return true


func _spend(cost: Dictionary) -> void:
	for key in cost.keys():
		inventory.remove(str(key), int(cost[key]))


func spawn_placeable(def: Dictionary, origin: Vector2i, rotation_value := 0) -> VisualSamplePlaceable:
	if not _loading:
		var cost: Dictionary = def.get("build_cost", {})
		if not cost.is_empty() and not _can_afford(cost):
			ui.add_toast("建造材料不足。", Painter.CORAL_DARK)
			return null
	var obj: VisualSamplePlaceable = super.spawn_placeable(def, origin, rotation_value)
	if obj == null:
		return null
	if not _loading:
		var cost: Dictionary = def.get("build_cost", {})
		if not cost.is_empty():
			_spend(cost)
		var id := str(def.get("id", ""))
		if id == "restaurant":
			_on_restaurant_built(obj)
		elif id == "boat":
			_on_boat_built(obj)
	return obj


func save_game(path: String = "") -> bool:
	var ok := super.save_game(path)
	if ok:
		_write_state()
	return ok


func load_game(path: String = "") -> bool:
	_loading = true
	var ok := super.load_game(path)
	_loading = false
	if ok:
		_restore_after_load()
	return ok


func _write_state() -> void:
	var data := {
		"day": day, "wallet": wallet, "snake_met": snake_met,
		"has_carrot": has_carrot, "rabbit_meat": rabbit_meat, "cat_food": cat_food,
		"mud": mud, "water_count": water_count, "held_dish": held_dish,
		"dish_on_counter": dish_on_counter, "restaurant_built": restaurant_built,
		"boat_built": boat_built, "first_sale": first_sale, "day_sale": day_sale,
		"day_income": day_income, "orders_completed": orders_completed,
		"employee_hired": employee_hired, "employee_assigned": employee_assigned,
		"carrot_hunts": carrot_hunts, "big_carrot_active": big_carrot_active,
		"big_carrot_resolved": big_carrot_resolved, "completed": completed
	}
	var file := FileAccess.open(state_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


func _restore_after_load() -> void:
	var file := FileAccess.open(state_path, FileAccess.READ)
	if file == null:
		_start_day(1, true)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_start_day(1, true)
		return
	var data: Dictionary = parsed
	day = int(data.get("day", 1))
	wallet = int(data.get("wallet", 0))
	snake_met = bool(data.get("snake_met", false))
	has_carrot = int(data.get("has_carrot", 0))
	rabbit_meat = int(data.get("rabbit_meat", 0))
	cat_food = int(data.get("cat_food", 0))
	mud = int(data.get("mud", 0))
	water_count = int(data.get("water_count", 0))
	held_dish = str(data.get("held_dish", ""))
	dish_on_counter = bool(data.get("dish_on_counter", false))
	restaurant_built = bool(data.get("restaurant_built", false))
	boat_built = bool(data.get("boat_built", false))
	first_sale = bool(data.get("first_sale", false))
	day_sale = bool(data.get("day_sale", false))
	day_income = int(data.get("day_income", 0))
	orders_completed = int(data.get("orders_completed", 0))
	employee_hired = bool(data.get("employee_hired", false))
	employee_assigned = bool(data.get("employee_assigned", false))
	carrot_hunts = int(data.get("carrot_hunts", 0))
	big_carrot_active = bool(data.get("big_carrot_active", false))
	big_carrot_resolved = bool(data.get("big_carrot_resolved", false))
	completed = bool(data.get("completed", false))
	restaurant_object = _find_restaurant()
	boat_object = _find_boat()
	_apply_day_build_defs()
	_clear_actor(customer_actor)
	customer_actor = null
	_clear_actor(employee_actor)
	employee_actor = null
	_clear_actor(big_carrot_actor)
	big_carrot_actor = null
	if employee_hired:
		_spawn_employee()
		if employee_assigned and employee_actor:
			employee_actor.label_text = "阿水 · 服务员"
			employee_actor.state_text = "等待下一单"
	if restaurant_built and not day_sale and day != 4 and day != 5:
		_spawn_day_customer()
	if day == 4 and big_carrot_active:
		_spawn_big_carrot()
	_refresh_objective()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()
