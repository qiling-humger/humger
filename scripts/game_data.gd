class_name GameData
extends RefCounted
## 集中读取 data/game_config.json，并提供纯数据工具函数。
## 数值全部在 JSON 中调整，剧情/表现层不硬编码经济数值。

const CONFIG_PATH := "res://data/game_config.json"

static var _cached: Dictionary = {}


static func config() -> Dictionary:
	if _cached.is_empty():
		var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file == null:
			push_error("无法读取配置文件: %s" % CONFIG_PATH)
			return {}
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("配置文件不是合法 JSON 对象")
			return {}
		_cached = parsed
	return _cached


static func section(name: String) -> Dictionary:
	return config().get(name, {})


static func cook_states() -> Array:
	return section("cooking").get("states", [])


static func cook_state(cook_time: float) -> Dictionary:
	var states := cook_states()
	for state in states:
		if cook_time < float(state.get("until", 0.0)):
			return state
	return states[states.size() - 1] if not states.is_empty() else {}


static func cook_state_by_id(id: String) -> Dictionary:
	for state in cook_states():
		if str(state.get("id", "")) == id:
			return state
	return {}


static func quality_rank(id: String) -> int:
	# 数字越大越好；用于双层热狗取“最差的一根”。
	match id:
		"perfect":
			return 5
		"just_cooked":
			return 4
		"overcooked":
			return 3
		"heating":
			return 2
		"raw":
			return 1
		"burnt":
			return 0
	return 0


static func worst_quality(ids: Array) -> String:
	var worst := "perfect"
	var worst_rank := 99
	for raw_id in ids:
		var id := str(raw_id)
		var rank := quality_rank(id)
		if rank < worst_rank:
			worst_rank = rank
			worst = id
	return worst


static func color(hex: String, fallback: Color = Color.WHITE) -> Color:
	if hex.is_empty():
		return fallback
	return Color.from_string(hex, fallback)


static func weighted_pick(rng: RandomNumberGenerator, entries: Array) -> Dictionary:
	if entries.is_empty():
		return {}
	var total := 0.0
	for entry in entries:
		total += maxf(0.0, float(entry.get("weight", 1.0)))
	if total <= 0.0:
		return entries[0]
	var roll := rng.randf_range(0.0, total)
	for entry in entries:
		roll -= maxf(0.0, float(entry.get("weight", 1.0)))
		if roll <= 0.0:
			return entry
	return entries[entries.size() - 1]


static func make_raw_sausage() -> Dictionary:
	return {"type": "raw_sausage"}


static func make_cooked_sausage(quality_id: String, cook_time: float) -> Dictionary:
	return {
		"type": "cooked_sausage",
		"quality": quality_id,
		"cook_time": cook_time,
	}


static func make_bun() -> Dictionary:
	return {"type": "bun"}


static func make_hotdog(sausages: Array, sauces: Dictionary) -> Dictionary:
	var ids: Array = []
	for sausage in sausages:
		ids.append(str(sausage.get("quality", "raw")))
	var ketchup := bool(sauces.get("ketchup", false))
	var mustard := bool(sauces.get("mustard", false))
	return {
		"type": "hotdog",
		"count": sausages.size(),
		"quality": worst_quality(ids),
		"sausages": sausages.duplicate(true),
		"sauces": {"ketchup": ketchup, "mustard": mustard},
	}


static func hotdog_sauce_label(item: Dictionary) -> String:
	var sauces: Dictionary = item.get("sauces", {})
	var ketchup := bool(sauces.get("ketchup", false))
	var mustard := bool(sauces.get("mustard", false))
	if ketchup and mustard:
		return "双酱"
	if ketchup:
		return "番茄酱"
	if mustard:
		return "芥末酱"
	return "原味"


static func hotdog_name(item: Dictionary) -> String:
	var count := int(item.get("count", 1))
	return "双层热狗" if count >= 2 else "经典热狗"


static func item_name(item: Dictionary) -> String:
	if item.is_empty():
		return "空手"
	match str(item.get("type", "")):
		"raw_sausage":
			return "生热狗肠"
		"cooked_sausage":
			var state := cook_state_by_id(str(item.get("quality", "raw")))
			return "%s热狗肠" % str(state.get("label", "热狗肠"))
		"bun":
			return "热狗面包"
		"hotdog":
			var state2 := cook_state_by_id(str(item.get("quality", "raw")))
			return "%s · %s · %s" % [
				hotdog_name(item),
				str(state2.get("label", "未知火候")),
				hotdog_sauce_label(item),
			]
	return "未知物品"


static func format_time(seconds: float) -> String:
	var total := maxi(0, int(ceil(seconds)))
	return "%02d:%02d" % [total / 60, total % 60]


static func cook_state_color(id: String) -> Color:
	var state := cook_state_by_id(id)
	return color(str(state.get("color", "#A8653C")), Color("#A8653C"))
