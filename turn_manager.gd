extends Node

var dice = Dice.new()

var players = ["A", "B"]
var positions = [0, 0]

var current_player = 0
var board_size = 20

@onready var label = get_node("../UI/Result")
@onready var timer = get_node("../UI/DiceTimer")

@onready var dice1_sprite = get_node("../UI/Dice1")
@onready var dice2_sprite = get_node("../UI/Dice2")

var rolling = false
var roll_time = 0
var final_result = null

func _ready():
	randomize()

func start_turn():
	var result = dice.roll()

	print("Player:", players[current_player])
	print("Dice:", result.total)
	
	update_ui(result)
	
	move_player(result.total)
	end_turn()
	
func move_player(steps):
	positions[current_player] += steps
	positions[current_player] %= board_size

	print("New position:", positions[current_player])
	
func end_turn():
	current_player = (current_player + 1) % players.size()

func _on_roll_dice_pressed() -> void:
	if rolling:
		return
	
	rolling = true
	roll_time = 0
	
	final_result = dice.roll()
	timer.start()
	
func update_ui(result):
	label.text = "Dice: %d + %d = %d" % [result.dice1, result.dice2, result.total]


func _on_dice_timer_timeout() -> void:
	if not rolling:
		return
	
	roll_time += 0.1
	
	var fake1 = randi_range(1, 6)
	var fake2 = randi_range(1, 6)
	dice1_sprite.texture = load("res://resource/dices/dice%d.jpg" % fake1)
	dice2_sprite.texture = load("res://resources/dices/dice%d.jpg" % fake2)
	if roll_time == 0.7:
		timer.stop()
		rolling = false
		
		label.text = "Dice: %d + %d = %d" % [
			final_result.dice1,
			final_result.dice2,
			final_result.total
		]
		
		move_player(final_result.total)
		end_turn()
		
