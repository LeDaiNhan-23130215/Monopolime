extends Node
class_name GameState

var players = []
var current_player = 0
var board_size = 20
var double_count = 0

func _ready():
	players = [
		create_player(0, "P1"),
		create_player(1, "P2")
	]

func add_player(id, player_name, avatar_id = 0):
	var p = Player.new(id, player_name)
	var state = PlayerState.new()
	state.position = 0
	state.balance = 1500
	p.state = state
	# p.avatar_id = avatar_id # We can add avatar property later
	players.append(p)
	return p
