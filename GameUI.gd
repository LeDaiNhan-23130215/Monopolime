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

var rolling := false
var roll_time := 0.0

var base_scale := Vector2.ONE

var game_controller: GameController

# UI nodes được tạo động
var player_info_panel: PanelContainer = null
var player_info_label: RichTextLabel = null
var message_label: Label = null
var buy_panel: PanelContainer = null
var game_over_panel: PanelContainer = null


func _ready():

	var target_size = 64.0

	var tex_size = dice1_sprite.texture.get_size().x

	var scale_factor = target_size / tex_size

	base_scale = Vector2.ONE * scale_factor

	dice1_sprite.scale = base_scale
	dice2_sprite.scale = base_scale

	_create_player_info_panel()
	_create_message_label()
	_create_buy_panel()
	_create_game_over_panel()


# =========================
# Tạo UI động
# =========================

func _create_player_info_panel():
	var ui_layer = get_node("UI")

	player_info_panel = PanelContainer.new()
	player_info_panel.position = Vector2(10, 10)
	player_info_panel.size = Vector2(280, 200)

	# Tạo style box tối
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	style.border_color = Color(0.3, 0.5, 0.9, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	player_info_panel.add_theme_stylebox_override("panel", style)

	player_info_label = RichTextLabel.new()
	player_info_label.bbcode_enabled = true
	player_info_label.fit_content = true
	player_info_label.scroll_active = false
	player_info_label.add_theme_font_size_override("normal_font_size", 13)
	player_info_panel.add_child(player_info_label)

	ui_layer.add_child(player_info_panel)


func _create_message_label():
	var ui_layer = get_node("UI")

	var msg_panel = PanelContainer.new()
	msg_panel.name = "MessagePanel"
	msg_panel.position = Vector2(300, 500)
	msg_panel.size = Vector2(500, 50)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	msg_panel.add_theme_stylebox_override("panel", style)

	message_label = Label.new()
	message_label.text = "Chào mừng đến với Monopolime!"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	msg_panel.add_child(message_label)

	ui_layer.add_child(msg_panel)


func _create_buy_panel():
	var ui_layer = get_node("UI")

	buy_panel = PanelContainer.new()
	buy_panel.name = "BuyPanel"
	buy_panel.position = Vector2(350, 300)
	buy_panel.size = Vector2(400, 160)
	buy_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.1, 0.2, 0.95)
	style.border_color = Color(0.2, 0.8, 0.4)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(15)
	buy_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"

	var title_label = Label.new()
	title_label.name = "BuyTitle"
	title_label.text = "Mua đất?"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	vbox.add_child(title_label)

	var info_label = Label.new()
	info_label.name = "BuyInfo"
	info_label.text = ""
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(info_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var buy_button = Button.new()
	buy_button.name = "BuyYes"
	buy_button.text = "✅ MUA"
	buy_button.custom_minimum_size = Vector2(120, 40)
	buy_button.add_theme_font_size_override("font_size", 16)
	buy_button.pressed.connect(_on_buy_yes)
	hbox.add_child(buy_button)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(20, 0)
	hbox.add_child(spacer2)

	var skip_button = Button.new()
	skip_button.name = "BuyNo"
	skip_button.text = "❌ BỎ QUA"
	skip_button.custom_minimum_size = Vector2(120, 40)
	skip_button.add_theme_font_size_override("font_size", 16)
	skip_button.pressed.connect(_on_buy_no)
	hbox.add_child(skip_button)

	vbox.add_child(hbox)
	buy_panel.add_child(vbox)
	ui_layer.add_child(buy_panel)


func _create_game_over_panel():
	var ui_layer = get_node("UI")

	game_over_panel = PanelContainer.new()
	game_over_panel.name = "GameOverPanel"
	game_over_panel.position = Vector2(250, 200)
	game_over_panel.size = Vector2(600, 250)
	game_over_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.0, 0.15, 0.95)
	style.border_color = Color(1.0, 0.8, 0.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(20)
	game_over_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var winner_label = Label.new()
	winner_label.name = "WinnerLabel"
	winner_label.text = "🎉 GAME OVER!"
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_label.add_theme_font_size_override("font_size", 36)
	winner_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	vbox.add_child(winner_label)

	var details_label = Label.new()
	details_label.name = "DetailsLabel"
	details_label.text = ""
	details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details_label.add_theme_font_size_override("font_size", 18)
	details_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(details_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var restart_btn = Button.new()
	restart_btn.name = "RestartButton"
	restart_btn.text = "🔄 CHƠI LẠI"
	restart_btn.custom_minimum_size = Vector2(200, 50)
	restart_btn.add_theme_font_size_override("font_size", 20)
	restart_btn.pressed.connect(_on_restart)
	vbox.add_child(restart_btn)

	game_over_panel.add_child(vbox)
	ui_layer.add_child(game_over_panel)


# =========================
# Hiển thị thông tin người chơi
# =========================

func update_player_info(players: Array):
	if player_info_label == null:
		return

	var bbcode = "[b]📊 THÔNG TIN NGƯỜI CHƠI[/b]\n"
	bbcode += "━━━━━━━━━━━━━━━━━━\n"

	for p in players:
		var color_tag = _get_player_color_tag(p.player_id)
		var status = ""

		if p.is_bankrupt():
			status = " 💀 PHÁ SẢN"
		elif p.state.in_jail:
			status = " 🔒 Tù"

		var current_marker = ""
		if game_controller and p == game_controller.get_current_player():
			current_marker = "▶ "

		bbcode += current_marker + "[color=" + color_tag + "]" + p.name + "[/color]"
		bbcode += status + "\n"
		if not p.is_bankrupt():
			bbcode += "  💰 $" + str(p.state.balance)
			bbcode += "  🏠 " + str(p.properties.size()) + " đất"
			if p.state.special_cards > 0:
				bbcode += "  🃏 " + str(p.state.special_cards)
			bbcode += "\n"

	player_info_label.text = bbcode


func _get_player_color_tag(id: int) -> String:
	match id:
		0: return "#FF6666"
		1: return "#6688FF"
		2: return "#66FF66"
		3: return "#FFFF66"
	return "#FFFFFF"


# =========================
# Turn & Dice
# =========================

func show_turn(player_index):
	label.text = "Lượt của " + _get_player_name(player_index)


func _get_player_name(index: int) -> String:
	if game_controller and index < game_controller.game_state.players.size():
		return game_controller.game_state.players[index].name
	return "Player " + str(index + 1)


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
	label.text = "VÀO TÙ!"


# =========================
# Message
# =========================

func show_message(text: String):

	if message_label:
		message_label.text = text

	print("[UI Message]: ", text)


# =========================
# Buy Prompt
# =========================

func show_buy_prompt(player: Player, cell: Cell):
	if buy_panel == null:
		return

	set_roll_enabled(false)
	buy_panel.visible = true

	var title = buy_panel.get_node("VBox/BuyTitle")
	var info = buy_panel.get_node("VBox/BuyInfo")

	title.text = "🏠 Mua " + cell.cell_name + "?"
	info.text = "Giá: $" + str(cell.price) + "  |  Thuê: $" + str(cell.rent_price) + "\nSố dư: $" + str(player.state.balance)


func _on_buy_yes():
	buy_panel.visible = false
	set_roll_enabled(true)
	game_controller.emit_signal("buy_decision_made", true)


func _on_buy_no():
	buy_panel.visible = false
	set_roll_enabled(true)
	game_controller.emit_signal("buy_decision_made", false)


# =========================
# Game Over
# =========================

func show_game_over(winner: Player):
	if game_over_panel == null:
		return

	set_roll_enabled(false)
	game_over_panel.visible = true

	var winner_label = game_over_panel.get_node("VBox/WinnerLabel")
	var details_label = game_over_panel.get_node("VBox/DetailsLabel")

	winner_label.text = "🎉 " + winner.name + " CHIẾN THẮNG! 🎉"
	details_label.text = "Tổng tài sản: $" + str(winner.state.balance) + " | Đất: " + str(winner.properties.size())


func _on_restart():
	get_tree().reload_current_scene()


# =========================
# Dice Animation
# =========================

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
