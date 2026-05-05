extends Node
class_name GameController

var game_state: GameState
var dice: Dice
var ui: GameUI

var final_result: DiceResult = null

func start_turn():
	print("===== TURN =====")
	var player = get_current_player()
	print("Player:", player.name)

	ui.show_turn(player.player_id)

func roll_dice():
	print("ROLL DICE CALLED")

	final_result = dice.roll()
	print("RESULT =", final_result.total())

	ui.start_dice_animation()

func resolve_roll():
	var player = get_current_player()

	ui.show_result(final_result)

	if final_result.is_double:
		game_state.double_count += 1
		ui.show_double()

		if game_state.double_count < 3:
			move_player(player, final_result.total())
			return
		else:
			go_to_jail(player)
			end_turn()
			return
	else:
		move_player(player, final_result.total())
		game_state.double_count = 0
		end_turn()

func move_player(player: Player, steps: int):
	var new_pos = player.state.position + steps
	new_pos %= game_state.board_size

	player.state.update_position(new_pos)

	ui.update_position(player.player_id, new_pos)

func go_to_jail(player: Player):
	print("GO TO JAIL!")

	player.state.set_in_jail(true)
	player.state.update_position(10)

	ui.show_jail()

func end_turn():
	game_state.current_player = (game_state.current_player + 1) % game_state.players.size()
	game_state.double_count = 0

	start_turn()

func get_current_player() -> Player:
	return game_state.players[game_state.current_player]
