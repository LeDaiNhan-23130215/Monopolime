extends Node
class_name GameController

signal turn_action_completed
signal buy_decision_made(accepted: bool)
signal auction_bid_made(amount: int)
signal build_decision_made

var board: Board
var game_state: GameState
var dice: Dice
var ui: GameUI
var asset_manager: AssetManager

var final_result: DiceResult = null
var is_rolling := false
var is_turn_resolving := false

var event_handler: EventHandler = null
var jail_manager: JailManager = null

# Lưu dice total để tính utility rent
var last_dice_total: int = 0


func get_event_handler() -> EventHandler:
	if event_handler == null:
		event_handler = EventHandler.new(self)
		add_child(event_handler)
		event_handler.refresh_board_deck_counts()
	return event_handler


func get_jail_manager() -> JailManager:
	if jail_manager == null:
		jail_manager = JailManager.new(self)
	return jail_manager


func _on_asset_action_completed(_action: String, success: bool, message: String) -> void:
	if ui == null:
		return
	ui.show_message(message)
	ui.add_history(message, Color("#1B5E20") if success else Color("#B71C1C"))
	if board and board.has_method("update_cell_tooltips"):
		board.update_cell_tooltips()
	if game_state:
		ui.update_player_info(game_state.players)


func _set_turn_ready() -> void:
	is_rolling = false
	is_turn_resolving = false
	if ui:
		ui.set_roll_enabled(true)


func _refresh_player_info() -> void:
	if ui and game_state:
		ui.update_player_info(game_state.players)


func _emit_turn_action_completed() -> void:
	emit_signal("turn_action_completed")


# =========================
# LƯỢT CHƠI
# =========================

func start_turn() -> void:
	print("\n===== LƯỢT MỚI =====")

	var player = get_current_player()

	if player.is_bankrupt():
		end_turn()
		return

	print("Người chơi: ", player.name, " | Vị trí: ", player.state.position, " | Tiền: $", player.state.balance)
	ui.show_turn(player.player_id)
	ui.show_message("Den luot " + player.name + " | Turn " + str(game_state.turn_number))
	ui.add_history("Lượt " + str(game_state.turn_number) + ": đến lượt " + player.name, Color("#06336F"))
	_refresh_player_info()

	if player.state.in_jail:
		print(player.name + " đang ở tù! (Lượt ", player.state.jail_turns, "/3)")
		get_jail_manager().begin_jail_turn(player)


func roll_dice() -> void:
	if is_rolling:
		return

	is_rolling = true
	ui.set_roll_enabled(false)

	final_result = dice.roll()
	last_dice_total = final_result.total()
	ui.show_message(get_current_player().name + " dang tung xuc xac...")
	ui.start_dice_animation()


func resolve_roll() -> void:
	is_turn_resolving = true
	var player = get_current_player()

	ui.show_result(final_result)

	# =========================
	# XỬ LÝ KHI Ở TÙ
	# =========================

	if player.state.in_jail:
		await get_jail_manager().handle_jail_turn(player, final_result)
		end_turn()
		is_rolling = false
		is_turn_resolving = false
		ui.set_roll_enabled(true)
		return

	# =========================
	# DOUBLE
	# =========================

	if final_result.is_double:
		game_state.double_count += 1
		ui.show_double()

		# 3 lần double liên tiếp -> vào tù
		if game_state.double_count >= 3:
			ui.show_message(player.name + " đổ Double 3 lần! Vào Tù!")
			await go_to_jail(player)
			game_state.double_count = 0
			end_turn()
			_set_turn_ready()
			return

	# =========================
	# DI CHUYỂN
	# =========================

	await move_player(player, final_result.total())
	await handle_landed_cell(player, player.state.position)

	# =========================
	# EXTRA TURN NẾU DOUBLE
	# =========================

	if final_result.is_double:
		_set_turn_ready()
		start_turn()
		return

	# =========================
	# KẾT THÚC LƯỢT
	# =========================

	game_state.double_count = 0
	end_turn()
	_set_turn_ready()


# =========================
# XỬ LÝ TÙ – đã chuyển sang JailManager (UC-07)
# Xem: JailManager.gd, handle_jail_turn(), resolve_jail_turn()
# =========================

func _handle_jail_turn(player: Player) -> void:
	# Ưu tiên dùng thẻ Ra Tù nếu có VÀ không đổ được double
	if player.state.special_cards > 0 and not final_result.is_double:
		player.state.special_cards -= 1
		player.state.set_in_jail(false)
		ui.show_message(player.name + " dùng thẻ Ra Tù Miễn Phí!")
		print(player.name + " dùng thẻ Ra Tù!")

		await move_player(player, final_result.total())
		await handle_landed_cell(player, player.state.position)

	elif final_result.is_double:
		player.state.set_in_jail(false)
		player.state.jail_turns = 0
		ui.show_message(player.name + " đổ Double - Thoát tù!")
		print(player.name + " thoát tù bằng Double!")

		await move_player(player, final_result.total())
		await handle_landed_cell(player, player.state.position)

	else:
		player.state.jail_turns += 1
		print(player.name + " không đổ được Double. Lượt tù: ", player.state.jail_turns)

		# Sau 3 lượt tù -> bắt buộc nộp $50
		if player.state.jail_turns >= 3:
			ui.show_message(player.name + " hết 3 lượt! Nộp phạt $50 ra tù!")
			await process_payment(player, null, 50, "Phạt tù")
			player.state.set_in_jail(false)
			player.state.jail_turns = 0

			await move_player(player, final_result.total())
			await handle_landed_cell(player, player.state.position)
		else:
			ui.show_message(player.name + " vẫn ở tù (Lượt " + str(player.state.jail_turns) + "/3)")

	end_turn()
	_set_turn_ready()


# =========================
# DI CHUYỂN
# =========================

func move_player(player: Player, steps: int) -> void:
	for i in range(steps):
		var next_pos = player.state.position + 1

		# Đi qua GO -> nhận $200
		if next_pos >= game_state.board_size:
			process_reward(player)

		next_pos %= game_state.board_size
		player.state.update_position(next_pos)

		var world_pos = board.get_cell_position(next_pos)
		var offset = get_offset(player.player_id)

		if player.token:
			await player.token.move_to(world_pos + offset)

		await get_tree().create_timer(0.08).timeout


func move_player_to_position(player: Player, pos: int) -> void:
	player.state.update_position(pos)

	var world_pos = board.get_cell_position(pos)
	var offset = get_offset(player.player_id)

	if player.token:
		await player.token.move_to(world_pos + offset)


func move_player_to_position_with_teleport_effect(player: Player, pos: int) -> void:
	if player.token:
		var fade_out = create_tween()
		fade_out.tween_property(player.token, "modulate:a", 0.0, 0.18)
		await fade_out.finished

	await move_player_to_position(player, pos)

	if player.token:
		var fade_in = create_tween()
		fade_in.tween_property(player.token, "modulate:a", 1.0, 0.22)
		await fade_in.finished


func handle_teleport(player: Player) -> void:
	ui.show_message(player.name + " duoc chon diem du lich!")
	ui.show_teleport_chooser(player, board)
	var selected_index = await ui.teleport_cell_selected
	var target_index = int(selected_index) % game_state.board_size
	var current_index = player.state.position
	var target_cell = board.get_cell(target_index)
	var target_name = target_cell.cell_name if target_cell else str(target_index)

	await ui.show_toast_and_wait(
		"Du lich",
		player.name + " dich chuyen den " + target_name,
		Color(0.4, 0.85, 1.0),
		0,
		0.8
	)
	ui.play_sfx(GameUI.SFX_TELEPORT)
	await move_player_to_position_with_teleport_effect(player, target_index)
	if target_index != current_index:
		await handle_landed_cell(player, target_index)


func go_to_jail(player: Player):
	# Delegate toàn bộ logic vào tù sang JailManager (UC-07, 7.1.1→7.1.3)
	await get_jail_manager().go_to_jail(player)


# =========================
# KẾT THÚC LƯỢT & GAME OVER
# =========================

func request_end_turn() -> void:
	if is_rolling:
		return
	end_turn()


func end_turn() -> void:
	# Kiểm tra game over
	var alive_players = []
	for p in game_state.players:
		if not p.is_bankrupt():
			alive_players.append(p)

	if alive_players.size() <= 1:
		if alive_players.size() == 1:
			var winner = alive_players[0]
			print("🎉 GAME OVER! Người thắng: ", winner.name)
			ui.play_sfx(GameUI.SFX_GAME_OVER)
			ui.show_game_over(winner)
		else:
			print("GAME OVER! Hòa!")
		return

	# Tìm người chơi tiếp theo (bỏ qua người phá sản)
	var next_player_found = false
	var safety_counter = 0

	while not next_player_found and safety_counter < game_state.players.size():
		var old_player = game_state.current_player
		game_state.current_player = (game_state.current_player + 1) % game_state.players.size()
		if game_state.current_player <= old_player:
			game_state.turn_number += 1

		if game_state.victory_mode == "turn_limit" and game_state.max_turns > 0 and game_state.turn_number > game_state.max_turns:
			var net_worth_winner = get_winner_by_net_worth()
			ui.play_sfx(GameUI.SFX_GAME_OVER)
			ui.show_game_over_with_rankings(net_worth_winner, build_rankings())
			return

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
		Vector2(-12, -12),
		Vector2(12, -12),
		Vector2(-12, 12),
		Vector2(12, 12)
	]
	return offsets[player_id % offsets.size()]


# =========================
# XỬ LÝ Ô ĐÁP XUỐNG
# =========================

func handle_landed_cell(player: Player, cell_index: int) -> void:
	var cell: Cell = board.get_cell(cell_index)

	if not cell:
		return

	print(player.name, " đáp xuống: ", cell.cell_name, " (", cell.cell_type, ")")
	ui.add_history(player.name + " đến ô " + cell.cell_name, Color("#2E2A22"))
	cell.play_land_effect()

	# --- Ô sự kiện ---
	var is_event = await get_event_handler().handle_event(player, cell)
	if is_event:
		_refresh_player_info()
		return

	# --- Ô có thể mua ---
	if cell.can_be_purchased():
		if player.state.balance >= cell.get_modified_price():
			ui.show_buy_prompt(player, cell)
			var accepted = await buy_decision_made

			if accepted:
				buy_property(player, cell)
			else:
				ui.show_message(player.name + " không mua → Đấu giá " + cell.cell_name + "!")
				await run_auction(cell)
		else:
			ui.show_message(player.name + " không đủ tiền → Đấu giá " + cell.cell_name + "!")
			await run_auction(cell)

	# --- Ô đã có chủ (trả thuê) ---
	elif cell.cell_owner != null and cell.cell_owner != player and not cell.is_mortgaged:
		var rent_amount = cell.get_current_rent(last_dice_total)
		await ui.show_transaction_popup(player, cell.cell_owner, rent_amount, "Tien thue: " + cell.cell_name)
		await process_payment(player, cell.cell_owner, rent_amount, cell.cell_name)

	# --- Ô của mình ---
	elif cell.cell_owner == player:
		ui.show_message("Đây là đất của bạn: " + cell.cell_name)

		if cell.can_build_house():
			ui.show_build_prompt(player, cell)
			await build_decision_made
		else:
			var reason = cell.get_build_block_reason()
			if reason != "":
				ui.show_message(cell.cell_name + " chua the xay: " + reason)

	_refresh_player_info()


# =========================
# MUA ĐẤT
# =========================

func buy_property(player: Player, cell: Cell) -> void:
	var purchase_price = cell.get_modified_price()
	player.deduct_money(purchase_price)
	cell.cell_owner = player
	player.add_property(cell)

	ui.play_sfx(GameUI.SFX_BUY)
	ui.show_message(player.name + " mua " + cell.cell_name + " ($" + str(purchase_price) + ")")
	ui.add_history(player.name + " mua " + cell.cell_name + " (-$" + str(purchase_price) + ")", Color("#0D47A1"))
	ui.show_money_float(-purchase_price, player.token)
	print(player.name, " đã mua: ", cell.cell_name)

	cell.play_buy_effect()
	board.update_cell_tooltips()
	_refresh_player_info()


func build_on_property(player: Player, cell: Cell) -> bool:
	if cell.cell_owner != player:
		ui.show_message("Ban khong so huu " + cell.cell_name)
		return false
	if not cell.can_build_house():
		ui.show_message("Chua the xay tren " + cell.cell_name + ": " + cell.get_build_block_reason())
		return false

	var ok = cell.build_house()
	if ok:
		ui.play_sfx(GameUI.SFX_BUILD)
		cell.play_upgrade_effect()
		ui.show_message("Nang cap thanh cong: " + cell.cell_name + " -> " + cell.get_build_level_name())
		ui.add_history(player.name + " nâng cấp " + cell.cell_name + " -> " + cell.get_build_level_name(), Color("#1B5E20"))
		board.update_cell_tooltips()
		_refresh_player_info()
	return ok


func sell_house_on_property(player: Player, cell: Cell) -> bool:
	if cell.cell_owner != player:
		ui.show_message("Ban khong so huu " + cell.cell_name)
		return false

	var ok = cell.sell_house()
	if ok:
		ui.show_message("Da ban bot cong trinh tren " + cell.cell_name)
		ui.add_history(player.name + " bán bớt công trình trên " + cell.cell_name, Color("#6D4C41"))
		board.update_cell_tooltips()
	else:
		ui.show_message("Chua the ban cong trinh tren " + cell.cell_name)
	_refresh_player_info()
	return ok


func mortgage_property(player: Player, cell: Cell) -> bool:
	if cell.cell_owner != player:
		ui.show_message("Ban khong so huu " + cell.cell_name)
		return false

	var amount = cell.mortgage_property()
	if amount > 0:
		ui.show_message("The chap " + cell.cell_name + " nhan $" + str(amount))
		ui.add_history(player.name + " thế chấp " + cell.cell_name + " (+$" + str(amount) + ")", Color("#6D4C41"))
		ui.show_money_float(amount, player.token)
		board.update_cell_tooltips()
	else:
		ui.show_message("Chua the the chap " + cell.cell_name)
	_refresh_player_info()
	return amount > 0


func unmortgage_property(player: Player, cell: Cell) -> bool:
	if cell.cell_owner != player:
		ui.show_message("Ban khong so huu " + cell.cell_name)
		return false

	var ok = cell.unmortgage_property()
	if ok:
		ui.show_message("Da giai chap " + cell.cell_name)
		ui.add_history(player.name + " giải chấp " + cell.cell_name, Color("#6D4C41"))
		board.update_cell_tooltips()
	else:
		ui.show_message("Chua the giai chap " + cell.cell_name)
	_refresh_player_info()
	return ok


func build_protection_tower_for_current_player(cell: Cell) -> bool:
	var player = get_current_player()
	if cell.cell_owner != player:
		ui.show_message("Ban khong so huu " + cell.cell_name)
		return false
	var ok = cell.build_protection_tower(player)
	if ok:
		ui.play_sfx(GameUI.SFX_BUILD)
		ui.show_message("Da xay thap bao ve tren " + cell.cell_name)
		ui.add_history(player.name + " xây tháp bảo vệ trên " + cell.cell_name, Color("#1B5E20"))
		board.update_cell_tooltips()
	else:
		ui.show_message("Chua the xay thap bao ve tren " + cell.cell_name)
	_refresh_player_info()
	return ok


func calculate_net_worth(player: Player) -> int:
	var total = player.state.balance
	for cell in player.properties:
		total += cell.get_mortgage_value() * 2
		total += cell.house_count * int(cell.house_cost * 0.5)
		if cell.has_protection_tower:
			total += int(cell.protection_cost * 0.5)
	return total


func count_player_houses(player: Player) -> int:
	var total = 0
	for cell in player.properties:
		if cell.house_count > 0 and cell.house_count < 4:
			total += cell.house_count
	return total


func count_player_hotels(player: Player) -> int:
	var total = 0
	for cell in player.properties:
		if cell.house_count >= 4:
			total += 1
	return total


func count_player_mortgaged_properties(player: Player) -> int:
	var total = 0
	for cell in player.properties:
		if cell.is_mortgaged:
			total += 1
	return total


func get_player_rank(player: Player) -> int:
	var rankings = build_rankings()
	for i in range(rankings.size()):
		if rankings[i]["player"] == player:
			return i + 1
	return rankings.size()


func build_rankings() -> Array:
	var rankings = []
	for p in game_state.players:
		rankings.append({
			"player": p,
			"cash": p.state.balance,
			"properties": p.properties.size(),
			"net_worth": calculate_net_worth(p),
		})
	rankings.sort_custom(func(a, b): return a["net_worth"] > b["net_worth"])
	return rankings


func get_winner_by_net_worth() -> Player:
	var rankings = build_rankings()
	for row in rankings:
		var p = row["player"]
		if not p.is_bankrupt():
			return p
	return null


# =========================
# ĐẤU GIÁ (Auction)
# =========================

func run_auction(cell: Cell) -> void:
	print("--- ĐẤU GIÁ: ", cell.cell_name, " ---")

	var highest_bid = 0
	var highest_bidder: Player = null

	for player in game_state.players:
		if player.is_bankrupt():
			continue

		var max_willing = int(cell.get_modified_price() * 0.8)
		var bid = min(max_willing, player.state.balance - 100)

		if bid > highest_bid and bid > 0:
			highest_bid = bid
			highest_bidder = player

	if highest_bidder != null:
		highest_bidder.deduct_money(highest_bid)
		cell.cell_owner = highest_bidder
		highest_bidder.add_property(cell)
		cell.play_buy_effect()
		ui.show_money_float(-highest_bid, highest_bidder.token)
		ui.add_history(highest_bidder.name + " thắng đấu giá " + cell.cell_name + " (-$" + str(highest_bid) + ")", Color("#0D47A1"))
		board.update_cell_tooltips()

		ui.show_message(highest_bidder.name + " thắng đấu giá " + cell.cell_name + " với $" + str(highest_bid))
		print(highest_bidder.name, " thắng đấu giá: ", cell.cell_name, " - $", highest_bid)
	else:
		ui.show_message("Không ai đấu giá " + cell.cell_name)
		print("Đấu giá thất bại - không ai mua")

	await get_tree().create_timer(1.5).timeout


# =========================
# TÀI CHÍNH
# =========================

func process_reward(player: Player, amount: int = 200) -> void:
	player.add_money(amount)
	ui.play_sfx(GameUI.SFX_REWARD)
	ui.show_message(player.name + " nhận $" + str(amount))
	ui.add_history(player.name + " nhận $" + str(amount), Color("#1B5E20"))
	ui.show_money_float(amount, player.token)


func process_payment(payer: Player, beneficiary: Player, amount: int, reason: String) -> void:
	if payer.state.balance >= amount:
		execute_transaction(payer, beneficiary, amount, reason)
	else:
		await handle_insufficient_funds(payer, beneficiary, amount, reason)


func execute_transaction(payer: Player, beneficiary: Player, amount: int, reason: String = "") -> void:
	payer.deduct_money(amount)
	ui.play_sfx(GameUI.SFX_PAY)
	ui.show_money_float(-amount, payer.token, beneficiary.token if beneficiary else null)

	if beneficiary:
		beneficiary.add_money(amount)
		ui.show_money_float(amount, beneficiary.token)

		if reason != "":
			ui.add_history(
				payer.name + " trả $" + str(amount) + " cho " + beneficiary.name + " (" + reason + ")",
				Color("#B71C1C")
			)
		else:
			ui.add_history(payer.name + " trả $" + str(amount) + " cho " + beneficiary.name, Color("#B71C1C"))
	else:
		if reason != "":
			ui.add_history(payer.name + " trả $" + str(amount) + " (" + reason + ")", Color("#B71C1C"))
		else:
			ui.add_history(payer.name + " trả $" + str(amount), Color("#B71C1C"))

	_emit_turn_action_completed()


func handle_insufficient_funds(
	payer: Player,
	beneficiary: Player,
	amount: int,
	reason: String = ""
) -> void:
	var total_cap = payer.get_total_capacity()

	if total_cap < amount:
		handle_bankruptcy(payer, beneficiary)
		return

	var amount_needed = amount - payer.state.balance
	await ui.show_insufficient_funds_options(payer, amount_needed)

	# Sau khi người chơi đóng popup / xử lý tài sản, kiểm tra lại
	if payer.state.balance >= amount:
		execute_transaction(payer, beneficiary, amount, reason)
	else:
		handle_bankruptcy(payer, beneficiary)


func handle_bankruptcy(debtor: Player, creditor: Player) -> void:
	print("💀 ", debtor.name, " PHÁ SẢN!")
	ui.show_message("💀 " + debtor.name + " đã PHÁ SẢN!")

	debtor.transfer_all_assets_to(creditor)

	if board.has_method("remove_player_token"):
		board.remove_player_token(debtor)

	for cell in board.cells:
		cell.queue_redraw()

	_emit_turn_action_completed()


func restart_game() -> void:
	if board:
		board.reset_board()
	if game_state:
		game_state.players.clear()
		game_state.current_player = 0
		game_state.double_count = 0
		game_state.turn_number = 1
		game_state.max_turns = 0
		game_state.victory_mode = "bankruptcy"
	get_tree().reload_current_scene()
