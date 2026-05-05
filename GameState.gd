extends Node

class_name GameState

var players = [
	Player.new(0, "A"),
	Player.new(1, "B")
]

var current_player = 0
var board_size = 20

var double_count = 0
