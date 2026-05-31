extends SceneTree


class StubUI extends GameUI:
	var roll_enabled_calls: Array[bool] = []

	func play_sfx(_key: String) -> void:
		pass

	func show_game_over(_winner: Player) -> void:
		pass

	func show_game_over_with_rankings(_winner: Player, _rankings: Array) -> void:
		pass

	func set_roll_enabled(enabled: bool) -> void:
		roll_enabled_calls.append(enabled)

	func show_turn(_player_index: int) -> void:
		pass

	func show_message(_text: String) -> void:
		pass

	func add_history(_text: String, _color: Color = Color.WHITE) -> void:
		pass

	func update_player_info(_players: Array) -> void:
		pass


func _initialize() -> void:
	var failures: Array[String] = []
	_check_end_turn_is_blocked_while_roll_is_active(failures)
	_check_end_turn_is_allowed_when_idle(failures)

	if failures.is_empty():
		print("PASS check_turn_flow_guard")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _make_controller() -> GameController:
	var controller := GameController.new()
	var state := GameState.new()
	state.add_player(0, "P1")
	state.add_player(1, "P2")
	controller.game_state = state
	controller.ui = StubUI.new()
	return controller


func _check_end_turn_is_blocked_while_roll_is_active(failures: Array[String]) -> void:
	var controller := _make_controller()
	if not controller.has_method("request_end_turn"):
		failures.append("GameController is missing request_end_turn guard API")
		return
	controller.is_rolling = true
	controller.request_end_turn()

	if controller.game_state.current_player != 0:
		failures.append("request_end_turn advanced player while dice roll was active")
	controller.free()


func _check_end_turn_is_allowed_when_idle(failures: Array[String]) -> void:
	var controller := _make_controller()
	if not controller.has_method("request_end_turn"):
		failures.append("GameController is missing request_end_turn guard API")
		return
	controller.request_end_turn()

	if controller.game_state.current_player != 1:
		failures.append("request_end_turn did not advance player while controller was idle")
	controller.free()
