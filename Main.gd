extends Node

@onready var game_state = $GameState
@onready var dice = $Dice
@onready var game_controller = $GameController
@onready var ui = $GameUI

func _ready():
	game_controller.game_state = game_state
	game_controller.dice = dice
	game_controller.ui = ui
	
	ui.game_controller = game_controller
	
	game_controller.start_turn()
