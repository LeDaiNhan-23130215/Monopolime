extends Node
class_name GameState

var players = []
var current_player = 0
var board_size = 40
var double_count = 0
var turn_number: int = 1
var max_turns: int = 0
var victory_mode: String = "bankruptcy"

func _ready():
	players = [
		add_player(0, "P1"),
		add_player(1, "P2")
	]

func add_player(id, player_name, avatar_id = 0):
	var p = Player.new(id, player_name)
	var state = PlayerState.new()
	state.position = 0
	state.balance = 1500
	p.state = state
	p.avatar_id = avatar_id
	players.append(p)
	return p
