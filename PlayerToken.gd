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
	# Hàm này của bạn bị dở dang, nhưng do token_sprite.centered = true 
	# ở _ready() nên Godot đã tự động căn giữa rồi. Ta có thể bỏ trống hoặc log.
	pass


# ==========================================
# CẬP NHẬT HIỂN THỊ SỐ DƯ TỔNG (FIX LỖI CRASH)
# ==========================================
func update_balance_display(new_balance: int) -> void:
	# Nếu quân cờ của bạn có một node Label con tên là "BalanceLabel" để hiện tổng tiền:
	if has_node("BalanceLabel"):
		$BalanceLabel.text = "$" + str(new_balance)
	else:
		# Lệnh pass giúp game không bị crash nếu bạn chưa thiết kế Label tĩnh cho số dư
		pass 


# ==========================================
# HIỆU ỨNG SỐ TIỀN BAY LÊN RỒI MỜ DẦN & PHÁT ÂM THANH
# ==========================================
func show_floating_money(amount: int):
	var float_label = Label.new()
	
	if amount > 0:
		float_label.text = "+$" + str(amount)
		float_label.add_theme_color_override("font_color", Color.GREEN)
		
		# [MỚI] Phát nhạc cộng tiền
		if add_money_sound:
			add_money_sound.play()
			
	else:
		float_label.text = "-$" + str(abs(amount))
		float_label.add_theme_color_override("font_color", Color.RED)
		
		# [MỚI] Phát nhạc trừ tiền
		if deduct_money_sound:
			deduct_money_sound.play()
		
	# Ép viền đen cho chữ dễ đọc trên mọi nền
	float_label.add_theme_color_override("font_outline_color", Color.BLACK)
	float_label.add_theme_constant_override("outline_size", 6)
	
	# Ép kích thước chữ to lên
	float_label.add_theme_font_size_override("font_size", 24)
	
	# Ép Z-index bằng 100 để chắc chắn nó NẰM TRÊN CÙNG
	float_label.z_index = 100
	
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Đặt vị trí xuất phát bay từ trên đỉnh đầu quân cờ
	float_label.position = Vector2(-20, -30)
	
	add_child(float_label)
	
	# Tạo hiệu ứng bay
	var tween = create_tween()
	# Cho bay vút lên trên 50 pixel mượt mà trong 1.5 giây
	tween.tween_property(float_label, "position", float_label.position + Vector2(0, -50), 1.5)
	tween.parallel().tween_property(float_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(float_label.queue_free)
