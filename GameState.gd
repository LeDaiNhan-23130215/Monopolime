extends Node
class_name GameState

var players = []

var current_player = 0
var board_size = 20

var double_count = 0

func _ready():
	players = [
		create_player(0, "Player A"),
		create_player(1, "Player B"),
		create_player(2, "Player C"),
	]

func create_player(id, player_name):
	var p = Player.new(id, player_name)

	var state = PlayerState.new()
	state.position = 0
	state.balance = 1500

	p.state = state

	return p
