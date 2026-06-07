extends Node
class_name GameController

signal turn_action_completed
signal auction_choice_made

var board: Board
var game_state: GameState
var dice: Dice
var ui: GameUI
var asset_manager: AssetManager

var final_result: DiceResult = null
var is_rolling := false

# Cấu hình lãi suất định kỳ (%) khi đi qua ô Bắt đầu
@export var interest_rate: float = 10.0

var _event_handler = null
var _last_auction_choice := {"player_id": -1, "choice_index": -1, "bid_amount": -1}
var _auction_expected_player_id := -1
var _pending_trade: Dictionary = {}


func get_players() -> Array:
	return game_state.players


func get_event_handler():
	if _event_handler == null:
		_event_handler = EventHandler.new(self)
		add_child(_event_handler)
	return _event_handler


func _on_asset_action_completed(action: String, success: bool, message: String, amount: int = 0):
	if ui:
		ui.show_message(message)
		if ui.has_method("log_finance"):
			var player_name := ""
			var current = get_current_player()
			if current:
				player_name = current.name
			ui.log_finance(action, player_name, amount, success, message)


func _log_tx(action: String, player: Player, amount: int, note: String = "") -> void:
	if ui and ui.has_method("log_finance"):
		ui.log_finance(action, player.name if player else "", amount, true, note)


func _on_auction_choice(player_id: int, choice_index: int, bid_amount: int = -1) -> void:
	if _auction_expected_player_id != -1 and player_id != _auction_expected_player_id:
		return
	_last_auction_choice["player_id"] = player_id
	_last_auction_choice["choice_index"] = choice_index
	_last_auction_choice["bid_amount"] = bid_amount
	emit_signal("auction_choice_made")


func start_turn():
	var player = get_current_player()
	if player.is_bankrupt():
		end_turn()
		return
	if ui:
		ui.show_turn(player.player_id)
		ui.refresh_player_panel(get_game_state_snapshot())
	if not _pending_trade.is_empty() and _pending_trade.get("receiver") == player:
		var t = _pending_trade
		_pending_trade = {}
		ui.show_pending_trade_offer(t)


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

	# TRƯỜNG HỢP Ở TRONG TÙ (JAIL)
	if player.state.in_jail:
		player.state.jail_turns += 1
		if player.state.get_out_of_jail_cards > 0:
			player.state.use_jail_free_card()
			player.state.set_in_jail(false)
			await move_player(player, final_result.total())
			await handle_landed_cell(player, player.state.position)
		elif final_result.is_double:
			player.state.set_in_jail(false)
			await move_player(player, final_result.total())
			await handle_landed_cell(player, player.state.position)
		elif player.state.jail_turns >= 3:
			player.deduct_money(50)
			_log_tx("jail_fee", player, -50, "Trả phí tù bắt buộc")
			player.state.set_in_jail(false)
			await move_player(player, final_result.total())
			await handle_landed_cell(player, player.state.position)
		else:
			if ui:
				ui.show_message(player.name + " ở tù – lượt " + str(player.state.jail_turns) + "/3")
		is_rolling = false
		if ui:
			ui.set_roll_enabled(true)
		end_turn()
		return

	# TRƯỜNG HỢP ĐỔ ĐÚNG ĐÔI (DOUBLE)
	if final_result.is_double:
		game_state.double_count += 1
		if ui:
			ui.show_double()
		if game_state.double_count >= 3:
			await go_to_jail(player)
			game_state.double_count = 0
			is_rolling = false
			if ui:
				ui.set_roll_enabled(true)
			end_turn()
			return

	# DI CHUYỂN & KÍCH HOẠT Ô ĐẤT (MOVE & LAND)
	await move_player(player, final_result.total())
	await handle_landed_cell(player, player.state.position)

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
			# KHI ĐI QUA Ô BẮT ĐẦU: Kích hoạt thưởng và chờ thông báo
			await process_reward(player)
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


func go_to_jail(player: Player) -> void:
	player.state.set_in_jail(true)
	if ui:
		ui.show_jail()
	await move_player_to_position(player, 5)


func end_turn() -> void:
	auto_save_game()
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


# ══════════════════════════════════════════════════════════════════════
# XỬ LÝ THƯỞNG VÀ HIỆN BẢNG LÃI SUẤT KHI QUA Ô BẮT ĐẦU (GO)
# ══════════════════════════════════════════════════════════════════════
func process_reward(player: Player, amount: int = 200) -> void:
	# 1. Thưởng tiền qua ô GO cơ bản
	player.add_money(amount)
	_log_tx("go_reward", player, amount, "Qua ô Xuất Phát nhận $" + str(amount))
	
	# 2. Tính tiền lãi định kỳ (Dựa vào số dư hiện hành)
	var interest_amount: int = int(floor(player.balance * (interest_rate / 100.0)))
	if interest_amount > 0:
		player.add_money(interest_amount)
		if ui and ui.has_method("log_finance"):
			ui.log_finance("interest", player.name, interest_amount, true, "Lãi tích lũy tại ô GO")
			
	# 3. Làm mới giao diện
	if ui:
		ui.refresh_player_panel(get_game_state_snapshot())
		
		# 4. THÔNG BÁO CHO NGƯỜI CHƠI (Đã sửa lỗi treo game)
		# Giải pháp an toàn: Dùng hệ thống tin nhắn mặc định của game
		var msg = "🎉 %s qua ô GO: Nhận $%d" % [player.name, amount]
		if interest_amount > 0:
			msg += "\n📈 Tiền lãi (%d%%): +$%d" % [interest_rate, interest_amount]
			
		ui.show_message(msg)
		
		# Tạm dừng 1.5 giây để người chơi kịp đọc thông báo
		await get_tree().create_timer(1.5).timeout

		# LƯU Ý: Nếu bạn có file `InterestPopup.gd` riêng biệt và bắt buộc muốn dùng nó, 
		# hãy xóa phần `ui.show_message` ở trên và dùng code này:
		#
		# var popup = InterestPopup.new(ui, player.name, Color("#FFC832"), amount, interest_amount, interest_rate)
		# ui.add_child(popup) # Bắt buộc phải có dòng này để UI hiện lên
		# await popup.closed


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


func process_payment(player: Player, receiver: Player, amount: int, _reason: String):
	if player.state.balance >= amount:
		player.deduct_money(amount)
		if player.token and player.token.has_method("show_floating_money"):
			player.token.show_floating_money(-amount)
		if receiver:
			receiver.add_money(amount)
			if receiver.token and receiver.token.has_method("show_floating_money"):
				receiver.token.show_floating_money(amount)
	else:
		handle_insufficient_funds(player, receiver, amount)
	emit_signal("turn_action_completed")


func handle_insufficient_funds(payer: Player, receiver: Player, amount: int):
	if payer.get_total_capacity() < amount:
		handle_bankruptcy(payer, receiver)
	elif ui:
		ui.request_mortgage(payer, amount - payer.state.balance)


func handle_bankruptcy(debtor: Player, _creditor: Player = null):
	_log_tx("bankrupt", debtor, -debtor.state.balance, "PHÁ SẢN – giải phóng tài sản")
	if ui:
		ui.show_message(debtor.name + " PHÁ SẢN!")
	debtor.release_all_assets()
	board.remove_player_token(debtor)
	if ui:
		ui.refresh_player_panel(get_game_state_snapshot())
	emit_signal("turn_action_completed")


# ─── LƯU & TẢI GAME ───────────────────────────────────────────────────
func save_game(save_id: int) -> void:
	if ui and ui.has_method("is_dice_rolling") and ui.is_dice_rolling():
		return
	var storage_status = StorageService.check_storage_availability()
	if not storage_status.get("ok", false):
		return

	var game_data = {
		"players_state": _collect_players_state(),
		"properties_state": _collect_properties_state(),
		"current_player": game_state.current_player,
		"double_count": game_state.double_count,
		"player_count": game_state.players.size(),
		"v_total": _compute_v_total()
	}
	StorageService.save_file(save_id, game_data)


func load_game(save_id: int) -> void:
	var slot: SaveSlot = StorageService.load_file(save_id)
	if slot.is_empty(): return

	var loaded_data = StorageService.load_game_data(save_id)
	if loaded_data.is_empty() or not loaded_data.has("players_state"): return

	var players_state_data = loaded_data.get("players_state", [])
	if typeof(players_state_data) != TYPE_ARRAY: return

	if not _apply_players_state(players_state_data): return

	game_state.current_player = int(loaded_data.get("current_player", game_state.current_player))
	game_state.double_count = int(loaded_data.get("double_count", game_state.double_count))

	var properties_state_data = loaded_data.get("properties_state", [])
	if typeof(properties_state_data) == TYPE_ARRAY:
		_apply_properties_state(properties_state_data)

	_refresh_player_tokens_from_state()


func auto_save_game() -> void:
	var storage_status = StorageService.check_storage_availability()
	if not storage_status.get("ok", false): return

	var game_data = {
		"players_state": _collect_players_state(),
		"properties_state": _collect_properties_state(),
		"current_player": game_state.current_player,
		"double_count": game_state.double_count,
		"player_count": game_state.players.size(),
		"v_total": _compute_v_total()
	}
	StorageService.save_auto(game_data)


func _collect_players_state() -> Array:
	var players_state_data: Array = []
	for player in game_state.players:
		var card_ids: Array = []
		for card in player.special_card:
			if typeof(card) == TYPE_DICTIONARY and card.has("type"):
				card_ids.append(str(card.get("type", "")))

		players_state_data.append({
			"player_id": player.player_id,
			"position": player.state.position,
			"balance": player.state.balance,
			"in_jail": player.state.in_jail,
			"jail_turns": player.state.jail_turns,
			"bankrupt": player.state.bankrupt,
			"get_out_of_jail_cards": player.state.get("get_out_of_jail_cards") if "get_out_of_jail_cards" in player.state else 0,
			"special_cards": card_ids
		})
	return players_state_data


func _collect_properties_state() -> Array:
	var props_state: Array = []
	for cell in board.cells:
		if not cell is PropertyCell: continue
		var prop = cell as PropertyCell
		if prop.property_owner == null: continue

		props_state.append({
			"cell_index": cell.index,
			"owner_player_id": prop.property_owner.player_id,
			"is_mortgaged": prop.is_mortgaged,
			"house_count": prop.house_count,
			"has_hotel": prop.has_hotel
		})
	return props_state


func _apply_properties_state(properties_state: Array) -> void:
	for player in game_state.players:
		player.properties.clear()

	for cell in board.cells:
		if cell is PropertyCell:
			var prop = cell as PropertyCell
			prop.property_owner = null
			prop.is_mortgaged = false
			prop.house_count = 0
			prop.has_hotel = false

	for entry in properties_state:
		if typeof(entry) != TYPE_DICTIONARY: continue
		var cell_index = int(entry.get("cell_index", -1))
		var cell = board.get_cell(cell_index)
		if not cell is PropertyCell: continue

		var prop = cell as PropertyCell
		var owner_id = int(entry.get("owner_player_id", -1))
		var owner: Player = null
		for p in game_state.players:
			if p.player_id == owner_id:
				owner = p
				break

		prop.property_owner = owner
		prop.is_mortgaged = bool(entry.get("is_mortgaged", false))
		prop.house_count = int(entry.get("house_count", 0))
		prop.has_hotel = bool(entry.get("has_hotel", false))
		prop.queue_redraw()

		if owner != null:
			owner.add_property(prop)


func _compute_v_total() -> int:
	var total := 0
	for player in game_state.players:
		total += player.state.balance
		for prop in player.properties:
			if prop is PropertyCell:
				var pd = prop.data as PropertyData
				if pd != null: total += pd.buy_price
	return total


func _apply_players_state(players_state_data: Array) -> bool:
	var by_id := {}
	for entry in players_state_data:
		if typeof(entry) != TYPE_DICTIONARY: return false
		by_id[int(entry.get("player_id", -1))] = entry

	for player in game_state.players:
		if not by_id.has(player.player_id): continue
		var state_data = by_id[player.player_id]
		player.state.position = int(state_data.get("position", state_data.get("position")))
		player.state.balance = int(state_data.get("balance", state_data.get("balance")))
		player.state.in_jail = bool(state_data.get("in_jail", state_data.get("in_jail")))
		player.state.jail_turns = int(state_data.get("jail_turns", state_data.get("jail_turns")))
		player.state.bankrupt = bool(state_data.get("bankrupt", state_data.get("bankrupt")))

		if state_data.has("get_out_of_jail_cards"):
			player.state.set("get_out_of_jail_cards", int(state_data.get("get_out_of_jail_cards", 0)))

		var saved_cards: Array = state_data.get("special_cards", [])
		if typeof(saved_cards) == TYPE_ARRAY and saved_cards.size() > 0:
			player.special_card.clear()
			for card_type in saved_cards:
				player.special_card.append({"type": str(card_type)})
	return true


func _refresh_player_tokens_from_state() -> void:
	for player in game_state.players:
		if not player.token: continue
		var world_pos = board.get_cell_position(player.state.position)
		var offset = get_offset(player.player_id)
		player.token.position = world_pos + offset


func get_offset(player_id: int) -> Vector2:
	var offsets = [Vector2(-10, -10), Vector2(10, -10), Vector2(-10, 10), Vector2(10, 10)]
	return offsets[player_id % offsets.size()]


# ─── XỬ LÝ SỰ KIỆN ĐÁP Ô (LANDED CELL) ─────────────────────────────────
func handle_landed_cell(player: Player, cell_index: int) -> void:
	var cell = board.get_cell(cell_index)
	if not cell: return

	if cell is PropertyCell:
		var prop = cell as PropertyCell
		if prop.property_owner == null:
			if ui:
				ui.prompt_buy_or_pass(player, prop, asset_manager)
				await ui.ui_action_done
		elif prop.property_owner != player and not prop.is_mortgaged:
			process_payment(player, prop.property_owner, prop.get_current_rent(), prop.data.cell_name)
		elif prop.property_owner == player:
			if ui:
				ui.show_asset_management(player, asset_manager)
				await ui.ui_action_done
		return

	if cell.data is TaxData:
		player.deduct_money(cell.data.tax_amount)
		_log_tx("tax", player, -cell.data.tax_amount, "Thuế: -$" + str(cell.data.tax_amount))
		if player.token and player.token.has_method("show_floating_money"):
			player.token.show_floating_money(-cell.data.tax_amount)
		return

	if cell is ChanceCell or cell is ChestCell:
		if get_event_handler().handle_event(player, cell):
			await get_event_handler().event_finished
		return

	if cell.data is SpecialData and cell.data.cell_type == CellType.Type.GO_TO_JAIL:
		await go_to_jail(player)


# ─── ĐẤU GIÁ (AUCTION) ─────────────────────────────────────────────────
func start_auction(cell: PropertyCell) -> void:
	if ui == null: return
	var pd = cell.data as PropertyData
	if pd == null: return

	_auction_expected_player_id = -1
	_last_auction_choice = {"player_id": -1, "choice_index": -1, "bid_amount": -1}

	var ordered: Array = []
	var n = game_state.players.size()
	for i in range(n):
		var check_idx = (game_state.current_player + 1 + i) % n
		var p = game_state.players[check_idx]
		if not p.is_bankrupt(): ordered.append(p)

	if ordered.size() == 0:
		if ui and ui.has_method("_close_auction"): ui._close_auction()
		return

	var passed = {}
	for p in ordered: passed[p.player_id] = false

	var current_bid: int = 0
	var current_winner: Player = null
	var min_increment: int = max(1, int(pd.buy_price / 10))
	var loop_idx = 0
	var safety := 0

	while true:
		safety += 1
		if safety > 500: break

		var bidder = ordered[loop_idx]
		if not passed[bidder.player_id]:
			var min_bid = current_bid + min_increment if current_bid > 0 else 1
			if bidder.balance < min_bid:
				passed[bidder.player_id] = true
			else:
				_auction_expected_player_id = bidder.player_id
				ui.prompt_auction(bidder, pd, current_bid, min_bid, ordered, Callable(self, "_on_auction_choice"))
				await self.auction_choice_made

				if int(_last_auction_choice["player_id"]) != bidder.player_id: continue
				var choice = int(_last_auction_choice["choice_index"])
				var bid_amount = int(_last_auction_choice.get("bid_amount", -1))
				_auction_expected_player_id = -1

				if choice == 0:
					passed[bidder.player_id] = true
				elif choice == 1:
					if bid_amount < min_bid or bid_amount > bidder.balance: continue
					current_bid = bid_amount
					current_winner = bidder

		var remaining = 0
		for p in ordered:
			if not passed[p.player_id]: remaining += 1
		if remaining == 1:
			if current_winner == null:
				for p in ordered:
					if not passed[p.player_id]:
						current_winner = p
						current_bid = max(current_bid, min_increment)
						break
			break
		loop_idx = (loop_idx + 1) % ordered.size()

	_auction_expected_player_id = -1
	if current_winner != null and current_bid > 0:
		if current_winner.balance >= current_bid:
			asset_manager.transfer_property(current_winner, cell, current_bid)

	if ui and ui.has_method("_close_auction"): ui._close_auction()


# ─── QUẢN LÝ TÀI SẢN & TRAO ĐỔI (ASSETS INTERACTION) ────────────────────
func player_buy_property(player: Player, cell: PropertyCell) -> bool:
	return asset_manager.buy_property(player, cell) if asset_manager else false

func player_build_house(player: Player, cell: PropertyCell) -> bool:
	return asset_manager.build_house(player, cell) if asset_manager else false

func player_mortgage(player: Player, cell: PropertyCell) -> bool:
	return asset_manager.mortgage_property(player, cell) if asset_manager else false

func player_redeem(player: Player, cell: PropertyCell) -> bool:
	return asset_manager.redeem_property(player, cell) if asset_manager else false

func player_sell_house(player: Player, cell: PropertyCell) -> bool:
	return asset_manager.sell_house_to_bank(player, cell) if asset_manager else false

func player_sell_property(player: Player, cell: PropertyCell) -> bool:
	return asset_manager.sell_property_to_bank(player, cell) if asset_manager else false

func player_queue_trade(initiator: Player, receiver: Player, offer_cell: PropertyCell, request_cell: PropertyCell, compensation: int, payer: Player) -> void:
	_pending_trade = {"initiator": initiator, "receiver": receiver, "offer_cell": offer_cell, "request_cell": request_cell, "compensation": compensation, "payer": payer}

func player_open_trade(player: Player) -> Array:
	return asset_manager.get_tradeable_properties(player) if asset_manager else []

func player_execute_trade(initiator: Player, receiver: Player, offer_cell: PropertyCell, request_cell: PropertyCell, compensation: int, payer: Player) -> bool:
	return asset_manager.execute_trade(initiator, receiver, offer_cell, request_cell, compensation, payer) if asset_manager else false
