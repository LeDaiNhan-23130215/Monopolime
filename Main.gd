extends Node

@onready var game_state = $GameState
@onready var dice = $Dice
@onready var game_controller = $GameController
@onready var ui = $GameUI
@onready var board = $Board
@onready var token_layer = $Tokens
@onready var token_scene = preload("res://player_token.tscn")

func _ready():
	game_controller.game_state = game_state
	game_controller.dice = dice
	game_controller.ui = ui
	game_controller.board = board
	ui.game_controller = game_controller
	for player in game_state.players:
		var token = token_scene.instantiate()
		token.player_id = player.player_id
	
		token_layer.add_child(token)
		player.token = token
	
		token.position = board.get_cell_position(0)

	
	game_controller.start_turn()
