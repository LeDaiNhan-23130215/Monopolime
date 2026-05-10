extends Node
class_name GameController

signal turn_action_completed

var board: Board
var game_state: GameState
var dice: Dice
var ui: GameUI
var asset_manager: AssetManager

var final_result: DiceResult = null
var is_rolling := false

# Untyped để tránh circular dependency với EventHandler.gd
var _event_handler = null

func get_event_handler():
	if _event_handler == null:
		_event_handler = EventHandler.new(self)
		add_child(_event_handler)
	return _event_handler


func _on_asset_action_completed(action: String, success: bool, message: String):
	if ui:
		ui.show_message(message)


func start_turn():
	var player = get_current_player()
	if player.is_bankrupt():
		end_turn()
		return
	if ui:
		ui.show_turn(player.player_id)
		ui.refresh_player_panel(get_game_state_snapshot())


func roll_dice():
	if is_rolling:
		return
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

	# ══════════════════════════════════════════════════════════════════
	# JAIL (BR-16, BR-17)
	# ══════════════════════════════════════════════════════════════════
	if player.state.in_jail:
		player.state.jail_turns += 1

		if final_result.is_double:
			# BR-17: Tung được double → ra tù, không được thêm lượt
			print(player.name + " tung double – thoát tù!")
			player.state.set_in_jail(false)
			await move_player(player, final_result.total())
			await handle_landed_cell(player, player.state.position)
			# Ra tù bằng double không được đi thêm lượt

		elif player.state.jail_turns >= 3:
			# BR-17: Lượt 3 bắt buộc trả $50 rồi di chuyển
			print(player.name + " hết hạn tù – bắt buộc trả $50!")
			if ui:
				ui.show_message(player.name + " hết hạn tù! Trả $50 và di chuyển.")
			player.deduct_money(50)
			player.state.set_in_jail(false)
			await move_player(player, final_result.total())
			await handle_landed_cell(player, player.state.position)

		else:
			# Chưa double, chưa hết 3 lượt → ở lại
			print(player.name + " vẫn ở trong tù (lượt " + str(player.state.jail_turns) + "/3).")
			if ui:
				ui.show_message(player.name + " ở tù – lượt " + str(player.state.jail_turns) + "/3")

		is_rolling = false
		if ui:
			ui.set_roll_enabled(true)
		end_turn()
		return

	# ══════════════════════════════════════════════════════════════════
	# DOUBLE (BR-03)
	# ══════════════════════════════════════════════════════════════════
	if final_result.is_double:
		game_state.double_count += 1
		if ui:
			ui.show_double()
		if game_state.double_count >= 3:
			# BR-03: 3 lần double liên tiếp → vào tù
			await go_to_jail(player)
			game_state.double_count = 0
			is_rolling = false
			if ui:
				ui.set_roll_enabled(true)
			end_turn()
			return

	# ══════════════════════════════════════════════════════════════════
	# MOVE & LAND
	# ══════════════════════════════════════════════════════════════════
	await move_player(player, final_result.total())
	await handle_landed_cell(player, player.state.position)

	# ══════════════════════════════════════════════════════════════════
	# EXTRA TURN (double) – BR-03
	# ══════════════════════════════════════════════════════════════════
	if final_result.is_double:
		is_rolling = false
		if ui:
			ui.set_roll_enabled(true)
		start_turn()
		return

	game_state.double_count = 0
	is_rolling = false
	if ui:
		ui.set_roll_enabled(true)
	end_turn()


func move_player(player: Player, steps: int) -> void:
	for i in range(steps):
		var next_pos = (player.state.position + 1)
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


# BR-15: Vào tù → di chuyển về index 5 (Visiting Jail)
func go_to_jail(player: Player):
	player.state.set_in_jail(true)
	if ui:
		ui.show_jail()
	await move_player_to_position(player, 5)


func end_turn():
	auto_save_game()

	# Tìm người chơi tiếp theo chưa phá sản
	var next_player_found = false
	var safety = 0
	while not next_player_found and safety < game_state.players.size():
		game_state.current_player = (game_state.current_player + 1) % game_state.players.size()
		if not get_current_player().is_bankrupt():
			next_player_found = true
		safety += 1
	if next_player_found:
		start_turn()
	else:
		print("GAME OVER")


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

func get_offset(player_id: int) -> Vector2:
	var offsets = [
		Vector2(-10, -10), Vector2(10, -10),
		Vector2(-10, 10),  Vector2(10, 10)
	]
	return offsets[player_id % offsets.size()]


# ══════════════════════════════════════════════════════════════════════
# Cell Logic
# ══════════════════════════════════════════════════════════════════════
func handle_landed_cell(player: Player, cell_index: int):
	var cell = board.get_cell(cell_index)
	if not cell:
		return

	# ── Property ──────────────────────────────────────────────────────
	if cell is PropertyCell:
		var prop = cell as PropertyCell

		if prop.property_owner == null:
			# Chưa có chủ → mua / đấu giá
			if ui:
				ui.prompt_buy_or_auction(player, prop, asset_manager)
				await ui.ui_action_done
		elif prop.property_owner != player and not prop.is_mortgaged:
			# Trả tiền thuê
			process_payment(player, prop.property_owner, prop.get_current_rent(), prop.data.cell_name)
		elif prop.property_owner == player:
			# Đất của mình → quản lý tài sản
			if ui:
				ui.show_asset_management(player, asset_manager)
				await ui.ui_action_done
		return

	# ── Tax ───────────────────────────────────────────────────────────
	if cell.data is TaxData:
		player.deduct_money(cell.data.tax_amount)
		if ui:
			ui.show_message(player.name + " đóng thuế $" + str(cell.data.tax_amount))
		return

	# ── Chance ────────────────────────────────────────────────────────
	if cell is ChanceCell:
		if get_event_handler().handle_event(player, cell):
			await get_event_handler().event_finished
		return

	# ── Chest ─────────────────────────────────────────────────────────
	if cell is ChestCell:
		if get_event_handler().handle_event(player, cell):
			await get_event_handler().event_finished
		return

	# ── Go To Jail ────────────────────────────────────────────────────
	if cell.data is SpecialData:
		if cell.data.cell_type == CellType.Type.GO_TO_JAIL:
			await go_to_jail(player)


# ══════════════════════════════════════════════════════════════════════
# Financial
# ══════════════════════════════════════════════════════════════════════
func process_reward(player: Player, amount: int = 200):
	player.add_money(amount)
	if ui:
		ui.show_message("Qua GO nhận $" + str(amount))
	if ui:
		ui.refresh_player_panel(get_game_state_snapshot())


# Trả về snapshot trạng thái players để UI render bảng tài sản
func get_game_state_snapshot() -> Array:
	var snapshot = []
	for p in game_state.players:
		var prop_names: Array = []
		for cell in p.properties:
			if cell is PropertyCell:
				prop_names.append(cell.data.cell_name)
		snapshot.append({
			"id": p.player_id,
			"name": p.name,
			"balance": p.state.balance,
			"properties": prop_names,
			"in_jail": p.state.in_jail
		})
	return snapshot


func process_payment(payer: Player, receiver: Player, amount: int, _reason: String):
	if payer.state.balance >= amount:
		payer.deduct_money(amount)
		if receiver:
			receiver.add_money(amount)
	else:
		handle_insufficient_funds(payer, receiver, amount)
	emit_signal("turn_action_completed")


func handle_insufficient_funds(payer: Player, receiver: Player, amount: int):
	if payer.get_total_capacity() < amount:
		handle_bankruptcy(payer, receiver)
	elif ui:
		ui.request_mortgage(payer, amount - payer.state.balance)


func handle_bankruptcy(debtor: Player, creditor: Player):
	print(debtor.name, " PHÁ SẢN!")
	debtor.transfer_all_assets_to(creditor)
	board.remove_player_token(debtor)
	emit_signal("turn_action_completed")


# ══════════════════════════════════════════════════════════════════════
# Asset Management shortcuts (gọi từ UI)
# ══════════════════════════════════════════════════════════════════════
func player_buy_property(player: Player, cell: PropertyCell) -> bool:
	if asset_manager == null: return false
	return asset_manager.buy_property(player, cell)

func player_build_house(player: Player, cell: PropertyCell) -> bool:
	if asset_manager == null: return false
	return asset_manager.build_house(player, cell)

func player_mortgage(player: Player, cell: PropertyCell) -> bool:
	if asset_manager == null: return false
	return asset_manager.mortgage_property(player, cell)

func player_redeem(player: Player, cell: PropertyCell) -> bool:
	if asset_manager == null: return false
	return asset_manager.redeem_property(player, cell)

func player_sell_property(seller: Player, buyer: Player, cell: PropertyCell, price: int) -> bool:
	if asset_manager == null: return false
	return asset_manager.sell_property(seller, buyer, cell, price)

func player_trade(
	proposer: Player, receiver: Player,
	offer_cells: Array, offer_money: int,
	request_cells: Array, request_money: int
) -> bool:
	if asset_manager == null: return false
	return asset_manager.trade_property(
		proposer, receiver,
		offer_cells, offer_money,
		request_cells, request_money
	)
