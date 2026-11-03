class_name InteractionSystem
extends Node
## 每帧寻找玩家交互半径内最近的设备，维护高亮和提示；E 键执行交互。

signal focus_changed(station: Station)

var manager: Node
var player: Player
var current_station: Station
var current_prompt: Dictionary = {}


func setup(manager_node: Node, player_node: Player) -> void:
	manager = manager_node
	player = player_node
	current_station = null
	current_prompt = {}
	focus_changed.emit(null)


func _process(_delta: float) -> void:
	if manager == null or player == null or not manager.is_playing():
		_clear_focus()
		return
	var best: Station = null
	var best_distance := 99999.0
	for node in get_tree().get_nodes_in_group("stations"):
		var station := node as Station
		if station == null:
			continue
		var distance := player.global_position.distance_to(station.get_interaction_position())
		if distance <= station.interaction_radius and distance < best_distance:
			best_distance = distance
			best = station
	if best != current_station:
		if current_station and is_instance_valid(current_station):
			current_station.set_highlighted(false)
		current_station = best
		if current_station:
			current_station.set_highlighted(true)
		focus_changed.emit(current_station)
	if current_station and is_instance_valid(current_station):
		current_prompt = current_station.get_prompt(player)
	else:
		current_prompt = {}


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if try_interact():
			get_viewport().set_input_as_handled()


func try_interact() -> bool:
	if manager == null or player == null or not manager.is_playing():
		return false
	if current_station == null or not is_instance_valid(current_station):
		return false
	current_station.interact(player)
	return true


func _clear_focus() -> void:
	if current_station and is_instance_valid(current_station):
		current_station.set_highlighted(false)
	if current_station != null:
		current_station = null
		focus_changed.emit(null)
	current_prompt = {}


func prompt_text() -> String:
	return str(current_prompt.get("text", ""))
