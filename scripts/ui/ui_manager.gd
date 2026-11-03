class_name UIManager
extends CanvasLayer
## 界面总控：创建 HUD / 标题 / 暂停 / 结算，处理 ESC 暂停与按钮流程。
## 本节点在暂停时仍处理输入，保证任何状态下菜单按钮都能用。

var manager: GameManager
var hud: GameHUD
var start_screen: StartScreen
var pause_screen: PauseScreen
var results_screen: ResultsScreen
var theme: Theme


func setup(manager_node: GameManager, player: Player, economy: EconomySystem, cooking: CookingSystem,
		customer_queue: CustomerQueue, interaction: InteractionSystem, order_system: OrderSystem) -> void:
	manager = manager_node
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiKit.build_theme()

	hud = GameHUD.new()
	hud.theme = theme
	add_child(hud)
	hud.setup(manager, player, economy, cooking, customer_queue, interaction, order_system)
	hud.visible = false

	start_screen = StartScreen.new()
	start_screen.theme = theme
	add_child(start_screen)
	start_screen.visible = false
	start_screen.start_requested.connect(_on_start_requested)

	pause_screen = PauseScreen.new()
	pause_screen.theme = theme
	add_child(pause_screen)
	pause_screen.visible = false
	pause_screen.resume_requested.connect(_on_resume)
	pause_screen.restart_requested.connect(_on_restart)
	pause_screen.quit_requested.connect(_on_quit)

	results_screen = ResultsScreen.new()
	results_screen.theme = theme
	add_child(results_screen)
	results_screen.visible = false
	results_screen.restart_requested.connect(_on_restart)
	results_screen.title_requested.connect(_on_back_to_title)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if manager and (manager.state == GameManager.State.PLAYING or manager.state == GameManager.State.PAUSED):
			get_viewport().set_input_as_handled()
			manager.toggle_pause()


func show_title() -> void:
	hud.visible = false
	start_screen.visible = true
	pause_screen.visible = false
	results_screen.visible = false


func hide_title() -> void:
	start_screen.visible = false


func show_hud() -> void:
	hud.visible = true


func show_pause() -> void:
	pause_screen.visible = true


func hide_pause() -> void:
	pause_screen.visible = false


func hide_results() -> void:
	results_screen.visible = false


func show_results(data: Dictionary) -> void:
	hud.visible = false
	results_screen.set_results(data)
	results_screen.visible = true


func _on_start_requested() -> void:
	manager.start_shift()


func _on_resume() -> void:
	manager.resume_game()


func _on_restart() -> void:
	manager.restart_round()


func _on_quit() -> void:
	SceneManager.quit_game()


func _on_back_to_title() -> void:
	SceneManager.back_to_title()
