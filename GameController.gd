extends Node
class_name GameController

signal turn_action_completed

var board: Board
var game_state: GameState
var dice: Dice
var ui: GameUI

var final_result: DiceResult = null
var is_rolling := false

var event_handler: EventHandler = null

func get_event_handler() -> EventHandler:
	if event_handler == null:
		event_handler = EventHandler.new(self)
		add_child(event_handler)
	return event_handler


func start_turn():
	print("\n===== TURN =====")

	var player = get_current_player()

	if player.is_bankrupt():
		end_turn()
		return

	print("Player:", player.name)
	ui.show_turn(player.player_id)

	if player.state.in_jail:
		print(player.name + " đang ở tù! Cần đổ Double để thoát.")


func roll_dice():
	if is_rolling:
		return

	print("ROLL DICE CALLED")

	is_rolling = true
	ui.set_roll_enabled(false)

	final_result = dice.roll()
	ui.start_dice_animation()


func resolve_roll():
	var player = get_current_player()

	ui.show_result(final_result)

	# =========================
	# Xử lý khi ở tù
	# =========================

	if player.state.in_jail:
		if final_result.is_double:
			print(player.name + " thoát tù!")

			player.state.set_in_jail(false)

			await move_player(player, final_result.total())
			await handle_landed_cell(player, player.state.position)
		else:
			print(player.name + " không ra Double.")

		end_turn()

		is_rolling = false
		ui.set_roll_enabled(true)

		return

	# =========================
	# Double
	# =========================

	if final_result.is_double:
		game_state.double_count += 1

		ui.show_double()

		if game_state.double_count >= 3:
			go_to_jail(player)

			game_state.double_count = 0

			end_turn()

			is_rolling = false
			ui.set_roll_enabled(true)

			return

	# =========================
	# Move player
	# =========================

	await move_player(player, final_result.total())

	await handle_landed_cell(player, player.state.position)

	# =========================
	# Extra turn nếu double
	# =========================

	if final_result.is_double:
		is_rolling = false
		ui.set_roll_enabled(true)

		start_turn()
		return

	# =========================
	# End turn bình thường
	# =========================

	game_state.double_count = 0

	end_turn()

	is_rolling = false
	ui.set_roll_enabled(true)


func move_player(player: Player, steps: int) -> void:
	await move_player_step_by_step(player, steps)


func move_player_step_by_step(player: Player, steps: int) -> void:
	for i in range(steps):

		var next_pos = player.state.position + 1

		if next_pos >= game_state.board_size:
			process_reward(player)

		next_pos %= game_state.board_size

		player.state.update_position(next_pos)

		var world_pos = board.get_cell_position(next_pos)

		var offset = get_offset(player.player_id)

		if player.token:
			await player.token.move_to(world_pos + offset)

		await get_tree().create_timer(0.1).timeout


func move_player_to_position(player: Player, pos: int) -> void:
	player.state.update_position(pos)

	var world_pos = board.get_cell_position(pos)

	var offset = get_offset(player.player_id)

	if player.token:
		await player.token.move_to(world_pos + offset)


func go_to_jail(player: Player):
	print("GO TO JAIL!")

	player.state.set_in_jail(true)

	ui.show_jail()

	await move_player_to_position(player, 10)


func end_turn():

	var next_player_found = false
	var safety_counter = 0

	while not next_player_found and safety_counter < game_state.players.size():

		game_state.current_player = (
			game_state.current_player + 1
		) % game_state.players.size()

		if not get_current_player().is_bankrupt():
			next_player_found = true

		safety_counter += 1

	if next_player_found:
		start_turn()
	else:
		print("GAME OVER!")


func get_current_player() -> Player:
	return game_state.players[game_state.current_player]


func get_offset(player_id: int) -> Vector2:
	var offsets = [
		Vector2(-10, -10),
		Vector2(10, -10),
		Vector2(-10, 10),
		Vector2(10, 10)
	]

	return offsets[player_id % offsets.size()]


func process_current_cell(player: Player):
	var cell = board.get_cell(player.state.position)

	if cell:
		print("Player landed on:", cell.cell_name)


# =========================
# Financial
# =========================

func handle_landed_cell(player: Player, cell_index: int):

	var cell = board.get_cell(cell_index)

	if not cell:
		return

	# Xử lý nếu là ô sự kiện
	if get_event_handler().handle_event(player, cell):
		await get_event_handler().event_finished
		return

	# Ô đất trống
	if cell.cell_owner == null and cell.price > 0:
		print("Ô đất trống.")

	# Trả tiền thuê
	elif (
		cell.cell_owner != null
		and cell.cell_owner != player
		and not cell.is_mortgaged
	):

		var rent_amount = cell.get_current_rent()

		if player.state.balance >= rent_amount:
			process_payment(
				player,
				cell.cell_owner,
				rent_amount,
				cell.cell_name
			)
		else:
			handle_insufficient_funds(
				player,
				cell.cell_owner,
				rent_amount
			)

			await self.turn_action_completed


func process_reward(player: Player, amount: int = 200):
	player.add_money(amount)

	if ui.has_method("show_message"):
		ui.show_message(
			"Qua ô GO! Nhận $" + str(amount)
		)


func process_payment(
	payer: Player,
	beneficiary: Player,
	amount: int,
	reason: String
):
	if payer.state.balance >= amount:
		execute_transaction(
			payer,
			beneficiary,
			amount
		)
	else:
		handle_insufficient_funds(
			payer,
			beneficiary,
			amount
		)


func execute_transaction(
	payer: Player,
	beneficiary: Player,
	amount: int
):
	payer.deduct_money(amount)

	if beneficiary:
		beneficiary.add_money(amount)

	emit_signal("turn_action_completed")


func handle_insufficient_funds(
	payer: Player,
	beneficiary: Player,
	amount: int
):
	var total_cap = payer.get_total_capacity()

	if total_cap < amount:
		handle_bankruptcy(payer, beneficiary)
	else:
		if ui.has_method("request_mortgage"):
			ui.request_mortgage(
				payer,
				amount - payer.state.balance
			)


func handle_bankruptcy(
	debtor: Player,
	creditor: Player
):
	print(debtor.name + " PHÁ SẢN!")

	debtor.transfer_all_assets_to(creditor)

	if board.has_method("remove_player_token"):
		board.remove_player_token(debtor)

	emit_signal("turn_action_completed")
