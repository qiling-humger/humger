extends Node
## 场景级流程：重开本局、退出。保持极薄，避免把玩法逻辑塞进 autoload。

const MAIN_SCENE := "res://scenes/Main.tscn"


func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func back_to_title() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
