extends Node
class_name GameState

var players = []

var current_player = 0
var board_size = 20

var double_count = 0

func _ready():
	players = [
		create_player(0, "A"),
		create_player(1, "B")
	]

func create_player(id, name):
	var p = Player.new(id, name)
	
	var state = PlayerState.new()
	state.position = 0
	state.balance = 1500
	
	p.state = state
	
	return p
