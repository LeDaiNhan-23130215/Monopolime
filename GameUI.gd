extends Node
class_name GameUI

signal setup_finished

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
	card_panel.position = Vector2(300, 180)
	card_panel.size = Vector2(480, 180)
	card_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.border_color = Color(1.0, 0.7, 0.2)
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(20)
	card_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"

	var card_title = Label.new()
	card_title.name = "CardTitle"
	card_title.text = "CƠ HỘI"
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.add_theme_font_size_override("font_size", 26)
	card_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(card_title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var card_text = Label.new()
	card_text.name = "CardText"
	card_text.text = ""
	card_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_text.add_theme_font_size_override("font_size", 16)
	card_text.add_theme_color_override("font_color", Color.WHITE)
	card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(card_text)

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


func show_card_popup(title: String, text: String, color: Color):
	if card_panel == null:
		return
	card_panel.visible = true
	card_panel.get_node("VBox/CardTitle").text = title
	card_panel.get_node("VBox/CardTitle").add_theme_color_override("font_color", color)
	card_panel.get_node("VBox/CardText").text = text


func hide_card_popup():
	if card_panel:
		card_panel.visible = false


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
var player_inputs = []

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
	
	var vbox = VBoxContainer.new()
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "THIẾT LẬP NGƯỜI CHƠI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	var avatars = [
		preload("res://resources/ui/avatars/avatar_boy.jpg"),
		preload("res://resources/ui/avatars/avatar_girl.jpg"),
		preload("res://resources/ui/avatars/avatar_cat.jpg"),
		preload("res://resources/ui/avatars/avatar_robot.jpg")
	]
	
	var default_names = ["An", "Bình", "Cường", "Dũng"]
	
	for i in range(4):
		var pbox = VBoxContainer.new()
		
		var active_check = CheckBox.new()
		active_check.text = "Tham gia"
		active_check.button_pressed = (i < 2) # Default 2 players
		pbox.add_child(active_check)
		
		var tex = TextureRect.new()
		tex.texture = avatars[i]
		tex.custom_minimum_size = Vector2(100, 100)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pbox.add_child(tex)
		
		var name_input = LineEdit.new()
		name_input.text = default_names[i]
		name_input.custom_minimum_size = Vector2(120, 30)
		pbox.add_child(name_input)
		
		player_inputs.append({
			"check": active_check,
			"input": name_input,
			"avatar_id": i
		})
		
		hbox.add_child(pbox)
		
		if i < 3:
			var sp = Control.new()
			sp.custom_minimum_size = Vector2(30, 0)
			hbox.add_child(sp)
			
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(spacer2)
	
	var start_btn = Button.new()
	start_btn.text = "BẮT ĐẦU GAME"
	start_btn.custom_minimum_size = Vector2(250, 60)
	start_btn.add_theme_font_size_override("font_size", 24)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.6, 0.3)
	btn_style.set_corner_radius_all(10)
	start_btn.add_theme_stylebox_override("normal", btn_style)
	start_btn.pressed.connect(_on_setup_start_pressed)
	vbox.add_child(start_btn)
	
	ui_layer.add_child(setup_panel)

func _on_setup_start_pressed():
	var active_count = 0
	for p in player_inputs:
		if p["check"].button_pressed:
			active_count += 1
			
	if active_count < 2:
		show_message("Phải có ít nhất 2 người chơi!")
		return
		
	var current_id = 0
	for p in player_inputs:
		if p["check"].button_pressed:
			game_controller.game_state.add_player(current_id, p["input"].text, p["avatar_id"])
			current_id += 1
			
	setup_panel.queue_free()
	update_player_info(game_controller.game_state.players)
	emit_signal("setup_finished")
