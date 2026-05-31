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
	# 1. Gán board cho AssetManager TRƯỚC (nó cần board.cells)
	asset_manager.board = board

	# 2. Connect signal của AssetManager về GameController
	asset_manager.asset_action_completed.connect(
		game_controller._on_asset_action_completed
	)

	# 3. Gán tất cả tham chiếu cho GameController
	game_controller.game_state    = game_state
	game_controller.dice          = dice
	game_controller.ui            = ui
	game_controller.board         = board
	game_controller.asset_manager = asset_manager   # node từ scene, không tạo mới

	# 4. Gán game_controller cho UI
	ui.game_controller = game_controller
	
	# Show setup menu first
	ui.show_setup_menu()
	ui.setup_finished.connect(_on_setup_finished)

	# 5. Tạo token cho từng người chơi
	for player in game_state.players:
		var token       = token_scene.instantiate()
		token.player_id = player.player_id
		token_layer.add_child(token)
		player.token    = token
		token.get_random_token_texture()
		var base_pos    = board.get_cell_position(0)
		var offset      = Vector2(player.player_id * 15, 0)
		token.position  = base_pos + offset

	# 6. Bắt đầu game
	game_controller.start_turn()
