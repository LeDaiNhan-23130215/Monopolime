extends Node
class_name GameController

# Tín hiệu dùng để "đóng băng" lượt đi
signal turn_action_completed

var board: Board
var game_state: GameState
var dice: Dice
var ui: GameUI

var final_result: DiceResult = null

func start_turn():
	print("\n===== TURN =====")
	var player = get_current_player()
	
	if player.is_bankrupt():
		end_turn()
		return
		
	print("Player:", player.name)
	ui.show_turn(player.player_id)
	
	if player.state.in_jail:
		print(player.name + " đang ở tù! Cần đổ ra Double để thoát.")

func roll_dice():
	final_result = dice.roll()
	ui.start_dice_animation()

func resolve_roll():
	var player = get_current_player()
	ui.show_result(final_result)

	# --- XỬ LÝ KHI Ở TÙ ---
	if player.state.in_jail:
		if final_result.is_double:
			print(player.name + " đổ ra Double! Thoát tù.")
			player.state.set_in_jail(false)
			await move_player(player, final_result.total())
			await handle_landed_cell(player, player.state.position)
		else:
			print(player.name + " không ra Double.")
		end_turn()
		return

	# --- XỬ LÝ LƯỢT BÌNH THƯỜNG ---
	if final_result.is_double:
		game_state.double_count += 1
		ui.show_double()
		if game_state.double_count < 3:
			await move_player(player, final_result.total())
			await handle_landed_cell(player, player.state.position)
			start_turn() # Được đi tiếp
			return
		else:
			go_to_jail(player)
			end_turn()
			return
	else:
		game_state.double_count = 0
		await move_player(player, final_result.total())
		await handle_landed_cell(player, player.state.position)
		end_turn()

func move_player(player: Player, steps: int) -> void:
	for i in range(steps):
		var next_pos = player.state.position + 1
		if next_pos >= game_state.board_size:
			process_reward(player)
		next_pos %= game_state.board_size
		
		player.state.update_position(next_pos)
		var world_pos = board.get_cell_position(next_pos)
		var offset = Vector2(player.player_id * 10, 0)
		
		# Đảm bảo token tồn tại trước khi di chuyển
		if player.token:
			player.token.move_to(world_pos + offset)
		
		await get_tree().create_timer(0.2).timeout

func go_to_jail(player: Player):
	player.state.set_in_jail(true)
	player.state.update_position(10) # Ví dụ ô 10 là tù
	ui.show_jail()

func end_turn():
	auto_save_game()

	# Tìm người chơi tiếp theo chưa phá sản
	var next_player_found = false
	var safety_counter = 0 
	while not next_player_found and safety_counter < game_state.players.size():
		game_state.current_player = (game_state.current_player + 1) % game_state.players.size()
	
		if not get_current_player().is_bankrupt():
			next_player_found = true
		safety_counter += 1

	if next_player_found:
		start_turn()
	else:
		print("GAME OVER!")

func get_current_player() -> Player:
	return game_state.players[game_state.current_player]


func save_game(save_id: int) -> void:
	if ui and ui.has_method("is_dice_rolling") and ui.is_dice_rolling():
		if ui.has_method("show_message"):
			ui.show_message("Cannot save while dice is rolling")
		return

	var storage_status = StorageService.check_storage_availability()
	if not storage_status.get("ok", false):
		if ui.has_method("show_message"):
			ui.show_message("Insufficient Storage")
		return

	var game_data = {
		"players_state": _collect_players_state(),
		"current_player": game_state.current_player,
		"double_count": game_state.double_count
	}

	if StorageService.save_file(save_id, game_data):
		if ui.has_method("show_message"):
			ui.show_message("Saved Slot %02d" % [save_id])
	else:
		if ui.has_method("show_message"):
			ui.show_message("Save failed at Slot %02d" % [save_id])


func load_game(save_id: int) -> void:
	var slot: SaveSlot = StorageService.load_file(save_id)
	if slot.is_empty():
		if ui.has_method("show_message"):
			ui.show_message("Slot %02d is empty" % [save_id])
		return

	var loaded_data = StorageService.load_game_data(save_id)
	if loaded_data.is_empty() or not loaded_data.has("players_state"):
		if ui.has_method("show_message"):
			ui.show_message("Corrupted Data")
		return

	var players_state_data = loaded_data.get("players_state", [])
	if typeof(players_state_data) != TYPE_ARRAY:
		if ui.has_method("show_message"):
			ui.show_message("Corrupted Data")
		return

	if not loaded_data.has("current_player") or not loaded_data.has("double_count"):
		if ui.has_method("show_message"):
			ui.show_message("Corrupted Data")
		return

	if not _apply_players_state(players_state_data):
		if ui.has_method("show_message"):
			ui.show_message("Corrupted Data")
		return

	game_state.current_player = int(loaded_data.get("current_player", game_state.current_player))
	game_state.double_count = int(loaded_data.get("double_count", game_state.double_count))

	_refresh_player_tokens_from_state()

	if ui.has_method("show_message"):
		ui.show_message("Loaded Slot %02d (%s)" % [save_id, slot.date_save])


func auto_save_game() -> void:
	var storage_status = StorageService.check_storage_availability()
	if not storage_status.get("ok", false):
		return

	var game_data = {
		"players_state": _collect_players_state(),
		"current_player": game_state.current_player,
		"double_count": game_state.double_count
	}

	if StorageService.save_auto(game_data) and ui.has_method("show_message"):
		ui.show_message("Auto-save complete")


func _collect_players_state() -> Array:
	# TODO(UC-03): Extend saved payload when property/building/card systems are finalized.
	var players_state_data: Array = []
	for player in game_state.players:
		players_state_data.append({
			"player_id": player.player_id,
			"position": player.state.position,
			"balance": player.state.balance,
			"in_jail": player.state.in_jail,
			"bankrupt": player.state.bankrupt
		})
	return players_state_data


func _apply_players_state(players_state_data: Array) -> bool:
	# TODO(UC-03): Restore property/building/card states when those domains are implemented.
	var by_id := {}
	for entry in players_state_data:
		if typeof(entry) != TYPE_DICTIONARY:
			return false
		if not entry.has("player_id"):
			return false
		by_id[int(entry.get("player_id", -1))] = entry

	for player in game_state.players:
		if not by_id.has(player.player_id):
			continue

		var state_data = by_id[player.player_id]
		player.state.position = int(state_data.get("position", player.state.position))
		player.state.balance = int(state_data.get("balance", player.state.balance))
		player.state.in_jail = bool(state_data.get("in_jail", player.state.in_jail))
		player.state.bankrupt = bool(state_data.get("bankrupt", player.state.bankrupt))

	return true


func _refresh_player_tokens_from_state() -> void:
	for player in game_state.players:
		if not player.token:
			continue
		var world_pos = board.get_cell_position(player.state.position)
		var offset = Vector2(player.player_id * 10, 0)
		player.token.position = world_pos + offset

# --- HÀM XỬ LÝ TÀI CHÍNH ---

func handle_landed_cell(player: Player, cell_index: int):
	var cell = board.get_cell(cell_index) 
	if not cell: return
	
	if cell.cell_owner == null and cell.price > 0:
		print("Ô đất trống.")
		# Logic mua đất sẽ thêm ở đây
	elif cell.cell_owner != null and cell.cell_owner != player and not cell.is_mortgaged:
		var rent_amount = cell.get_current_rent() 
		
		if player.state.balance >= rent_amount:
			process_payment(player, cell.cell_owner, rent_amount, cell.cell_name)
		else:
			handle_insufficient_funds(player, cell.cell_owner, rent_amount)
			await self.turn_action_completed 

func process_reward(player: Player, amount: int = 200):
	player.add_money(amount)
	if ui.has_method("show_message"):
		ui.show_message("Qua ô GO! Nhận $" + str(amount)) 

func process_payment(payer: Player, beneficiary: Player, amount: int, reason: String):
	if payer.state.balance >= amount: 
		execute_transaction(payer, beneficiary, amount)
	else:
		handle_insufficient_funds(payer, beneficiary, amount)

func execute_transaction(payer: Player, beneficiary: Player, amount: int):
	payer.deduct_money(amount) 
	if beneficiary:
		beneficiary.add_money(amount) 
	emit_signal("turn_action_completed")

func handle_insufficient_funds(payer: Player, beneficiary: Player, amount: int):
	var total_cap = payer.get_total_capacity()
	if total_cap < amount: 
		handle_bankruptcy(payer, beneficiary)
	else:
		if ui.has_method("request_mortgage"):
			ui.request_mortgage(payer, amount - payer.state.balance)

func handle_bankruptcy(debtor: Player, creditor: Player):
	print(debtor.name + " PHÁ SẢN!") 
	debtor.transfer_all_assets_to(creditor) 
	if board.has_method("remove_player_token"):
		board.remove_player_token(debtor)
	emit_signal("turn_action_completed")
