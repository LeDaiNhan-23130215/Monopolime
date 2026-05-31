extends SceneTree


class AutoTeleportUI extends GameUI:
	var chooser_count := 0
	var target_index := 39

	func add_history(_text: String, _color: Color = Color.WHITE) -> void:
		pass

	func show_message(_text: String) -> void:
		pass

	func update_player_info(_players: Array) -> void:
		pass

	func show_toast_and_wait(_title: String, _text: String, _color: Color, _amount: int = 0, _duration: float = 0.9) -> void:
		pass

	func show_teleport_chooser(_player: Player, _board: Board) -> void:
		chooser_count += 1
		call_deferred("emit_signal", "teleport_cell_selected", target_index)


func _initialize() -> void:
	var controller := GameController.new()
	get_root().add_child(controller)

	var state := GameState.new()
	var player: Player = state.add_player(0, "P1")
	player.state.position = 39
	controller.game_state = state
	controller.ui = AutoTeleportUI.new()
	controller.board = _make_board()

	await controller.handle_landed_cell(player, 39)

	var failures: Array[String] = []
	if controller.ui.chooser_count != 1:
		failures.append("teleport chooser opened " + str(controller.ui.chooser_count) + " times for one landing")

	controller.free()
	if failures.is_empty():
		print("PASS check_teleport_no_self_loop")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _make_board() -> Board:
	var board := Board.new()
	for i in range(40):
		board.cell_positions.append(Vector2(i * 10, 0))
		var cell := Cell.new()
		cell.index = i
		cell.cell_name = "Cell " + str(i)
		cell.cell_type = "parking"
		board.cells.append(cell)
	board.cells[39].cell_name = "Du lich"
	board.cells[39].cell_type = "teleport"
	return board
