class_name HomeIslandPlacement
extends VisualSamplePlacement
## Adds right-click demolition on top of the existing placement/move controller.


func demolish_at(world_pos: Vector2) -> bool:
	if build_mode or is_dragging():
		return false
	var object: VisualSamplePlaceable = game.get_movable_at_cell(grid.world_to_cell(world_pos))
	if object == null:
		return false
	var object_name := str(object.def.get("name", "物件"))
	game.remove_placeable(object)
	game.notify("已拆除 %s。" % object_name, Painter.BROWN)
	return true
