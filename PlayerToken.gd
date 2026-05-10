extends Node2D
class_name PlayerToken

var player_id: int

@onready var token_sprite = $TokenSprite

# --- KHAI BÁO NODE ÂM THANH ---
@onready var add_money_sound = $AddMoneySound
@onready var deduct_money_sound = $DeductMoneySound

func _ready():
	token_sprite.centered = true
	token_sprite.scale = Vector2(0.458, 0.458)
	
func move_to(target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.2)
	await tween.finished
	
func get_random_token_texture():
	var tex = TokenManage.get_random_texture()
	token_sprite.texture = tex
	center_sprite()

func center_sprite():
	if token_sprite.texture == null:
		return
	pass

func update_balance_display(new_balance: int) -> void:
	if has_node("BalanceLabel"):
		get_node("BalanceLabel").text = "$" + str(new_balance)

func show_floating_money(amount: int):
	var float_label = Label.new()
	if amount > 0:
		float_label.text = "+$" + str(amount)
		float_label.add_theme_color_override("font_color", Color.GREEN)
		if add_money_sound: add_money_sound.play()
	else:
		float_label.text = "-$" + str(abs(amount))
		float_label.add_theme_color_override("font_color", Color.RED)
		if deduct_money_sound: deduct_money_sound.play()
		
	float_label.add_theme_color_override("font_outline_color", Color.BLACK)
	float_label.add_theme_constant_override("outline_size", 6)
	float_label.add_theme_font_size_override("font_size", 24)
	float_label.z_index = 100
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.position = Vector2(-20, -30)
	
	add_child(float_label)
	
	var tween = create_tween()
	tween.tween_property(float_label, "position", float_label.position + Vector2(0, -50), 1.5)
	tween.parallel().tween_property(float_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(float_label.queue_free)

# ==========================================
# [MỚI] HIỆU ỨNG PHÁ SẢN CỦA QUÂN CỜ
# ==========================================
func play_bankrupt_animation():
	# 1. Biến quân cờ thành màu xám (tạo cảm giác mất mát)
	token_sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)
	
	# 2. Tạo hiệu ứng xoay tròn và nhỏ dần cho đến khi biến mất
	var tween = create_tween().set_parallel(true)
	
	# Xoay 2 vòng (720 độ)
	tween.tween_property(token_sprite, "rotation_degrees", 720.0, 1.0)
	# Thu nhỏ về 0
	tween.tween_property(token_sprite, "scale", Vector2.ZERO, 1.0)
	# Mờ dần hoàn toàn
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	# Chờ hiệu ứng xong thì tự xóa mình khỏi scene
	await tween.finished
	queue_free()
