extends Node
class_name GameController

signal turn_action_completed

var board: Board
var game_state: GameState
var dice: Dice
var ui: GameUI

var final_result: DiceResult = null
var is_rolling := false


func start_turn():
	print("\n===== TURN =====")

	var player = get_current_player()

	if player.is_bankrupt():
		end_turn()
		return

	print("Player:", player.name)

	if ui:
		ui.show_turn(player.player_id)

	if player.state.in_jail:
		print(player.name + " đang ở tù!")


func roll_dice():

	if is_rolling:
		return

	print("ROLL DICE CALLED")

	is_rolling = true

	if ui:
		ui.set_roll_enabled(false)

	final_result = dice.roll()

	if ui:
		ui.start_dice_animation()


func resolve_roll():

	var player = get_current_player()

	if ui:
		ui.show_result(final_result)

	# =========================
	# Jail
	# =========================

	if player.state.in_jail:

		if final_result.is_double:

			print(player.name + " thoát tù!")

			player.state.set_in_jail(false)

			await move_player(
				player,
				final_result.total()
			)

			await handle_landed_cell(
				player,
				player.state.position
			)

		else:
			print(player.name + " không ra double.")

		end_turn()

		is_rolling = false

		if ui:
			ui.set_roll_enabled(true)

		return


	# =========================
	# Double
	# =========================

	if final_result.is_double:

		game_state.double_count += 1

		if ui:
			ui.show_double()

		if game_state.double_count >= 3:

			await go_to_jail(player)

			game_state.double_count = 0

			end_turn()

			is_rolling = false

			if ui:
				ui.set_roll_enabled(true)

			return


	# =========================
	# Move
	# =========================

	await move_player(
		player,
		final_result.total()
	)

	await handle_landed_cell(
		player,
		player.state.position
	)


	# =========================
	# Extra Turn
	# =========================

	if final_result.is_double:

		is_rolling = false

		if ui:
			ui.set_roll_enabled(true)

		start_turn()

		return


	game_state.double_count = 0

	end_turn()

	is_rolling = false

	if ui:
		ui.set_roll_enabled(true)


func move_player(
	player: Player,
	steps: int
) -> void:

	for i in range(steps):

		var next_pos = (
			player.state.position + 1
		)

		if next_pos >= game_state.board_size:
			process_reward(player)

		next_pos %= game_state.board_size

		player.state.update_position(
			next_pos
		)

		var world_pos = board.get_cell_position(
			next_pos
		)

		var offset = get_offset(
			player.player_id
		)

		if player.token:
			await player.token.move_to(
				world_pos + offset
			)

		await get_tree().create_timer(
			0.1
		).timeout


func move_player_to_position(
	player: Player,
	pos: int
) -> void:

	player.state.update_position(pos)

	var world_pos = board.get_cell_position(pos)

	var offset = get_offset(
		player.player_id
	)

	if player.token:
		await player.token.move_to(
			world_pos + offset
		)


func go_to_jail(player: Player):

	print("GO TO JAIL!")

	player.state.set_in_jail(true)

	if ui:
		ui.show_jail()

	await move_player_to_position(
		player,
		10
	)


func end_turn():

	var next_player_found = false
	var safety = 0

	while (
		not next_player_found
		and safety < game_state.players.size()
	):

		game_state.current_player = (
			game_state.current_player + 1
		) % game_state.players.size()

		if not get_current_player().is_bankrupt():
			next_player_found = true

		safety += 1

	if next_player_found:
		start_turn()
	else:
		print("GAME OVER")


func get_current_player() -> Player:

	return game_state.players[
		game_state.current_player
	]


func get_offset(
	player_id: int
) -> Vector2:

	var offsets = [

		Vector2(-10, -10),
		Vector2(10, -10),

		Vector2(-10, 10),
		Vector2(10, 10)
	]

	return offsets[
		player_id % offsets.size()
	]


# =========================
# Cell Logic
# =========================

func handle_landed_cell(
	player: Player,
	cell_index: int
):

	var cell = board.get_cell(
		cell_index
	)

	if not cell:
		return


	# =========================
	# Property
	# =========================

	if cell is PropertyCell:

		var property_cell = (
			cell as PropertyCell
		)

		var property_data = (
			property_cell.data
			as PropertyData
		)

		# Chưa có chủ
		if property_cell.property_owner == null:

			print(
				"Có thể mua: ",
				property_data.cell_name
			)

			return

		# Trả tiền thuê
		if (
			property_cell.property_owner
			!= player
			and not property_cell.is_mortgaged
		):

			var rent = (
				property_cell.get_current_rent()
			)

			process_payment(
				player,
				property_cell.property_owner,
				rent,
				property_data.cell_name
			)

			return


	# =========================
	# Tax
	# =========================

	if cell.data is TaxData:

		var tax_data = (
			cell.data as TaxData
		)

		print(
			"Đóng thuế: ",
			tax_data.tax_amount
		)

		player.deduct_money(
			tax_data.tax_amount
		)

		return


	# =========================
	# Chance
	# =========================

	if cell.data is ChanceData:

		print("Rút Chance")

		return


	# =========================
	# Chest
	# =========================

	if cell.data is ChestData:

func process_reward(player: Player, amount: int = 200):
	player.add_money(amount)

	if ui.has_method("show_message"):
		ui.show_message("Qua ô GO! Nhận $" + str(amount))
		
	if has_node("MoneySound"):
		$MoneySound.play()

	# --- HIỆN CHỮ MÀU XANH BAY LÊN ---
	if player.token and player.token.has_method("show_floating_money"):
		player.token.show_floating_money(amount)

	if ui.has_method("update_all_balances"):
		ui.update_all_balances(game_state.players)

func process_payment(
	payer: Player,
	receiver: Player,
	amount: int,
	_reason: String
):

	if payer.state.balance >= amount:

		payer.deduct_money(amount)

		if receiver:
			receiver.add_money(amount)

	else:

		handle_insufficient_funds(
			payer,
			receiver,
			amount
		)


func execute_transaction(
	payer: Player,
	beneficiary: Player,
	amount: int
):
	payer.deduct_money(amount)
	
	# --- HIỆN CHỮ MÀU ĐỎ CHO NGƯỜI BỊ TRỪ TIỀN ---
	if payer.token and payer.token.has_method("show_floating_money"):
		payer.token.show_floating_money(-amount)

	if beneficiary:
		beneficiary.add_money(amount)
		# --- HIỆN CHỮ MÀU XANH CHO NGƯỜI NHẬN TIỀN ---
		if beneficiary.token and beneficiary.token.has_method("show_floating_money"):
			beneficiary.token.show_floating_money(amount)

	if has_node("MoneySound"):
		$MoneySound.play()

	if ui.has_method("update_all_balances"):
		ui.update_all_balances(game_state.players)

	emit_signal("turn_action_completed")

func handle_insufficient_funds(
	payer: Player,
	receiver: Player,
	amount: int
):

	var total = payer.get_total_capacity()

	if total < amount:

		handle_bankruptcy(
			payer,
			receiver
		)


func handle_bankruptcy(
	debtor: Player,
	creditor: Player
):
	print(debtor.name + " PHÁ SẢN!")
	debtor.state.set_bankrupt(true)
	debtor.transfer_all_assets_to(creditor)

	print(
		debtor.name,
		" PHÁ SẢN!"
	)

	debtor.transfer_all_assets_to(
		creditor
	)

	board.remove_player_token(
		debtor
	)

	if ui.has_method("show_bankruptcy_ui"):
	
		await ui.show_bankruptcy_ui(debtor.name)
		
	if ui.has_method("update_all_balances"):
		ui.update_all_balances(game_state.players)
		
	var active_players = []
	for p in game_state.players:
		if not p.is_bankrupt():
			active_players.append(p)
			
	if active_players.size() == 1:
		print("GAME OVER! Người chiến thắng: ", active_players[0].name)
		if ui.has_method("show_winner_ui"):
			ui.show_winner_ui(active_players[0].name)
			return 

	emit_signal("turn_action_completed")
	emit_signal(
		"turn_action_completed"
	)
