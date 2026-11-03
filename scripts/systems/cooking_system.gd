class_name CookingSystem
extends Node
## 三个烤位的火候状态机。计时与状态阈值全部来自 game_config.json。

signal slots_changed

var manager: Node
var max_slots := 3
var heat_multiplier := 1.0
var slots: Array[Dictionary] = []

var _last_states: Array[String] = []


func setup(manager_node: Node) -> void:
	manager = manager_node
	var cfg := GameData.section("cooking")
	max_slots = int(cfg.get("max_slots", 3))
	heat_multiplier = float(cfg.get("heat_multiplier", 1.0))
	reset()


func reset() -> void:
	slots.clear()
	_last_states.clear()
	for i in range(max_slots):
		slots.append({"occupied": false, "elapsed": 0.0, "state": ""})
		_last_states.append("")
	slots_changed.emit()


func _process(delta: float) -> void:
	if manager == null or not manager.is_playing():
		return
	var changed := false
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		if not bool(slot.get("occupied", false)):
			continue
		slot["elapsed"] = float(slot.get("elapsed", 0.0)) + delta * heat_multiplier
		var state := GameData.cook_state(float(slot["elapsed"]))
		var state_id := str(state.get("id", "raw"))
		if state_id != str(slot.get("state", "")):
			slot["state"] = state_id
			changed = true
		if state_id != _last_states[i]:
			_last_states[i] = state_id
			changed = true
	if changed:
		slots_changed.emit()
		# 让烤制中的视觉立即刷新，而不是等下一次鼠标/计时事件。
		var grill := get_tree().get_first_node_in_group("station_grill")
		if grill:
			grill.queue_redraw()


func has_empty_slot() -> bool:
	for slot in slots:
		if not bool(slot.get("occupied", false)):
			return true
	return false


func has_any() -> bool:
	for slot in slots:
		if bool(slot.get("occupied", false)):
			return true
	return false


func occupied_count() -> int:
	var count := 0
	for slot in slots:
		if bool(slot.get("occupied", false)):
			count += 1
	return count


func place_raw() -> int:
	for i in range(slots.size()):
		if not bool(slots[i].get("occupied", false)):
			slots[i] = {"occupied": true, "elapsed": 0.0, "state": "raw"}
			_last_states[i] = "raw"
			slots_changed.emit()
			return i
	return -1


func state_for_slot(index: int) -> Dictionary:
	if index < 0 or index >= slots.size():
		return {}
	var slot: Dictionary = slots[index]
	if not bool(slot.get("occupied", false)):
		return {}
	return GameData.cook_state(float(slot.get("elapsed", 0.0)))


func progress_for_slot(index: int) -> float:
	if index < 0 or index >= slots.size():
		return 0.0
	var elapsed := float(slots[index].get("elapsed", 0.0))
	# 展示到“烤焦”起点为满格，超过后仍显示满。
	var burnt_at := 14.5
	var states := GameData.cook_states()
	if not states.is_empty():
		burnt_at = float(states[states.size() - 1].get("until", 14.5))
		if burnt_at > 100.0:
			burnt_at = float(states[states.size() - 2].get("until", 14.5))
	return clampf(elapsed / maxf(0.1, burnt_at), 0.0, 1.0)


func take_slot(index: int) -> Dictionary:
	if index < 0 or index >= slots.size():
		return {}
	var slot: Dictionary = slots[index]
	if not bool(slot.get("occupied", false)):
		return {}
	var elapsed := float(slot.get("elapsed", 0.0))
	var state := GameData.cook_state(elapsed)
	var item := GameData.make_cooked_sausage(str(state.get("id", "raw")), elapsed)
	slots[index] = {"occupied": false, "elapsed": 0.0, "state": ""}
	_last_states[index] = ""
	slots_changed.emit()
	return item


func take_best() -> Dictionary:
	var best_index := -1
	var best_rank := -99
	for i in range(slots.size()):
		if not bool(slots[i].get("occupied", false)):
			continue
		var state := GameData.cook_state(float(slots[i].get("elapsed", 0.0)))
		var rank := GameData.quality_rank(str(state.get("id", "raw")))
		if rank > best_rank:
			best_rank = rank
			best_index = i
	if best_index < 0:
		return {}
	return take_slot(best_index)


func set_slot_time(index: int, seconds: float) -> void:
	# 供自动化测试和调试使用，正常玩法不会直接调用。
	if index < 0 or index >= slots.size():
		return
	slots[index]["occupied"] = true
	slots[index]["elapsed"] = seconds
	slots[index]["state"] = str(GameData.cook_state(seconds).get("id", "raw"))
	_last_states[index] = slots[index]["state"]
	slots_changed.emit()


func toast_for_quality(quality: String) -> String:
	var state := GameData.cook_state_by_id(quality)
	var label := str(state.get("label", "未知"))
	match quality:
		"perfect":
			return "漂亮！这根是「完美」火候。"
		"just_cooked":
			return "熟透了，趁现在用正好。"
		"overcooked":
			return "有点过熟了，口感会打折。"
		"burnt":
			return "糟糕，烤焦了！只能丢掉。"
		"heating":
			return "还没熟，再等等。"
		_:
			return "现在是「%s」。" % label
