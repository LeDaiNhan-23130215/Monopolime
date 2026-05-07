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
