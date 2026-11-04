class_name MapConfig
extends RefCounted
## 读取家园岛原型的集中配置。地图、资源、家具尺寸都不写死在绘制脚本里。

const CONFIG_PATH := "res://map_prototype/data/island_config.json"
static var _cached: Dictionary = {}


static func load_data() -> Dictionary:
	if _cached.is_empty():
		var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file == null:
			push_error("MapConfig: 无法读取 " + CONFIG_PATH)
			return {}
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("MapConfig: JSON 根节点必须是 Dictionary")
			return {}
		_cached = parsed as Dictionary
	return _cached.duplicate(true)
