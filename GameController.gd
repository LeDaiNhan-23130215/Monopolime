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

var event_handler: EventHandler = null

# Lưu dice total để tính utility rent
var last_dice_total: int = 0


func get_event_handler() -> EventHandler:
	if event_handler == null:
		event_handler = EventHandler.new(self)
		add_child(event_handler)
	return event_handler


# =========================
# LƯỢT CHƠI
# =========================

func _on_asset_action_completed(action: String, success: bool, message: String):
	if ui:
		ui.show_message(message)


func start_turn():
	print("\n===== LƯỢT MỚI =====")

	var player = get_current_player()
	if player.is_bankrupt():
		end_turn()
		return

	print("Người chơi: ", player.name, " | Vị trí: ", player.state.position, " | Tiền: $", player.state.balance)
	ui.show_turn(player.player_id)
	ui.update_player_info(game_state.players)

	if player.state.in_jail:
		print(player.name + " đang ở tù! (Lượt ", player.state.jail_turns, "/3)")
		if player.state.special_cards > 0:
			ui.show_message(player.name + " ở tù. Có thẻ Ra Tù. Nhấn Roll!")
		else:
			ui.show_message(player.name + " ở tù. Đổ Double để ra! (Lượt " + str(player.state.jail_turns + 1) + "/3)")


func roll_dice():
	if is_rolling:
		return

	is_rolling = true
	if ui:
		ui.set_roll_enabled(false)
	final_result = dice.roll()
	last_dice_total = final_result.total()
	ui.start_dice_animation()


func resolve_roll():
	var player = get_current_player()
	if ui:
		ui.show_result(final_result)

	ui.show_result(final_result)

	# =========================
	# XỬ LÝ KHI Ở TÙ
	# =========================

	if player.state.in_jail:
		await _handle_jail_turn(player)
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
			is_rolling = false
			ui.set_roll_enabled(true)
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
		is_rolling = false
		ui.set_roll_enabled(true)
		start_turn()
		return

	# =========================
	# KẾT THÚC LƯỢT
	# =========================

	game_state.double_count = 0
	end_turn()
	is_rolling = false
	if ui:
		ui.set_roll_enabled(true)


# =========================
# XỬ LÝ TÙ
# =========================

func _handle_jail_turn(player: Player):
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
			process_payment(player, null, 50, "Phạt tù")
			player.state.set_in_jail(false)
			player.state.jail_turns = 0

			await move_player(player, final_result.total())
			await handle_landed_cell(player, player.state.position)
		else:
			ui.show_message(player.name + " vẫn ở tù (Lượt " + str(player.state.jail_turns) + "/3)")

	end_turn()
	is_rolling = false
	ui.set_roll_enabled(true)


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


# BR-15: Vào tù → di chuyển về index 5 (Visiting Jail)
func go_to_jail(player: Player):
	print("🔒 ", player.name, " VÀO TÙ!")
	player.state.set_in_jail(true)
	player.state.jail_turns = 0

	ui.show_jail()

	var jail_pos = board.get_jail_position()
	await move_player_to_position(player, jail_pos)


# =========================
# KẾT THÚC LƯỢT & GAME OVER
# =========================

func end_turn():
	# Kiểm tra game over
	var alive_players = []
	for p in game_state.players:
		if not p.is_bankrupt():
			alive_players.append(p)

	if alive_players.size() <= 1:
		if alive_players.size() == 1:
			var winner = alive_players[0]
			print("🎉 GAME OVER! Người thắng: ", winner.name)
			ui.show_game_over(winner)
		else:
			print("GAME OVER! Hòa!")
		return

	# Tìm người chơi tiếp theo (bỏ qua người phá sản)
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
		print("GAME OVER")


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

func handle_landed_cell(player: Player, cell_index: int):
	var cell = board.get_cell(cell_index)
	if not cell:
		return

	print(player.name, " đáp xuống: ", cell.cell_name, " (", cell.cell_type, ")")

	# --- Ô sự kiện ---
	var is_event = await get_event_handler().handle_event(player, cell)
	if is_event:
		ui.update_player_info(game_state.players)
		return

	# --- Ô có thể mua ---
	if cell.can_be_purchased():
		if player.state.balance >= cell.price:
			# Hiện popup mua đất
			ui.show_buy_prompt(player, cell)
			var accepted = await buy_decision_made

			if accepted:
				buy_property(player, cell)
			else:
				# Đấu giá nếu người chơi từ chối mua
				ui.show_message(player.name + " không mua → Đấu giá " + cell.cell_name + "!")
				await run_auction(cell)
		else:
			ui.show_message(player.name + " không đủ tiền → Đấu giá " + cell.cell_name + "!")
			await run_auction(cell)

	# --- Ô đã có chủ (trả thuê) ---
	elif cell.cell_owner != null and cell.cell_owner != player and not cell.is_mortgaged:
		var rent_amount = cell.get_current_rent(last_dice_total)

		ui.show_message(player.name + " trả $" + str(rent_amount) + " tiền thuê cho " + cell.cell_owner.name)

		if player.state.balance >= rent_amount:
			process_payment(player, cell.cell_owner, rent_amount, cell.cell_name)
		else:
			handle_insufficient_funds(player, cell.cell_owner, rent_amount)
			await self.turn_action_completed

	# --- Ô của mình ---
	elif cell.cell_owner == player:
		ui.show_message("Đây là đất của bạn: " + cell.cell_name)

		# Cho phép xây nhà nếu có đủ bộ màu
		if cell.can_build_house():
			ui.show_build_prompt(player, cell)
			await build_decision_made

	ui.update_player_info(game_state.players)


# =========================
# MUA ĐẤT
# =========================

func buy_property(player: Player, cell: Cell):
	player.deduct_money(cell.price)
	cell.cell_owner = player
	player.add_property(cell)

	ui.show_message(player.name + " mua " + cell.cell_name + " ($" + str(cell.price) + ")")
	print(player.name, " đã mua: ", cell.cell_name)

	cell.queue_redraw()
	ui.update_player_info(game_state.players)


# =========================
# ĐẤU GIÁ (Auction)
# =========================

func run_auction(cell: Cell):
	print("--- ĐẤU GIÁ: ", cell.cell_name, " ---")

	var highest_bid = 0
	var highest_bidder: Player = null

	# Đấu giá tự động giữa các AI/player
	for player in game_state.players:
		if player.is_bankrupt():
			continue

		# Logic đấu giá đơn giản: trả giá nếu có tiền và giá hợp lý
		var max_willing = int(cell.price * 0.8) # Tối đa 80% giá niêm yết
		var bid = min(max_willing, player.state.balance - 100) # Giữ lại ít nhất $100

		if bid > highest_bid and bid > 0:
			highest_bid = bid
			highest_bidder = player

	if highest_bidder != null:
		highest_bidder.deduct_money(highest_bid)
		cell.cell_owner = highest_bidder
		highest_bidder.add_property(cell)
		cell.queue_redraw()

		ui.show_message(highest_bidder.name + " thắng đấu giá " + cell.cell_name + " với $" + str(highest_bid))
		print(highest_bidder.name, " thắng đấu giá: ", cell.cell_name, " - $", highest_bid)
	else:
		ui.show_message("Không ai đấu giá " + cell.cell_name)
		print("Đấu giá thất bại - không ai mua")

	await get_tree().create_timer(1.5).timeout


# =========================
# TÀI CHÍNH
# =========================

# ══════════════════════════════════════════════════════════════════════
# Financial (Đã tích hợp toàn bộ FinanceManager)
# ══════════════════════════════════════════════════════════════════════
func process_reward(player: Player, amount: int = 200):
	player.add_money(amount)
	ui.show_message(player.name + " nhận $" + str(amount))


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


# ══════════════════════════════════════════════════════════════════════
# [MỚI CẬP NHẬT] XỬ LÝ PHÁ SẢN VÀ KẾT THÚC GAME
# ══════════════════════════════════════════════════════════════════════
func handle_bankruptcy(debtor: Player, creditor: Player):
	print(debtor.name, " ĐÃ PHÁ SẢN!")
	
	# 1. Chuyển giao tài sản
	if creditor != null:
		debtor.transfer_all_assets_to(creditor)
	else:
		debtor.transfer_all_assets_to(null) # Xóa tài sản nếu nợ ngân hàng

	# 2. Xóa quân cờ khỏi bàn
	if debtor.token and debtor.token.has_method("play_bankrupt_animation"):
		debtor.token.play_bankrupt_animation()
	board.remove_player_token(debtor)
	
	# 3. Hiển thị Giao diện Phá sản thật ngầu và chờ bấm nút
	if ui and ui.has_method("show_bankruptcy_alert"):
		ui.show_bankruptcy_alert(debtor, creditor)
		await ui.ui_action_done # Game sẽ TẠM DỪNG ở đây chờ người chơi bấm nút
	elif ui:
		ui.show_message(debtor.name + " đã phá sản!")
		await get_tree().create_timer(2.0).timeout

func handle_bankruptcy(debtor: Player, creditor: Player):
	print("💀 ", debtor.name, " PHÁ SẢN!")
	ui.show_message("💀 " + debtor.name + " đã PHÁ SẢN!")

	debtor.transfer_all_assets_to(creditor)

	if board.has_method("remove_player_token"):
		board.remove_player_token(debtor)

	# Redraw tất cả ô đất
	for cell in board.cells:
		cell.queue_redraw()

	emit_signal("turn_action_completed")

func check_game_over():
	var active_players = []
	for p in game_state.players:
		if not p.is_bankrupt():
			active_players.append(p)
			
	if active_players.size() == 1:
		var winner = active_players[0]
		print("========== GAME OVER ==========")
		print("NGƯỜI CHIẾN THẮNG LÀ: ", winner.name)
		if ui and ui.has_method("show_message"):
			ui.show_message("TRÒ CHƠI KẾT THÚC! " + winner.name + " CHIẾN THẮNG!")


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
