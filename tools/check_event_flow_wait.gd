extends SceneTree


class StubUI extends GameUI:
	func show_message(_text: String) -> void:
		pass

	func show_toast_and_wait(_title: String, _text: String, _color: Color, _amount: int = 0, _duration: float = 0.9) -> void:
		pass

	func add_history(_text: String, _color: Color = Color.WHITE) -> void:
		pass

	func update_player_info(_players: Array) -> void:
		pass


class TrackingController extends GameController:
	var landed_started := false
	var landed_finished := false

	func move_player_to_position(player: Player, pos: int) -> void:
		player.state.update_position(pos)

	func handle_landed_cell(_player: Player, _cell_index: int) -> void:
		landed_started = true
		await Engine.get_main_loop().process_frame
		landed_finished = true


func _initialize() -> void:
	var controller := TrackingController.new()
	get_root().add_child(controller)

	var state := GameState.new()
	var player: Player = state.add_player(0, "P1")
	controller.game_state = state
	controller.ui = StubUI.new()
	controller.board = _make_board()

	var handler := EventHandler.new(controller)
	controller.add_child(handler)
	await handler._process_card(player, {
		"action": "move_forward",
		"steps": 1,
		"text": "test move",
	})

	var failures: Array[String] = []
	if not controller.landed_started:
		failures.append("event move did not start handling the arrival cell")
	if not controller.landed_finished:
		failures.append("event move returned before the arrival cell finished")

	controller.free()
	if failures.is_empty():
		print("PASS check_event_flow_wait")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _make_board() -> Board:
	var board := Board.new()
	for i in range(2):
		board.cell_positions.append(Vector2(i * 10, 0))
		var cell := Cell.new()
		cell.index = i
		cell.cell_name = "Cell " + str(i)
		cell.cell_type = "parking"
		board.cells.append(cell)
	return board
