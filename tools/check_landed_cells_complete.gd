extends SceneTree


class AutoUI extends GameUI:
	func add_history(_text: String, _color: Color = Color.WHITE) -> void:
		pass

	func show_message(_text: String) -> void:
		pass

	func update_player_info(_players: Array) -> void:
		pass

	func show_buy_prompt(_player: Player, _cell: Cell) -> void:
		call_deferred("_emit_buy_declined")

	func _emit_buy_declined() -> void:
		if game_controller:
			game_controller.emit_signal("buy_decision_made", false)

	func show_transaction_popup(_from_player: Player, _to_player: Player, _amount: int, _reason: String) -> void:
		pass

	func show_card_and_wait(_title: String, _text: String, _color: Color, _amount: int = 0) -> void:
		pass

	func show_event_card_and_wait(_deck_title: String, _card: Dictionary, _color: Color, _amount: int = 0, _deck_counts := {}) -> void:
		pass

	func show_toast_and_wait(_title: String, _text: String, _color: Color, _amount: int = 0, _duration: float = 0.9) -> void:
		pass

	func show_card_popup(_title: String, _text: String, _color: Color, _amount: int = 0) -> void:
		pass

	func show_jail() -> void:
		pass

	func show_teleport_chooser(player: Player, board: Board) -> void:
		var target := 0
		for step in range(1, board.cells.size() + 1):
			var i := (player.state.position + step) % board.cells.size()
			if board.cells[i].cell_type != "teleport":
				target = i
				break
		call_deferred("emit_signal", "teleport_cell_selected", target)

	func show_money_float(_amount: int, _from_node: Node = null, _to_node: Node = null) -> void:
		pass

	func play_sfx(_key: String) -> void:
		pass


class TestController extends GameController:
	func move_player_to_position(player: Player, pos: int) -> void:
		player.state.update_position(pos)

	func move_player_to_position_with_teleport_effect(player: Player, pos: int) -> void:
		player.state.update_position(pos)

	func run_auction(_cell: Cell) -> void:
		pass


func _initialize() -> void:
	var controller := TestController.new()
	get_root().add_child(controller)
	var ui := AutoUI.new()
	controller.ui = ui
	ui.game_controller = controller

	var state := GameState.new()
	var player: Player = state.add_player(0, "P1")
	player.state.balance = 5000
	state.add_player(1, "P2")
	controller.game_state = state
	controller.board = _make_board()

	var failures: Array[String] = []
	for i in range(controller.board.cells.size()):
		player.state.position = i
		await controller.handle_landed_cell(player, i)

	controller.free()
	if failures.is_empty():
		print("PASS check_landed_cells_complete")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _make_board() -> Board:
	var board := Board.new()
	var configs := BoardData.get_cell_configs()
	for i in range(configs.size()):
		board.cell_positions.append(Vector2(i * 10, 0))
		var cell := Cell.new()
		cell.index = i
		cell.setup(configs[i])
		board.cells.append(cell)
	return board
