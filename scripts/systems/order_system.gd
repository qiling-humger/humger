class_name OrderSystem
extends Node
## 生成订单、顾客外观数据，并做订单正确性校验。

var manager: Node
var rng := RandomNumberGenerator.new()


func setup(manager_node: Node) -> void:
	manager = manager_node
	rng.randomize()


func generate_order(recipe_id: String = "", sauce_id: String = "") -> Dictionary:
	var recipes: Array = GameData.config().get("recipes", [])
	var sauces: Array = GameData.config().get("sauces", [])
	var recipe: Dictionary = {}
	if not recipe_id.is_empty():
		for entry in recipes:
			if str(entry.get("id", "")) == recipe_id:
				recipe = entry
				break
	if recipe.is_empty():
		recipe = GameData.weighted_pick(rng, recipes)
	var sauce: Dictionary = {}
	if not sauce_id.is_empty():
		for entry in sauces:
			if str(entry.get("id", "")) == sauce_id:
				sauce = entry
				break
	if sauce.is_empty():
		sauce = GameData.weighted_pick(rng, sauces)
	return {
		"recipe_id": str(recipe.get("id", "classic")),
		"recipe_name": str(recipe.get("name", "经典热狗")),
		"sausages": int(recipe.get("sausages", 1)),
		"sauce_id": str(sauce.get("id", "ketchup")),
		"sauce_name": str(sauce.get("name", "番茄酱")),
		"sauce_color": str(sauce.get("color", "#D9534F")),
		"ketchup": bool(sauce.get("ketchup", false)),
		"mustard": bool(sauce.get("mustard", false)),
		"base_price": int(recipe.get("base_price", 22)),
	}


func generate_customer_profile() -> Dictionary:
	var species: Array = GameData.section("customers").get("species", [])
	var entry: Dictionary = {}
	if species.is_empty():
		entry = {"id": "cat", "name": "咪咪", "fur": "#F4C98F", "accent": "#D89462", "shirt": "#9DD8C0"}
	else:
		entry = species[rng.randi_range(0, species.size() - 1)]
	return {
		"species": str(entry.get("id", "cat")),
		"name": str(entry.get("name", "顾客")),
		"fur": str(entry.get("fur", "#F4C98F")),
		"accent": str(entry.get("accent", "#D89462")),
		"shirt": str(entry.get("shirt", "#9DD8C0")),
	}


func describe_order(order: Dictionary) -> String:
	return "%s · %s" % [str(order.get("recipe_name", "热狗")), str(order.get("sauce_name", "原味"))]


func validate_order(order: Dictionary, item: Dictionary) -> Dictionary:
	if item.is_empty() or str(item.get("type", "")) != "hotdog":
		return {"ok": false, "reason": "手上还没有做好的热狗。"}
	var required_count := int(order.get("sausages", 1))
	var actual_count := int(item.get("count", 1))
	if actual_count != required_count:
		return {
			"ok": false,
			"reason": "订单要的是%s，肠的数量不对。" % str(order.get("recipe_name", "热狗")),
		}
	var quality_id := str(item.get("quality", "raw"))
	if quality_id in ["raw", "heating"]:
		return {"ok": false, "reason": "这根还没熟透，顾客可不敢吃。"}
	if quality_id == "burnt":
		return {"ok": false, "reason": "这根已经烤焦了，只能丢掉。"}
	var sauces: Dictionary = item.get("sauces", {})
	var ketchup_ok := bool(sauces.get("ketchup", false)) == bool(order.get("ketchup", false))
	var mustard_ok := bool(sauces.get("mustard", false)) == bool(order.get("mustard", false))
	if not ketchup_ok or not mustard_ok:
		return {
			"ok": false,
			"reason": "酱料不对：订单要的是%s。" % str(order.get("sauce_name", "原味")),
		}
	return {"ok": true, "reason": "", "quality": quality_id}
