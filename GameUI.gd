extends Node
class_name GameUI

@onready var label = get_node("UI/Result")
@onready var timer = get_node("UI/DiceTimer")
@onready var double_label = get_node("UI/IsDoubleLabel")

@onready var dice1_sprite = get_node("UI/Dice1")
@onready var dice2_sprite = get_node("UI/Dice2")

@onready var audio_roll = get_node("UI/AudioRoll")

@onready var roll_button = get_node("UI/Roll Dice")

# --- PHẦN THÊM MỚI: Các Node Giao diện Tài chính ---
@onready var player_info_labels = get_node_or_null("UI/PlayerInfoContainer")
@onready var message_log = get_node_or_null("UI/MessageLog")
@onready var mortgage_dialog = get_node_or_null("UI/MortgageDialog")
# ---------------------------------------------------

var dice_textures = [
	preload("res://resources/dices/dice1.jpg"),
	preload("res://resources/dices/dice2.jpg"),
	preload("res://resources/dices/dice3.jpg"),
	preload("res://resources/dices/dice4.jpg"),
	preload("res://resources/dices/dice5.jpg"),
	preload("res://resources/dices/dice6.jpg"),
]

var rolling := false
var roll_time := 0.0

var base_scale := Vector2.ONE

var game_controller: GameController


func _ready():

	var target_size = 64.0

	var tex_size = dice1_sprite.texture.get_size().x

	var scale_factor = target_size / tex_size

	base_scale = Vector2.ONE * scale_factor

	dice1_sprite.scale = base_scale
	dice2_sprite.scale = base_scale


func show_turn(player_index):
	label.text = "Player %d's turn" % (player_index + 1)


func start_dice_animation():

	rolling = true
	roll_time = 0.0

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

	roll_time += timer.wait_time

	var fake1 = randi_range(1, 6)
	var fake2 = randi_range(1, 6)

	dice1_sprite.texture = dice_textures[fake1 - 1]
	dice2_sprite.texture = dice_textures[fake2 - 1]

	dice1_sprite.rotation = randf_range(-0.3, 0.3)
	dice2_sprite.rotation = randf_range(-0.3, 0.3)

	bounce(dice1_sprite)
	bounce(dice2_sprite)

	if roll_time >= 0.7:

		timer.stop()

		rolling = false

		var result = game_controller.final_result

		dice1_sprite.texture = dice_textures[result.dice1 - 1]
		dice2_sprite.texture = dice_textures[result.dice2 - 1]

		dice1_sprite.rotation = 0
		dice2_sprite.rotation = 0

		await game_controller.resolve_roll()


func bounce(sprite):

	sprite.scale = base_scale

	var tween = create_tween()

	tween.tween_property(
		sprite,
		"scale",
		base_scale * 1.2,
		0.1
	)

	tween.tween_property(
		sprite,
		"scale",
		base_scale,
		0.1
	)


func shake():

	var cam = get_viewport().get_camera_2d()

	if cam == null:
		return

	for i in range(5):

		cam.offset = Vector2(
			randf_range(-5, 5),
			randf_range(-5, 5)
		)

		await get_tree().create_timer(0.03).timeout

	cam.offset = Vector2.ZERO


func _on_roll_dice_pressed() -> void:
	game_controller.roll_dice()


func set_roll_enabled(enabled: bool):
	roll_button.disabled = not enabled


# =========================
# Message
# =========================

func show_message(text: String):

	label.text = text

	print("[UI Message]: ", text)


# =========================
# Mortgage
# =========================

func request_mortgage(
	player: Player,
	amount_needed: int
):

	show_message(
		player.name
		+ " thiếu $"
		+ str(amount_needed)
		+ "! Cần thế chấp."
	)

	auto_mortgage_for_test(
		player,
		amount_needed
	)


func auto_mortgage_for_test(
	player: Player,
	amount_needed: int
):

	print(
		"--- [Auto Test] Đang tự động bán đất cho ",
		player.name,
		" ---"
	)

	var target_balance = (
		player.state.balance + amount_needed
	)

	for cell in player.properties:

		if (
			not cell.is_mortgaged
			and player.state.balance < target_balance
		):

			var amount = cell.mortgage_property()

			print(
				"> Tự động thế chấp: ",
				cell.cell_name,
				" lấy $",
				amount
			)

	await get_tree().create_timer(1.5).timeout

	print("Đã xoay đủ tiền, tiếp tục game!")

	game_controller.emit_signal(
		"turn_action_completed"
	)

# ==========================================
# PHẦN THÊM MỚI: GIAO DIỆN TÀI CHÍNH
# ==========================================

# Cập nhật hiển thị số dư cho tất cả người chơi
func update_all_balances(players: Array):
	# 1. CẬP NHẬT TIỀN TRÊN ĐẦU QUÂN CỜ (Mới thêm vào)
	for p in players:
		if p.token != null:
			# Tìm nhãn BalanceLabel gắn trên quân cờ
			var token_label = p.token.find_child("BalanceLabel", true, false)
			if token_label != null:
				token_label.text = "$" + str(p.state.balance)

# Hiển thị thông báo giao dịch nổi (Toast)
func show_transaction_message(text: String):
	if message_log:
		message_log.text = text
		message_log.visible = true
		await get_tree().create_timer(2.0).timeout
		message_log.visible = false
	else:
		print("[Transaction UI]: ", text)

# Giao diện thế chấp (để dành sau này bạn tắt Auto Test thì gọi hàm này)
func show_mortgage_dialog_ui(payer: Player, amount_needed: int):
	if mortgage_dialog:
		mortgage_dialog.title = "Thiếu tiền!"
		mortgage_dialog.dialog_text = payer.name + " cần thêm $" + str(amount_needed) + ".\nBạn có muốn thế chấp tài sản không?"
		mortgage_dialog.popup_centered()
		
		if not mortgage_dialog.confirmed.is_connected(_on_mortgage_confirmed):
			mortgage_dialog.confirmed.connect(_on_mortgage_confirmed.bind(payer))

func _on_mortgage_confirmed(payer: Player):
	print("UI: Mở bảng chọn đất để thế chấp cho ", payer.name)

# Hiển thị popup Game Over / Phá sản
func show_bankruptcy_ui(player_name: String):
	var panel = find_child("GameOverPanel", true, false)
	if panel:
		panel.show()
		
		var title = panel.find_child("TitleLabel", true, false)
		var msg = panel.find_child("MessageLabel", true, false)
		
		if title:
			title.text = "CÓ NGƯỜI PHÁ SẢN!"
			title.add_theme_color_override("font_color", Color.RED)
		if msg:
			msg.text = player_name + " đã hết sạch tiền và bị tịch thu tài sản!"
			
		await get_tree().create_timer(3.0).timeout
		panel.hide()

func show_winner_ui(winner_name: String):
	var panel = find_child("GameOverPanel", true, false)
	if panel:
		panel.show()
		
		var title = panel.find_child("TitleLabel", true, false)
		var msg = panel.find_child("MessageLabel", true, false)
		
		if title:
			title.text = "🏆 KẾT THÚC VÁN CỜ 🏆"
			title.add_theme_color_override("font_color", Color.YELLOW)
		if msg:
			msg.text = "Chúc mừng " + winner_name + " đã trở thành TỶ PHÚ!"
