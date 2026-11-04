class_name MapInventory
extends RefCounted
## 地图原型的运行时资源库存。开局全部为 0，只有采集才会增加。

signal changed(resource_id: String, amount: int, snapshot: Dictionary)

var order: Array[String] = []
var counts: Dictionary = {}


func setup(resource_order: Array, _types: Dictionary) -> void:
	order.clear()
	counts.clear()
	for item in resource_order:
		var id := str(item)
		order.append(id)
		counts[id] = 0


func add(resource_id: String, amount: int) -> void:
	if amount <= 0:
		return
	counts[resource_id] = int(counts.get(resource_id, 0)) + amount
	changed.emit(resource_id, amount, counts.duplicate())


func get_count(resource_id: String) -> int:
	return int(counts.get(resource_id, 0))


func snapshot() -> Dictionary:
	return counts.duplicate()


func total_gathered() -> int:
	var total := 0
	for id in order:
		if id == "coins":
			continue
		total += get_count(id)
	return total
