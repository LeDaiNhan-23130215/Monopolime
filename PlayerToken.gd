extends Node2D
class_name PlayerToken

var player_id: int

@onready var token_sprite = $TokenSprite
@onready var balance_label = $BalanceLabel

func _ready():
	token_sprite.centered = true
	token_sprite.scale = Vector2(0.458, 0.458)
	
func move_to(target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.2)
	await tween.finished
	
func get_random_token_texture():
	var token_manager = get_node_or_null("/root/TokenManage")
	if token_manager == null:
		return
	var tex = token_manager.get_random_texture()
	token_sprite.texture = tex
	
	center_sprite()

func center_sprite():
	if token_sprite.texture == null:
		return
	
	var size = token_sprite.texture.get_size() * token_sprite.scale
	
	# Tạo hiệu ứng số tiền bay lên rồi mờ dần
func show_floating_money(amount: int):
	var float_label = Label.new()
	
	# Nếu số tiền > 0 thì hiện màu xanh (cộng), ngược lại màu đỏ (trừ)
	if amount > 0:
		float_label.text = "+$" + str(amount)
		float_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		float_label.text = "-$" + str(abs(amount))
		float_label.add_theme_color_override("font_color", Color.RED)
		
	float_label.add_theme_color_override("font_outline_color", Color.BLACK)
	float_label.add_theme_constant_override("outline_size", 4)
	
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	float_label.position = Vector2(-20, -40) 
	
	add_child(float_label)
	
	var tween = create_tween()
	
	tween.tween_property(float_label, "position", float_label.position + Vector2(0, -30), 2.0)
	
	# 2. Cùng lúc đó (parallel), làm cho chữ mờ dần đi (độ trong suốt alpha về 0)
	tween.parallel().tween_property(float_label, "modulate:a", 0.0, 1.0)
	
	# 3. Khi bay xong và mờ hết thì xóa cái nhãn này đi cho nhẹ game
	tween.tween_callback(float_label.queue_free)
	
func set_balance (value: int):
	balance_label.text = "$" + str(value)
	
	if value >= 200:
		balance_label.modulate = Color.LIME_GREEN
	else:
		balance_label.modulate = Color.TOMATO
