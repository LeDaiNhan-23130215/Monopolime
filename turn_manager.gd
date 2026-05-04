extends Node
class_name TurnManager

@onready var game_state: GameState = get_node("../GameState")
@onready var dice: Dice = get_node("../Dice")

@onready var view: GameView = get_node("../GameView")

var final_result = null

func start_turn():
	print("===== TURN =====")
	print("Player:", game_state.players[game_state.current_player])
	
	view.show_turn(game_state.current_player)

func roll_dice():
	print("ROLL DICE CALLED")
	final_result = dice.roll()
	print("RESULT =", final_result)
	view.start_dice_animation(final_result)

func resolve_roll():
	var d1 = final_result.dice1
	var d2 = final_result.dice2
	
	view.show_result(final_result)
	
	if d1 == d2:
		game_state.double_count += 1
		view.show_double()
		
		if game_state.double_count < 3:
			move_player(final_result.total)
			return
		else:
			go_to_jail()
			end_turn()
			return
	else:
		move_player(final_result.total)
		game_state.double_count = 0
		end_turn()

func move_player(steps):
	var i = game_state.current_player
	
	game_state.positions[i] += steps
	game_state.positions[i] %= game_state.board_size
	
	print("New position:", game_state.positions[i])
	view.update_position(i, game_state.positions[i])

func end_turn():
	game_state.current_player = (game_state.current_player + 1) % game_state.players.size()
	game_state.double_count = 0
	
	start_turn()

func go_to_jail():
	print("GO TO JAIL!")
	view.show_jail()
