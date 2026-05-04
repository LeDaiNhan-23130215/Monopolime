extends Node

@onready var game_state = $GameState
@onready var dice = $Dice
@onready var turn_manager = $TurnManager
@onready var view = $GameView

func _ready():
	turn_manager.game_state = game_state
	turn_manager.dice = dice
	turn_manager.view = view
	
	view.turn_manager = turn_manager
	
	turn_manager.start_turn()
