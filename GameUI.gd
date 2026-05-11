extends Node
class_name GameUI

signal setup_finished
signal card_dismissed

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

# Dynamic UI nodes
var player_info_panel: PanelContainer
var player_info_label: RichTextLabel
var message_label: Label
var buy_panel: PanelContainer
var build_panel: PanelContainer
var card_panel: PanelContainer
var game_over_panel: PanelContainer

func _ready():
	var target_size = 64.0
	var tex_size = dice1_sprite.texture.get_size().x
	base_scale = Vector2.ONE * (target_size / tex_size)
	dice1_sprite.scale = base_scale
	dice2_sprite.scale = base_scale

	_create_player_info_panel()
	_create_message_label()
	_create_buy_panel()
	_create_build_panel()
	_create_card_panel()
	_create_game_over_panel()

# ======== PLAYER INFO HUD ========

func _create_player_info_panel():
	var ui_layer = get_node("UI")
	player_info_panel = PanelContainer.new()
	player_info_panel.position = Vector2(830, 20)
	player_info_panel.size = Vector2(300, 220)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	style.border_color = Color(0.8, 0.6, 0.2, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 10
	player_info_panel.add_theme_stylebox_override("panel", style)

	player_info_label = RichTextLabel.new()
	player_info_label.bbcode_enabled = true
	player_info_label.fit_content = true
	player_info_label.scroll_active = false
	player_info_label.add_theme_font_size_override("normal_font_size", 12)
	player_info_panel.add_child(player_info_label)
	ui_layer.add_child(player_info_panel)

func _create_message_label():
	var ui_layer = get_node("UI")
	var msg_panel = PanelContainer.new()
	msg_panel.name = "MessagePanel"
	msg_panel.position = Vector2(100, 15)
	msg_panel.size = Vector2(650, 50)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	style.border_color = Color(0.8, 0.6, 0.2, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(25)
	style.set_content_margin_all(8)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 5
	msg_panel.add_theme_stylebox_override("panel", style)

	message_label = Label.new()
	message_label.text = "🎲 Chào mừng đến với Monopolime!"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 15)
	message_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	msg_panel.add_child(message_label)
	ui_layer.add_child(msg_panel)

# ======== BUY PROMPT ========

func _create_buy_panel():
	var ui_layer = get_node("UI")
	buy_panel = PanelContainer.new()
	buy_panel.name = "BuyPanel"
	buy_panel.position = Vector2(340, 280)
	buy_panel.size = Vector2(400, 170)
	buy_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.16, 0.95)
	style.border_color = Color(0.2, 0.75, 0.4)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(16)
	buy_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"

	var title = Label.new()
	title.name = "BuyTitle"
	title.text = "Mua đất?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	vbox.add_child(title)

	var info = Label.new()
	info.name = "BuyInfo"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(info)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var buy_btn = Button.new()
	buy_btn.name = "BuyYes"
	buy_btn.text = "✅ MUA"
	buy_btn.custom_minimum_size = Vector2(130, 42)
	buy_btn.add_theme_font_size_override("font_size", 16)
	buy_btn.pressed.connect(_on_buy_yes)
	hbox.add_child(buy_btn)

	var sp2 = Control.new()
	sp2.custom_minimum_size = Vector2(20, 0)
	hbox.add_child(sp2)

	var skip_btn = Button.new()
	skip_btn.name = "BuyNo"
	skip_btn.text = "❌ BỎ QUA"
	skip_btn.custom_minimum_size = Vector2(130, 42)
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.pressed.connect(_on_buy_no)
	hbox.add_child(skip_btn)

	vbox.add_child(hbox)
	buy_panel.add_child(vbox)
	ui_layer.add_child(buy_panel)


# ======== BUILD PROMPT ========

func _create_build_panel():
	var ui_layer = get_node("UI")
	build_panel = PanelContainer.new()
	build_panel.name = "BuildPanel"
	build_panel.position = Vector2(340, 280)
	build_panel.size = Vector2(400, 170)
	build_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.12, 0.06, 0.95)
	style.border_color = Color(0.3, 0.85, 0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(16)
	build_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"

	var title = Label.new()
	title.name = "BuildTitle"
	title.text = "🏗️ Xây nhà?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	vbox.add_child(title)

	var info = Label.new()
	info.name = "BuildInfo"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(info)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var build_btn = Button.new()
	build_btn.name = "BuildYes"
	build_btn.text = "🏠 XÂY"
	build_btn.custom_minimum_size = Vector2(130, 42)
	build_btn.add_theme_font_size_override("font_size", 16)
	build_btn.pressed.connect(_on_build_yes)
	hbox.add_child(build_btn)

	var sp2 = Control.new()
	sp2.custom_minimum_size = Vector2(20, 0)
	hbox.add_child(sp2)

	var skip_btn = Button.new()
	skip_btn.name = "BuildNo"
	skip_btn.text = "⏭️ BỎ QUA"
	skip_btn.custom_minimum_size = Vector2(130, 42)
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.pressed.connect(_on_build_no)
	hbox.add_child(skip_btn)

	vbox.add_child(hbox)
	build_panel.add_child(vbox)
	ui_layer.add_child(build_panel)


# ======== CARD POPUP ========

func _create_card_panel():
	var ui_layer = get_node("UI")
	card_panel = PanelContainer.new()
	card_panel.name = "CardPanel"
	card_panel.position = Vector2(250, 140)
	card_panel.size = Vector2(540, 260)
	card_panel.visible = false
	# Z-order đưa lên trước
	card_panel.z_index = 100

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.12, 0.98)
	style.border_color = Color(1.0, 0.7, 0.2)
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(24)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 20
	card_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)

	# Thanh tiêu đề loại thẻ
	var title_bg = PanelContainer.new()
	var tbg_style = StyleBoxFlat.new()
	tbg_style.bg_color = Color(1.0, 0.7, 0.2, 0.15)
	tbg_style.set_corner_radius_all(10)
	tbg_style.set_content_margin_all(6)
	title_bg.add_theme_stylebox_override("panel", tbg_style)

	var card_title = Label.new()
	card_title.name = "CardTitle"
	card_title.text = "CƠ HỘI"
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.add_theme_font_size_override("font_size", 24)
	card_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	title_bg.add_child(card_title)
	vbox.add_child(title_bg)

	# Gạch phân cách
	var sep = HSeparator.new()
	sep.add_theme_color_override("color", Color(1.0, 0.7, 0.2, 0.4))
	vbox.add_child(sep)

	# Nội dung thẻ
	var card_text = Label.new()
	card_text.name = "CardText"
	card_text.text = ""
	card_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_text.add_theme_font_size_override("font_size", 18)
	card_text.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_text.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(card_text)

	# Nhãn hiển thị số tiền
	var amount_lbl = Label.new()
	amount_lbl.name = "AmountLabel"
	amount_lbl.text = ""
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_lbl.add_theme_font_size_override("font_size", 28)
	amount_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	vbox.add_child(amount_lbl)

	# Nút OK
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)

	var ok_btn = Button.new()
	ok_btn.name = "OkBtn"
	ok_btn.text = "  ✔️  OK  "
	ok_btn.custom_minimum_size = Vector2(160, 44)
	ok_btn.add_theme_font_size_override("font_size", 18)
	var ok_style = StyleBoxFlat.new()
	ok_style.bg_color = Color(0.15, 0.55, 0.25)
	ok_style.set_corner_radius_all(10)
	ok_style.set_border_width_all(2)
	ok_style.border_color = Color(0.3, 0.9, 0.5)
	ok_btn.add_theme_stylebox_override("normal", ok_style)
	ok_btn.pressed.connect(_on_card_ok_pressed)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_child(ok_btn)
	vbox.add_child(btn_hbox)

	card_panel.add_child(vbox)
	ui_layer.add_child(card_panel)


# ======== GAME OVER ========

func _create_game_over_panel():
	var ui_layer = get_node("UI")
	game_over_panel = PanelContainer.new()
	game_over_panel.name = "GameOverPanel"
	game_over_panel.position = Vector2(220, 180)
	game_over_panel.size = Vector2(640, 260)
	game_over_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.0, 0.1, 0.95)
	style.border_color = Color(1.0, 0.8, 0.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(24)
	game_over_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var winner_lbl = Label.new()
	winner_lbl.name = "WinnerLabel"
	winner_lbl.text = "🎉 GAME OVER!"
	winner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_lbl.add_theme_font_size_override("font_size", 36)
	winner_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0))
	vbox.add_child(winner_lbl)

	var details = Label.new()
	details.name = "DetailsLabel"
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.add_theme_font_size_override("font_size", 18)
	details.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(details)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var restart_btn = Button.new()
	restart_btn.text = "🔄 CHƠI LẠI"
	restart_btn.custom_minimum_size = Vector2(200, 50)
	restart_btn.add_theme_font_size_override("font_size", 20)
	restart_btn.pressed.connect(func(): get_tree().reload_current_scene())
	vbox.add_child(restart_btn)

	game_over_panel.add_child(vbox)
	ui_layer.add_child(game_over_panel)

# ======== PUBLIC METHODS ========

func update_player_info(players: Array):
	if player_info_label == null:
		return
	var bb = "[b]📊 NGƯỜI CHƠI[/b]\n━━━━━━━━━━━━━━━\n"
	
	var avatar_paths = [
		"res://resources/ui/avatars/avatar_boy.jpg",
		"res://resources/ui/avatars/avatar_girl.jpg",
		"res://resources/ui/avatars/avatar_cat.jpg",
		"res://resources/ui/avatars/avatar_robot.jpg"
	]
	
	for p in players:
		var c = _color_tag(p.player_id)
		var marker = "▶ " if game_controller and p == game_controller.get_current_player() else "  "
		var status = ""
		if p.is_bankrupt():
			status = " 💀"
		elif p.state.in_jail:
			status = " 🔒"
			
		var avatar = ""
		if p.get("avatar_id") != null and p.avatar_id >= 0 and p.avatar_id < avatar_paths.size():
			avatar = "[img=24x24]" + avatar_paths[p.avatar_id] + "[/img] "
			
		bb += marker + avatar + "[color=" + c + "]" + p.name + "[/color]" + status + "\n"
		if not p.is_bankrupt():
			bb += "      💰$" + str(p.state.balance) + "  🏠" + str(p.properties.size())
			if p.state.special_cards > 0:
				bb += "  🃏" + str(p.state.special_cards)
			bb += "\n\n"
	player_info_label.text = bb


func _color_tag(id: int) -> String:
	match id:
		0: return "#FF6666"
		1: return "#6699FF"
		2: return "#66FF66"
		3: return "#FFFF66"
	return "#FFFFFF"


func show_turn(player_index):
	var pname = ""
	if game_controller and player_index < game_controller.game_state.players.size():
		pname = game_controller.game_state.players[player_index].name
	else:
		pname = "Player " + str(player_index + 1)
	label.text = "Lượt: " + pname


func show_message(text: String):
	if message_label:
		message_label.text = text
	print("[UI] ", text)


func show_buy_prompt(player: Player, cell: Cell):
	if buy_panel == null:
		return
	set_roll_enabled(false)
	buy_panel.visible = true
	buy_panel.get_node("VBox/BuyTitle").text = "🏠 Mua " + cell.cell_name + "?"
	buy_panel.get_node("VBox/BuyInfo").text = "Giá: $" + str(cell.price) + "  |  Thuê: $" + str(cell.rent_price) + "\nSố dư: $" + str(player.state.balance)

var _current_build_cell: Cell = null

func show_build_prompt(player: Player, cell: Cell):
	if build_panel == null:
		return
	_current_build_cell = cell
	set_roll_enabled(false)
	build_panel.visible = true
	var type_name = "Khách sạn" if cell.house_count == 4 else "Nhà"
	build_panel.get_node("VBox/BuildTitle").text = "🏗️ Xây " + type_name + "?"
	build_panel.get_node("VBox/BuildInfo").text = cell.cell_name + " | Chi phí: $" + str(cell.house_cost) + "\nHiện có: " + str(cell.house_count) + "/5 | Số dư: $" + str(player.state.balance)


func show_card_popup(title: String, text: String, color: Color, amount: int = 0):
	if card_panel == null:
		return
	card_panel.visible = true

	var vbox = card_panel.get_node("VBox")
	
	# title_bg là child(0), CardTitle là con của nó
	var title_bg = vbox.get_child(0)
	if title_bg is PanelContainer:
		var tbg_style = StyleBoxFlat.new()
		tbg_style.bg_color = Color(color.r, color.g, color.b, 0.15)
		tbg_style.set_corner_radius_all(10)
		tbg_style.set_content_margin_all(6)
		title_bg.add_theme_stylebox_override("panel", tbg_style)
		
		var title_node = title_bg.get_node("CardTitle")
		if title_node:
			title_node.text = title
			title_node.add_theme_color_override("font_color", color)

	# Nội dung thẻ
	var card_text = vbox.get_node("CardText")
	if card_text:
		card_text.text = text

	# Số tiền (nếu có)
	var amt_lbl = vbox.get_node("AmountLabel")
	if amt_lbl:
		if amount > 0:
			amt_lbl.text = "+$" + str(amount)
			amt_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			amt_lbl.visible = true
		elif amount < 0:
			amt_lbl.text = "-$" + str(abs(amount))
			amt_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			amt_lbl.visible = true
		else:
			amt_lbl.visible = false

	# Hiệu ứng scale-in
	card_panel.scale = Vector2(0.5, 0.5)
	card_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card_panel, "modulate:a", 1.0, 0.2)


# Đợi người chơi nhấn OK rồi trả về
func show_card_and_wait(title: String, text: String, color: Color, amount: int = 0):
	show_card_popup(title, text, color, amount)
	await card_dismissed


func _on_card_ok_pressed():
	card_panel.visible = false
	emit_signal("card_dismissed")


func show_game_over(winner: Player):
	if game_over_panel == null:
		return
	set_roll_enabled(false)
	game_over_panel.visible = true
	game_over_panel.get_node("VBox/WinnerLabel").text = "🎉 " + winner.name + " CHIẾN THẮNG! 🎉"
	game_over_panel.get_node("VBox/DetailsLabel").text = "Tài sản: $" + str(winner.state.balance) + " | Đất: " + str(winner.properties.size())


func _on_buy_yes():
	buy_panel.visible = false
	set_roll_enabled(true)
	game_controller.emit_signal("buy_decision_made", true)

func _on_buy_no():
	buy_panel.visible = false
	set_roll_enabled(true)
	game_controller.emit_signal("buy_decision_made", false)

func _on_build_yes():
	build_panel.visible = false
	set_roll_enabled(true)
	if _current_build_cell and _current_build_cell.can_build_house():
		_current_build_cell.build_house()
		show_message("Đã xây nhà trên " + _current_build_cell.cell_name)
	game_controller.emit_signal("build_decision_made")

func _on_build_no():
	build_panel.visible = false
	set_roll_enabled(true)
	game_controller.emit_signal("build_decision_made")


# ======== DICE ANIMATION ========

func start_dice_animation():
	rolling = true
	roll_time = 0.0
	timer.start()
	audio_roll.play()
	shake()

func show_result(result):
	label.text = "🎲 %d + %d = %d" % [result.dice1, result.dice2, result.total()]
	audio_roll.stop()

func show_double():
	double_label.visible = true
	double_label.text = "✨ DOUBLE! ✨"
	await get_tree().create_timer(1.5).timeout
	double_label.visible = false

func show_jail():
	label.text = "🔒 VÀO TÙ!"

func update_position(player, pos):
	print("Player", player, "->", pos)

func set_roll_enabled(enabled: bool):
	roll_button.disabled = not enabled

func _on_roll_dice_pressed() -> void:
	game_controller.roll_dice()

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
	tween.tween_property(sprite, "scale", base_scale * 1.2, 0.1)
	tween.tween_property(sprite, "scale", base_scale, 0.1)

func shake():
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return
	for i in range(5):
		cam.offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		await get_tree().create_timer(0.03).timeout
	cam.offset = Vector2.ZERO


# ======== MORTGAGE ========

func request_mortgage(player: Player, amount_needed: int):
	show_message(player.name + " thiếu $" + str(amount_needed) + "! Tự động thế chấp...")
	auto_mortgage_for_test(player, amount_needed)

func auto_mortgage_for_test(player: Player, amount_needed: int):
	print("--- Tự động thế chấp cho ", player.name, " ---")
	var target = player.state.balance + amount_needed
	for cell in player.properties:
		if not cell.is_mortgaged and player.state.balance < target:
			# Bán nhà trước
			while cell.house_count > 0:
				cell.sell_house()
			var amt = cell.mortgage_property()
			if amt > 0:
				print("> Thế chấp: ", cell.cell_name, " -> $", amt)
	await get_tree().create_timer(1.0).timeout
	game_controller.emit_signal("turn_action_completed")

# ======== SETUP MENU ========

var setup_panel: PanelContainer
var added_players: Array = []

var avatars = [
	preload("res://resources/ui/avatars/avatar_boy.jpg"),
	preload("res://resources/ui/avatars/avatar_girl.jpg"),
	preload("res://resources/ui/avatars/avatar_cat.jpg"),
	preload("res://resources/ui/avatars/avatar_robot.jpg")
]
var current_avatar_idx = 0
var avatar_display: TextureRect
var name_input: LineEdit
var players_list_vbox: VBoxContainer
var start_game_btn: Button

func show_setup_menu():
	var ui_layer = get_node("UI")
	
	setup_panel = PanelContainer.new()
	setup_panel.name = "SetupPanel"
	setup_panel.position = Vector2(0, 0)
	setup_panel.size = get_viewport().get_visible_rect().size
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.1, 0.95)
	setup_panel.add_theme_stylebox_override("panel", style)
	
	var center = CenterContainer.new()
	setup_panel.add_child(center)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(main_vbox)
	
	var title = Label.new()
	title.text = "THÊM NGƯỜI CHƠI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	main_vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(spacer)
	
	# === ADD PLAYER FORM ===
	var form_bg = PanelContainer.new()
	var fstyle = StyleBoxFlat.new()
	fstyle.bg_color = Color(0.1, 0.15, 0.2)
	fstyle.set_corner_radius_all(15)
	fstyle.set_content_margin_all(15)
	form_bg.add_theme_stylebox_override("panel", fstyle)
	main_vbox.add_child(form_bg)
	
	var form_hbox = HBoxContainer.new()
	form_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	form_bg.add_child(form_hbox)
	
	# Avatar Selector
	var prev_btn = Button.new()
	prev_btn.text = "<"
	prev_btn.custom_minimum_size = Vector2(40, 60)
	prev_btn.pressed.connect(func(): _change_avatar(-1))
	form_hbox.add_child(prev_btn)
	
	avatar_display = TextureRect.new()
	avatar_display.texture = avatars[current_avatar_idx]
	avatar_display.custom_minimum_size = Vector2(80, 80)
	avatar_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	form_hbox.add_child(avatar_display)
	
	var next_btn = Button.new()
	next_btn.text = ">"
	next_btn.custom_minimum_size = Vector2(40, 60)
	next_btn.pressed.connect(func(): _change_avatar(1))
	form_hbox.add_child(next_btn)
	
	var sp1 = Control.new()
	sp1.custom_minimum_size = Vector2(20, 0)
	form_hbox.add_child(sp1)
	
	name_input = LineEdit.new()
	name_input.placeholder_text = "Nhập tên..."
	name_input.custom_minimum_size = Vector2(200, 40)
	form_hbox.add_child(name_input)
	
	var sp2 = Control.new()
	sp2.custom_minimum_size = Vector2(20, 0)
	form_hbox.add_child(sp2)
	
	var add_btn = Button.new()
	add_btn.text = "➕ THÊM"
	add_btn.custom_minimum_size = Vector2(100, 40)
	add_btn.pressed.connect(_on_add_player_pressed)
	form_hbox.add_child(add_btn)
	
	# === PLAYERS LIST ===
	var sp3 = Control.new()
	sp3.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(sp3)
	
	var list_title = Label.new()
	list_title.text = "DANH SÁCH (Ít nhất 2 người):"
	list_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(list_title)
	
	players_list_vbox = VBoxContainer.new()
	players_list_vbox.custom_minimum_size = Vector2(400, 150)
	main_vbox.add_child(players_list_vbox)
	
	# === START BTN ===
	var sp4 = Control.new()
	sp4.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(sp4)
	
	start_game_btn = Button.new()
	start_game_btn.text = "BẮT ĐẦU GAME"
	start_game_btn.custom_minimum_size = Vector2(300, 60)
	start_game_btn.add_theme_font_size_override("font_size", 24)
	start_game_btn.disabled = true
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.6, 0.3)
	btn_style.set_corner_radius_all(10)
	start_game_btn.add_theme_stylebox_override("normal", btn_style)
	start_game_btn.pressed.connect(_on_start_game_pressed)
	main_vbox.add_child(start_game_btn)
	
	ui_layer.add_child(setup_panel)

func _change_avatar(dir: int):
	current_avatar_idx += dir
	if current_avatar_idx < 0:
		current_avatar_idx = avatars.size() - 1
	elif current_avatar_idx >= avatars.size():
		current_avatar_idx = 0
	avatar_display.texture = avatars[current_avatar_idx]

func _on_add_player_pressed():
	if added_players.size() >= 4:
		show_message("Tối đa 4 người chơi!")
		return
	var pname = name_input.text.strip_edges()
	if pname == "":
		pname = "Player " + str(added_players.size() + 1)
		
	var pdata = {
		"name": pname,
		"avatar_id": current_avatar_idx
	}
	added_players.append(pdata)
	
	name_input.text = ""
	_change_avatar(1)
	_update_players_list_ui()

func _update_players_list_ui():
	for c in players_list_vbox.get_children():
		c.queue_free()
		
	for i in range(added_players.size()):
		var p = added_players[i]
		var hb = HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var tex = TextureRect.new()
		tex.texture = avatars[p["avatar_id"]]
		tex.custom_minimum_size = Vector2(40, 40)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hb.add_child(tex)
		
		var lbl = Label.new()
		lbl.text = "  " + p["name"]
		lbl.custom_minimum_size = Vector2(150, 40)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(lbl)
		
		var rm_btn = Button.new()
		rm_btn.text = "X"
		rm_btn.add_theme_color_override("font_color", Color.RED)
		rm_btn.pressed.connect(self._remove_player.bind(i))
		hb.add_child(rm_btn)
		
		players_list_vbox.add_child(hb)
		
	start_game_btn.disabled = (added_players.size() < 2)

func _remove_player(idx: int):
	added_players.remove_at(idx)
	_update_players_list_ui()

func _on_start_game_pressed():
	var current_id = 0
	for p in added_players:
		game_controller.game_state.add_player(current_id, p["name"], p["avatar_id"])
		current_id += 1
		
	setup_panel.queue_free()
	update_player_info(game_controller.game_state.players)
	emit_signal("setup_finished")
