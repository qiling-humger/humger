class_name CustomerQueue
extends Node
## 顾客队列：自动到店、排队、耐心超时、服务后补位与离场。

signal queue_changed
signal front_changed(customer: Customer)
signal customer_arrived(customer: Customer)
signal customer_left(customer: Customer, reason: String)

const CUSTOMER_SCENE := preload("res://scenes/Customer.tscn")

var manager: Node
var container: Node2D
var order_system: OrderSystem
var customers: Array[Customer] = []
var slots: Array[Vector2] = []
var active := false
var spawn_timer := 0.0
var next_customer_in := 0.0

var _rng := RandomNumberGenerator.new()


func setup(manager_node: Node, container_node: Node2D, order_sys: OrderSystem) -> void:
	manager = manager_node
	container = container_node
	order_system = order_sys
	_rng.randomize()
	_load_slots()
	reset()


func _load_slots() -> void:
	slots.clear()
	var raw: Array = GameData.config().get("queue_slots", [])
	if raw.is_empty():
		raw = GameData.section("customers").get("queue_slots", [])
	for entry in raw:
		slots.append(Vector2(float(entry.get("x", 950)), float(entry.get("y", 460))))
	if slots.is_empty():
		slots = [Vector2(1028, 400), Vector2(1042, 458), Vector2(904, 516)]


func reset() -> void:
	active = false
	spawn_timer = 0.0
	next_customer_in = 0.0
	for customer in customers:
		if is_instance_valid(customer):
			customer.queue_free()
	customers.clear()
	queue_changed.emit()
	front_changed.emit(null)


func start() -> void:
	reset()
	active = true
	var cfg := GameData.section("customers")
	spawn_timer = float(cfg.get("first_arrival_delay", 1.2))
	next_customer_in = spawn_timer
	queue_changed.emit()


func stop() -> void:
	active = false


func _process(delta: float) -> void:
	if not active or manager == null or not manager.is_playing():
		return
	next_customer_in = maxf(0.0, spawn_timer)
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		if customers.size() < int(GameData.section("customers").get("max_queue", 3)):
			spawn_customer_now()
		else:
			spawn_timer = 5.0


func spawn_customer_now(recipe_id: String = "", sauce_id: String = "") -> Customer:
	if customers.size() >= int(GameData.section("customers").get("max_queue", 3)):
		return null
	var profile := order_system.generate_customer_profile()
	# 同屏尽量不出现同名顾客，避免 UI 和对话指向不清。
	for attempt in range(6):
		if not _name_in_queue(str(profile.get("name", ""))):
			break
		profile = order_system.generate_customer_profile()
	var order := order_system.generate_order(recipe_id, sauce_id)
	var patience := float(GameData.section("customers").get("patience_seconds", 80.0))
	var customer := CUSTOMER_SCENE.instantiate() as Customer
	customer.setup(profile, order, self, patience)
	customer.timed_out.connect(_on_customer_timed_out)
	container.add_child(customer)
	customers.append(customer)
	_set_front_flags()
	var slot_index := customers.size() - 1
	customer.enter_slot(_slot_for(slot_index))
	spawn_timer = float(GameData.section("customers").get("arrival_interval", 26.0)) * _rng.randf_range(0.85, 1.15)
	next_customer_in = spawn_timer
	queue_changed.emit()
	customer_arrived.emit(customer)
	if customers.size() == 1:
		front_changed.emit(customer)
	return customer


func _name_in_queue(customer_name: String) -> bool:
	if customer_name.is_empty():
		return false
	for customer in customers:
		if is_instance_valid(customer) and str(customer.profile.get("name", "")) == customer_name:
			return true
	return false


func _slot_for(index: int) -> Vector2:
	return slots[min(index, slots.size() - 1)]


func _set_front_flags() -> void:
	for i in range(customers.size()):
		if is_instance_valid(customers[i]):
			customers[i].set_front(i == 0)


func get_front() -> Customer:
	if customers.is_empty():
		return null
	return customers[0]


func get_front_order() -> Dictionary:
	var front := get_front()
	return front.order if front else {}


func dismiss_front(reason: String, reward: int = 0) -> void:
	if customers.is_empty():
		return
	var customer := customers[0]
	customers.remove_at(0)
	if is_instance_valid(customer):
		customer.timed_out.disconnect(_on_customer_timed_out)
		if reason == "served":
			customer.play_served(reward)
		elif reason == "wrong":
			customer.play_rejected()
		else:
			customer.play_timeout()
	_set_front_flags()
	_arrange_queue()
	queue_changed.emit()
	customer_left.emit(customer, reason)
	front_changed.emit(get_front())
	_schedule_next_if_empty()


func _on_customer_timed_out(customer: Customer) -> void:
	var index := customers.find(customer)
	if index < 0:
		return
	customers.remove_at(index)
	customer.timed_out.disconnect(_on_customer_timed_out)
	customer.play_timeout()
	_set_front_flags()
	_arrange_queue()
	queue_changed.emit()
	customer_left.emit(customer, "timeout")
	front_changed.emit(get_front())
	_schedule_next_if_empty()


func _arrange_queue() -> void:
	for i in range(customers.size()):
		if is_instance_valid(customers[i]):
			customers[i].move_to_slot(_slot_for(i))


func _schedule_next_if_empty() -> void:
	if customers.is_empty():
		var delay := float(GameData.section("customers").get("after_empty_queue_delay", 3.0))
		spawn_timer = minf(spawn_timer, delay)
		next_customer_in = spawn_timer


func clear_all() -> void:
	for customer in customers:
		if is_instance_valid(customer):
			customer.queue_free()
	customers.clear()
	queue_changed.emit()
	front_changed.emit(null)
