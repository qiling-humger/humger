class_name EconomySystem
extends Node
## 金币、满意度、本局统计。所有数值变化通过信号发布给 UI。

signal coins_changed(value: int)
signal satisfaction_changed(value: int)
signal stats_changed(stats: Dictionary)

var manager: Node
var coins := 0
var satisfaction := 80
var stats: Dictionary = {}


func setup(manager_node: Node) -> void:
	manager = manager_node
	reset()


func reset() -> void:
	var cfg := GameData.section("economy")
	coins = int(cfg.get("starting_coins", 0))
	if coins == 0:
		coins = int(GameData.section("shift").get("starting_coins", 0))
	satisfaction = int(cfg.get("starting_satisfaction", 80))
	stats = {
		"served": 0,
		"wrong": 0,
		"lost": 0,
		"perfect": 0,
		"quality_points": 0,
		"earned": 0,
		"quality_count": 0,
	}
	coins_changed.emit(coins)
	satisfaction_changed.emit(satisfaction)
	stats_changed.emit(stats.duplicate(true))


func quality_score(quality_id: String) -> int:
	match quality_id:
		"perfect":
			return 4
		"just_cooked":
			return 3
		"overcooked":
			return 1
	return 0


func reward_order(order: Dictionary, quality_id: String, patience_ratio: float) -> Dictionary:
	var cfg := GameData.section("economy")
	var state := GameData.cook_state_by_id(quality_id)
	var base := int(order.get("base_price", 20))
	var quality_bonus := int(state.get("reward", 0))
	var tip_max := int(cfg.get("tip_max", 7))
	var tip := int(round(clampf(patience_ratio, 0.0, 1.0) * tip_max))
	var total := base + quality_bonus + tip
	coins += total
	stats["served"] = int(stats.get("served", 0)) + 1
	stats["earned"] = int(stats.get("earned", 0)) + total
	stats["quality_points"] = int(stats.get("quality_points", 0)) + quality_score(quality_id)
	stats["quality_count"] = int(stats.get("quality_count", 0)) + 1
	if quality_id == "perfect":
		stats["perfect"] = int(stats.get("perfect", 0)) + 1
	var satisfaction_delta := int(state.get("satisfaction", 0))
	if quality_id == "perfect":
		satisfaction_delta += int(cfg.get("perfect_satisfaction_bonus", 2))
	if patience_ratio > 0.65:
		satisfaction_delta += 1
	satisfaction = clampi(satisfaction + satisfaction_delta, 0, 100)
	_emit_all()
	manager.on_order_rewarded({
		"total": total,
		"base": base,
		"quality_bonus": quality_bonus,
		"tip": tip,
		"satisfaction": satisfaction_delta,
		"quality": quality_id,
	})
	return {
		"total": total,
		"base": base,
		"quality_bonus": quality_bonus,
		"tip": tip,
		"satisfaction": satisfaction_delta,
	}


func penalize_wrong(reason: String) -> void:
	var cfg := GameData.section("economy")
	var penalty := int(cfg.get("wrong_delivery_penalty", 8))
	coins = maxi(0, coins - penalty)
	satisfaction = clampi(satisfaction - penalty, 0, 100)
	stats["wrong"] = int(stats.get("wrong", 0)) + 1
	_emit_all()
	manager.on_order_failed("wrong", reason, penalty)


func penalize_timeout(customer_name: String) -> void:
	var cfg := GameData.section("economy")
	var penalty := int(cfg.get("patience_leave_penalty", 14))
	satisfaction = clampi(satisfaction - penalty, 0, 100)
	stats["lost"] = int(stats.get("lost", 0)) + 1
	_emit_all()
	manager.on_order_failed("timeout", "%s 等太久离开了。" % customer_name, penalty)


func _emit_all() -> void:
	coins_changed.emit(coins)
	satisfaction_changed.emit(satisfaction)
	stats_changed.emit(stats.duplicate(true))


func average_quality() -> float:
	var count := int(stats.get("quality_count", 0))
	if count <= 0:
		return 0.0
	return float(stats.get("quality_points", 0)) / float(count)
