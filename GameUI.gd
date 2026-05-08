extends Node
class_name GameUI

@onready var label = get_node("UI/Result")
@onready var timer = get_node("UI/DiceTimer")
@onready var double_label = get_node("UI/IsDoubleLabel")

@onready var dice1_sprite = get_node("UI/Dice1")
@onready var dice2_sprite = get_node("UI/Dice2")

@onready var audio_roll = get_node("UI/AudioRoll")

@onready var roll_button = get_node("UI/Roll Dice")

var dice_textures = [
	preload("res://resources/dices/dice1.jpg"),
	preload("res://resources/dices/dice2.jpg"),
	preload("res://resources/dices/dice3.jpg"),
	preload("res://resources/dices/dice4.jpg"),
	preload("res://resources/dices/dice5.jpg"),
	preload("res://resources/dices/dice6.jpg"),
]

var rolling = false
var roll_time = 0
var base_scale = Vector2.ONE

var game_controller: GameController

func _ready():
	var target_size = 64.0
	var tex_size = dice1_sprite.texture.get_size().x
	var scale_factor = target_size / tex_size
	
	base_scale = Vector2.ONE * scale_factor
	
	dice1_sprite.scale = base_scale
	dice2_sprite.scale = base_scale


func show_turn(player_index):
	label.text = "Player %d's turn" % player_index

func start_dice_animation():
	rolling = true
	roll_time = 0
	timer.start()
	
	audio_roll.play()
	shake()

func show_result(result):
	label.text = "Dice: %d + %d = %d" % [
		result.dice1,
		result.dice2,
		result.total()
	]
	audio_roll.stop()

func show_double():
	double_label.visible = true
	double_label.text = "DOUBLE!"
	
	await get_tree().create_timer(2.0).timeout
	double_label.visible = false

func update_position(player, pos):
	print("Player", player, "->", pos)

func show_jail():
	label.text = "GO TO JAIL!"

func _on_dice_timer_timeout():
	if not rolling:
		return
	
	roll_time += 0.1
	
	var fake1 = randi_range(1, 6)
	var fake2 = randi_range(1, 6)
	
	dice1_sprite.texture = dice_textures[fake1 - 1]
	dice2_sprite.texture = dice_textures[fake2 - 1]
	
	dice1_sprite.rotation += randf_range(-0.3, 0.3)
	dice2_sprite.rotation += randf_range(-0.3, 0.3)
	
	bounce(dice1_sprite)
	bounce(dice2_sprite)
	
	if roll_time >= 0.7:
		timer.stop()
		rolling = false
		
		var result = game_controller.final_result
		
		dice1_sprite.texture = dice_textures[result.dice1 - 1]
		dice2_sprite.texture = dice_textures[result.dice2 - 1]
		
		# Gọi controller xử lý logic tài chính và di chuyển
		game_controller.resolve_roll()

func bounce(sprite):
	sprite.scale = base_scale
	
	var tween = create_tween()
	tween.tween_property(sprite, "scale", base_scale * 1.2, 0.1)
	tween.tween_property(sprite, "scale", base_scale, 0.1)
	
	
func shake():
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return
	
	cam.offset = Vector2(randf_range(-5,5), randf_range(-5,5))
	await get_tree().create_timer(0.05).timeout
	cam.offset = Vector2.ZERO


func _on_roll_dice_pressed() -> void:
	game_controller.roll_dice()

func set_roll_enabled(enabled: bool):
	roll_button.disabled = not enabled

# Hiển thị thông báo (Đi qua GO, thưởng, phạt...)
func show_message(text: String):
	label.text = text
	print("[UI Message]: ", text)

# Yêu cầu thế chấp khi không đủ tiền
func request_mortgage(player: Player, amount_needed: int):
	show_message(player.name + " thiếu $" + str(amount_needed) + "! Cần thế chấp.")
	
	# === LOGIC GIẢ LẬP ĐỂ TEST GAME KHÔNG BỊ KẸT MÀN HÌNH ===
	auto_mortgage_for_test(player, amount_needed)

func auto_mortgage_for_test(player: Player, amount_needed: int):
	print("--- [Auto Test] Đang tự động bán đất để trả nợ cho ", player.name, " ---")
	
	var target_balance = player.balance + amount_needed
	
	for cell in player.properties:
		if not cell.is_mortgaged and player.balance < target_balance:
			var amount = cell.mortgage_property()
			print("> Tự động thế chấp: ", cell.cell_name, " lấy $", amount)
			
	# Chờ 1.5 giây để bạn kịp nhìn console
	await get_tree().create_timer(1.5).timeout 
	
	# Quan trọng: Kích hoạt lại lượt đi cho GameController
	print("Đã xoay đủ tiền, tiếp tục game!")
	
	game_controller.emit_signal("turn_action_completed")
