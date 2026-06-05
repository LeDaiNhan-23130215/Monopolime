extends Node2D

@onready var game_state      : GameState      = $GameState
@onready var dice            : Dice           = $Dice
@onready var game_controller : GameController = $GameController
@onready var asset_manager   : AssetManager   = $GameController/AssetManager
@onready var ui              : GameUI         = $GameUI
@onready var board           : Board          = $Board
@onready var token_layer                      = $Board/Tokens

var token_scene = preload("res://player_token.tscn")


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#BFEFFF"))
	_add_ocean_background()

	asset_manager.board = board
	asset_manager.asset_action_completed.connect(
		game_controller._on_asset_action_completed
	)

	game_controller.game_state = game_state
	game_controller.dice = dice
	game_controller.ui = ui
	game_controller.board = board
	game_controller.asset_manager = asset_manager
	ui.game_controller = game_controller

	ui.show_setup_menu()
	ui.setup_finished.connect(_on_setup_finished)


func _on_setup_finished() -> void:
	for player in game_state.players:
		var token = token_scene.instantiate()
		token.player_id = player.player_id
		token_layer.add_child(token)
		player.token = token
		token.get_random_token_texture()

		var base_pos = board.get_cell_position(0)
		var offset = Vector2(player.player_id * 15, 0)
		token.position = base_pos + offset

	game_controller.start_turn()


func _add_ocean_background() -> void:
	var layer := CanvasLayer.new()
	layer.name = "OceanBackground"
	layer.layer = -100
	add_child(layer)

	var bg := ColorRect.new()
	bg.name = "LightOceanBlue"
	bg.color = Color("#BFEFFF")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bg)
