class_name GameManager
extends Node2D
## 游戏流程：标题 → 营业 → 暂停 → 结算；协调各系统，但不把烹饪/订单/经济逻辑吞进本文件。

signal state_changed(new_state: int)
signal time_changed(seconds_left: float)
signal toast_requested(text: String, color: Color)

enum State { TITLE, PLAYING, PAUSED, GAME_OVER }

const PLAYER_SPAWN := Vector2(620, 535)
const MAX_PLAYER_SPEED := 235.0

@onready var entities: Node2D = $Entities
@onready var player: Player = $Entities/Player
@onready var cooking_system: CookingSystem = $Systems/CookingSystem
@onready var order_system: OrderSystem = $Systems/OrderSystem
@onready var economy_system: EconomySystem = $Systems/EconomySystem
@onready var customer_queue: CustomerQueue = $Systems/CustomerQueue
@onready var interaction_system: InteractionSystem = $Systems/InteractionSystem
@onready var ui: UIManager = $UI

var state: int = State.TITLE
var shift_duration := 180.0
var time_left := 180.0
var results: Dictionary = {}

var delivery_station: DeliveryStation
var assembly_station: AssemblyStation


func _ready() -> void:
	var shift_cfg := GameData.section("shift")
	shift_duration = float(shift_cfg.get("duration_seconds", 180.0))
	time_left = shift_duration
	var player_cfg := GameData.section("player")
	var speed := float(player_cfg.get("speed", MAX_PLAYER_SPEED))

	economy_system.setup(self)
	order_system.setup(self)
	cooking_system.setup(self)
	customer_queue.setup(self, entities, order_system)

	var obstacles: Array[Rect2] = []
	for node in get_tree().get_nodes_in_group("stations"):
		var station := node as Station
		if station == null:
			continue
		station.setup(self)
		obstacles.append(station.get_obstacle_rect())
		if station.station_id == "delivery":
			delivery_station = station as DeliveryStation
		elif station.station_id == "assembly":
			assembly_station = station as AssemblyStation

	player.setup(self, PLAYER_SPAWN, obstacles)
	player.move_speed = speed
	player.set_input_enabled(false)
	interaction_system.setup(self, player)

	economy_system.satisfaction_changed.connect(_on_satisfaction_changed)
	customer_queue.customer_arrived.connect(_on_customer_arrived)
	customer_queue.customer_left.connect(_on_customer_left)

	ui.setup(self, player, economy_system, cooking_system, customer_queue, interaction_system, order_system)
	state = State.TITLE
	player.reset_player()
	customer_queue.reset()
	time_changed.emit(time_left)
	ui.show_title()
	state_changed.emit(state)


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	var previous_second := int(ceil(time_left))
	time_left = maxf(0.0, time_left - delta)
	if int(ceil(time_left)) != previous_second:
		time_changed.emit(time_left)
	if time_left <= 0.0:
		end_shift("shift_end")


func is_playing() -> bool:
	return state == State.PLAYING


func start_shift() -> void:
	if state == State.PLAYING:
		return
	get_tree().paused = false
	state = State.PLAYING
	time_left = shift_duration
	economy_system.reset()
	cooking_system.reset()
	customer_queue.reset()
	player.reset_player()
	player.set_input_enabled(true)
	if assembly_station:
		assembly_station.reset_board()
	if delivery_station:
		delivery_station.ring_time = 0.0
	ui.hide_title()
	ui.show_hud()
	ui.hide_pause()
	ui.hide_results()
	customer_queue.start()
	state_changed.emit(state)
	time_changed.emit(time_left)
	notify("开门营业！先看看顾客要什么。", Painter.TEAL)


func toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		player.set_input_enabled(false)
		get_tree().paused = true
		ui.show_pause()
		state_changed.emit(state)
	elif state == State.PAUSED:
		state = State.PLAYING
		get_tree().paused = false
		player.set_input_enabled(true)
		ui.hide_pause()
		state_changed.emit(state)


func resume_game() -> void:
	if state == State.PAUSED:
		toggle_pause()


func end_shift(reason: String) -> void:
	if state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	player.set_input_enabled(false)
	customer_queue.stop()
	time_changed.emit(time_left)
	var stats: Dictionary = economy_system.stats
	var average := economy_system.average_quality()
	var score := economy_system.coins + int(stats.get("served", 0)) * 15 \
		+ economy_system.satisfaction * 2 + int(stats.get("perfect", 0)) * 4
	var rank := _rank_for_score(score)
	results = {
		"reason": reason,
		"coins": economy_system.coins,
		"served": int(stats.get("served", 0)),
		"wrong": int(stats.get("wrong", 0)),
		"lost": int(stats.get("lost", 0)),
		"perfect": int(stats.get("perfect", 0)),
		"satisfaction": economy_system.satisfaction,
		"average_quality": average,
		"score": score,
		"rank": rank,
		"time_played": shift_duration - time_left,
		"duration": shift_duration,
	}
	ui.show_results(results)
	get_tree().paused = true
	state_changed.emit(state)


func _rank_for_score(score: int) -> String:
	if score >= 380:
		return "S"
	if score >= 280:
		return "A"
	if score >= 180:
		return "B"
	return "C"


func restart_round() -> void:
	get_tree().paused = false
	state = State.TITLE
	ui.hide_pause()
	ui.hide_results()
	start_shift()


func restart_game() -> void:
	SceneManager.restart_game()


func back_to_title() -> void:
	SceneManager.back_to_title()


func deliver_hotdog(player_node: Player) -> void:
	if state != State.PLAYING or player_node == null:
		return
	var front := customer_queue.get_front()
	if front == null:
		notify("现在没有等待中的顾客，先等客人进店。", Painter.BROWN)
		return
	var item := player_node.get_item()
	if str(item.get("type", "")) != "hotdog":
		notify("手上没有做好的热狗，不能交付。", Painter.BROWN)
		return
	var validation := order_system.validate_order(front.order, item)
	if not bool(validation.get("ok", false)):
		var reason := str(validation.get("reason", "订单不对。"))
		player_node.clear_item()
		economy_system.penalize_wrong(reason)
		customer_queue.dismiss_front("wrong")
		if delivery_station:
			delivery_station.ring_bell()
		_check_failure()
		return
	var reward: Dictionary = economy_system.reward_order(front.order, str(validation.get("quality", "perfect")),
		front.patience_ratio())
	player_node.clear_item()
	customer_queue.dismiss_front("served", int(reward.get("total", 0)))
	if delivery_station:
		delivery_station.ring_bell()
	notify("交付成功！+¥%d（品质 ¥%d / 小费 ¥%d）" % [
		int(reward.get("total", 0)), int(reward.get("quality_bonus", 0)), int(reward.get("tip", 0))
	], Painter.TEAL)


func on_order_rewarded(_data: Dictionary) -> void:
	# 具体金币文案由 deliver_hotdog 统一播报，这里保留扩展点给未来的连击/评级。
	pass


func on_order_failed(kind: String, reason: String, penalty: int) -> void:
	var color := Painter.CORAL_DARK
	if kind == "timeout":
		notify("%s 满意度 -%d" % [reason, penalty], color)
	else:
		notify("交付失败：%s 满意度 -%d" % [reason, penalty], color)
	_check_failure()


func _on_customer_arrived(customer: Customer) -> void:
	# 只在队伍从空到有人时播报，避免连续到店时顶上刷出一排提示。
	if customer_queue.customers.size() == 1:
		var name := str(customer.profile.get("name", "顾客"))
		notify("叮咚！%s 进店了。" % name, Painter.BROWN)


func _on_customer_left(customer: Customer, reason: String) -> void:
	if reason == "timeout":
		economy_system.penalize_timeout(str(customer.profile.get("name", "顾客")))


func _on_satisfaction_changed(value: int) -> void:
	if state == State.PLAYING and value <= 0:
		_check_failure()


func _check_failure() -> void:
	if state == State.PLAYING and economy_system.satisfaction <= 0:
		end_shift("satisfaction")


func notify(text: String, color: Color = Painter.INK) -> void:
	toast_requested.emit(text, color)


func get_state_label() -> String:
	match state:
		State.TITLE:
			return "准备中"
		State.PLAYING:
			return "营业中"
		State.PAUSED:
			return "已暂停"
		State.GAME_OVER:
			return "已打烊"
	return ""
