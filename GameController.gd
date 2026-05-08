extends Node
class_name GameController

# Tín hiệu dùng để "đóng băng" lượt đi
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
	ui.show_turn(player.player_id)
	
	if player.state.in_jail:
		print(player.name + " đang ở tù! Cần đổ ra Double để thoát.")

func roll_dice():
	print("ROLL DICE CALLED")
	if is_rolling:
		return  
		
	is_rolling = true
	ui.set_roll_enabled(false)
	
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
			is_rolling = false
			ui.set_roll_enabled(true)
			start_turn()
			return
		else:
			go_to_jail(player)
			is_rolling = false
			ui.set_roll_enabled(true)
			end_turn()
			return
	else:
		await move_player(player, final_result.total())
		process_current_cell(player) 
		game_state.double_count = 0
		await move_player(player, final_result.total())
		await handle_landed_cell(player, player.state.position)
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
		
		# update logic
		player.state.update_position(next_pos)

		# lấy vị trí world
		var world_pos = board.get_cell_position(next_pos)

		# offset tránh chồng
		var offset = get_offset(player.player_id)

		# move token
		await player.token.move_to(world_pos + offset)

		# delay nhỏ giữa bước (optional nếu move_to đã await)
		await get_tree().create_timer(0.1).timeout

func go_to_jail(player: Player):
	print("GO TO JAIL!")
	player.state.set_in_jail(true)
	await move_player_to_position(player, board.get_jail_index())
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
	
func get_offset(player_id: int) -> Vector2:
	var offsets = [
		Vector2(-10, -10),
		Vector2(10, -10),
		Vector2(-10, 10),
		Vector2(10, 10)
	]
	return offsets[player_id % offsets.size()]
	
func move_player_to_position(player: Player, pos: int) -> void:
	player.state.update_position(pos)
	
	var world_pos = board.get_cell_position(pos)
	var offset = get_offset(player.player_id)
	
	await player.token.move_to(world_pos + offset)
	
func process_current_cell(player: Player):
	var cell = board.get_cell_position(player.state.position)
	print("Player landed on:", cell)
