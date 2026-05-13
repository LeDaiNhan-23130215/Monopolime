extends Node
class_name GameUI

signal setup_finished
signal card_dismissed
signal teleport_cell_selected(cell_index: int)

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

# Sound placeholder keys. Add real AudioStreamPlayer nodes/assets later.
const SFX_BUY := "sfx_buy"
const SFX_PAY := "sfx_pay"
const SFX_REWARD := "sfx_reward"
const SFX_BUILD := "sfx_build"
const SFX_JAIL := "sfx_jail"
const SFX_CARD := "sfx_card"
const SFX_TELEPORT := "sfx_teleport"
const SFX_GAME_OVER := "sfx_game_over"

# Dynamic UI nodes
var player_info_panel: PanelContainer
var player_info_label: RichTextLabel
var message_label: Label
var buy_panel: PanelContainer
var build_panel: PanelContainer
var card_panel: PanelContainer
var game_over_panel: PanelContainer
var property_manager_panel: PanelContainer
var property_manager_list: VBoxContainer
var open_assets_button: Button
var teleport_panel: PanelContainer
var teleport_list: VBoxContainer
var _property_manager_player: Player = null
var property_filter_option: OptionButton
var property_sort_option: OptionButton

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
	_create_property_manager_panel()
	_create_teleport_panel()

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

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(player_info_label)

	open_assets_button = Button.new()
	open_assets_button.text = "TAI SAN"
	open_assets_button.custom_minimum_size = Vector2(0, 34)
	open_assets_button.pressed.connect(_on_open_assets_pressed)
	vbox.add_child(open_assets_button)

	player_info_panel.add_child(vbox)
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
	build_panel.size = Vector2(460, 220)
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
	restart_btn.pressed.connect(func():
		if game_controller:
			game_controller.restart_game()
		else:
			get_tree().reload_current_scene()
	)
	vbox.add_child(restart_btn)

	game_over_panel.add_child(vbox)
	ui_layer.add_child(game_over_panel)


# ======== PROPERTY MANAGER ========

func _create_property_manager_panel():
	var ui_layer = get_node("UI")
	property_manager_panel = PanelContainer.new()
	property_manager_panel.name = "PropertyManagerPanel"
	property_manager_panel.position = Vector2(120, 90)
	property_manager_panel.size = Vector2(760, 430)
	property_manager_panel.visible = false
	property_manager_panel.z_index = 120

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.12, 0.98)
	style.border_color = Color(0.25, 0.75, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(14)
	property_manager_panel.add_theme_stylebox_override("panel", style)

	var root = VBoxContainer.new()
	root.name = "Root"
	root.add_theme_constant_override("separation", 8)

	var header = HBoxContainer.new()
	header.name = "Header"
	var title = Label.new()
	title.name = "Title"
	title.text = "Quan ly tai san"
	title.custom_minimum_size = Vector2(560, 28)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(44, 32)
	close_btn.pressed.connect(func(): property_manager_panel.visible = false)
	header.add_child(close_btn)
	root.add_child(header)

	var summary = Label.new()
	summary.name = "Summary"
	summary.add_theme_font_size_override("font_size", 13)
	summary.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	root.add_child(summary)

	var controls = HBoxContainer.new()
	controls.name = "Controls"
	controls.add_theme_constant_override("separation", 8)

	var filter_label = Label.new()
	filter_label.text = "Loc:"
	filter_label.custom_minimum_size = Vector2(34, 30)
	controls.add_child(filter_label)

	property_filter_option = OptionButton.new()
	property_filter_option.custom_minimum_size = Vector2(130, 30)
	property_filter_option.add_item("Tat ca", 0)
	property_filter_option.add_item("Co the xay", 1)
	property_filter_option.add_item("Da the chap", 2)
	property_filter_option.add_item("Du bo mau", 3)
	property_filter_option.item_selected.connect(func(_idx): _refresh_property_rows(_property_manager_player))
	controls.add_child(property_filter_option)

	var sort_label = Label.new()
	sort_label.text = "Sap xep:"
	sort_label.custom_minimum_size = Vector2(62, 30)
	controls.add_child(sort_label)

	property_sort_option = OptionButton.new()
	property_sort_option.custom_minimum_size = Vector2(150, 30)
	property_sort_option.add_item("Thu tu ban co", 0)
	property_sort_option.add_item("Thue cao", 1)
	property_sort_option.add_item("Gia tri cao", 2)
	property_sort_option.add_item("The chap truoc", 3)
	property_sort_option.item_selected.connect(func(_idx): _refresh_property_rows(_property_manager_player))
	controls.add_child(property_sort_option)

	root.add_child(controls)

	var header_row = Label.new()
	header_row.text = "Tai san | Loai | Gia | Thue | Cap | Trang thai | Hanh dong"
	header_row.add_theme_font_size_override("font_size", 12)
	header_row.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	root.add_child(header_row)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(720, 300)
	property_manager_list = VBoxContainer.new()
	property_manager_list.add_theme_constant_override("separation", 5)
	scroll.add_child(property_manager_list)
	root.add_child(scroll)

	property_manager_panel.add_child(root)
	ui_layer.add_child(property_manager_panel)


func _create_teleport_panel():
	var ui_layer = get_node("UI")
	teleport_panel = PanelContainer.new()
	teleport_panel.name = "TeleportPanel"
	teleport_panel.position = Vector2(160, 70)
	teleport_panel.size = Vector2(720, 470)
	teleport_panel.visible = false
	teleport_panel.z_index = 130

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.08, 0.14, 0.98)
	style.border_color = Color(0.35, 0.85, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(16)
	teleport_panel.add_theme_stylebox_override("panel", style)

	var root = VBoxContainer.new()
	root.name = "Root"
	root.add_theme_constant_override("separation", 8)

	var title = Label.new()
	title.name = "Title"
	title.text = "Chon diem du lich"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.45, 0.9, 1.0))
	root.add_child(title)

	var hint = Label.new()
	hint.text = "Chon mot o bat ky tren ban co de dich chuyen den."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	root.add_child(hint)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(660, 360)
	teleport_list = VBoxContainer.new()
	teleport_list.add_theme_constant_override("separation", 4)
	scroll.add_child(teleport_list)
	root.add_child(scroll)

	teleport_panel.add_child(root)
	ui_layer.add_child(teleport_panel)

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
			if game_controller:
				bb += (
					"      Rank #" + str(game_controller.get_player_rank(p))
					+ "  Cash $" + str(p.state.balance)
					+ "  Land " + str(p.properties.size())
					+ "\n      House " + str(game_controller.count_player_houses(p))
					+ "  Hotel " + str(game_controller.count_player_hotels(p))
					+ "  Mortgage " + str(game_controller.count_player_mortgaged_properties(p))
					+ "  Net $" + str(game_controller.calculate_net_worth(p))
					+ "\n"
				)
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


func _on_open_assets_pressed():
	if game_controller:
		show_property_manager(game_controller.get_current_player())


func show_property_manager(player: Player):
	if property_manager_panel == null or player == null:
		return

	_property_manager_player = player
	property_manager_panel.visible = true
	property_manager_panel.get_node("Root/Header/Title").text = "Quan ly tai san - " + player.name
	property_manager_panel.get_node("Root/Summary").text = (
		"Tien mat: $" + str(player.state.balance)
		+ " | Tai san: " + str(player.properties.size())
		+ " | The ra tu: " + str(player.state.special_cards)
	)
	_refresh_property_rows(player)


func _refresh_property_rows(player: Player):
	if player == null:
		return
	for child in property_manager_list.get_children():
		property_manager_list.remove_child(child)
		child.queue_free()

	var properties = _get_filtered_sorted_properties(player)
	if properties.is_empty():
		var empty = Label.new()
		empty.text = "Khong co tai san phu hop."
		empty.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
		property_manager_list.add_child(empty)
		return

	for cell in properties:
		property_manager_list.add_child(_create_property_row(player, cell))


func _get_filtered_sorted_properties(player: Player) -> Array:
	var result = []
	var filter_id = property_filter_option.selected if property_filter_option else 0
	for cell in player.properties:
		var keep = true
		match filter_id:
			1:
				keep = cell.can_build_house()
			2:
				keep = cell.is_mortgaged
			3:
				keep = cell.cell_type == "property" and cell.get_build_block_reason() != "Chua so huu du bo mau."
		if keep:
			result.append(cell)

	var sort_id = property_sort_option.selected if property_sort_option else 0
	match sort_id:
		0:
			result.sort_custom(func(a, b): return a.index < b.index)
		1:
			result.sort_custom(func(a, b): return a.get_current_rent(7) > b.get_current_rent(7))
		2:
			result.sort_custom(func(a, b): return a.get_modified_price() > b.get_modified_price())
		3:
			result.sort_custom(func(a, b): return (1 if a.is_mortgaged else 0) > (1 if b.is_mortgaged else 0))
	return result


func _create_property_row(player: Player, cell: Cell) -> Control:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(700, 44)
	row.add_theme_constant_override("separation", 6)

	var info = Label.new()
	info.custom_minimum_size = Vector2(355, 40)
	info.add_theme_font_size_override("font_size", 11)
	info.text = (
		cell.cell_name
		+ " | " + cell.cell_type
		+ " | Gia $" + str(cell.get_modified_price())
		+ " | Thue $" + str(cell.get_current_rent(7))
		+ " | " + cell.get_build_level_name()
		+ " | " + ("The chap" if cell.is_mortgaged else "Dang mo")
		+ " | Bao ve: " + ("Co" if cell.has_protection_tower else "Khong")
	)
	if not cell.can_build_house():
		var reason = cell.get_build_block_reason()
		if reason != "":
			info.text += "\nKhong xay: " + reason
	row.add_child(info)

	var build_btn = Button.new()
	build_btn.text = "Xay"
	build_btn.custom_minimum_size = Vector2(58, 32)
	build_btn.disabled = not cell.can_build_house()
	build_btn.pressed.connect(func(): _on_property_action_pressed("build", cell))
	row.add_child(build_btn)

	var sell_btn = Button.new()
	sell_btn.text = "Ban nha"
	sell_btn.custom_minimum_size = Vector2(78, 32)
	sell_btn.disabled = cell.house_count <= 0
	sell_btn.pressed.connect(func(): _on_property_action_pressed("sell", cell))
	row.add_child(sell_btn)

	var mortgage_btn = Button.new()
	mortgage_btn.text = "The chap"
	mortgage_btn.custom_minimum_size = Vector2(82, 32)
	mortgage_btn.disabled = cell.is_mortgaged or not cell.can_mortgage()
	mortgage_btn.pressed.connect(func(): _on_property_action_pressed("mortgage", cell))
	row.add_child(mortgage_btn)

	var unmortgage_btn = Button.new()
	unmortgage_btn.text = "Giai chap"
	unmortgage_btn.custom_minimum_size = Vector2(86, 32)
	unmortgage_btn.disabled = not cell.is_mortgaged
	unmortgage_btn.pressed.connect(func(): _on_property_action_pressed("unmortgage", cell))
	row.add_child(unmortgage_btn)

	var protect_btn = Button.new()
	protect_btn.text = "Bao ve"
	protect_btn.custom_minimum_size = Vector2(72, 32)
	protect_btn.disabled = not cell.can_build_protection_tower(player)
	protect_btn.pressed.connect(func(): _on_property_action_pressed("protect", cell))
	row.add_child(protect_btn)

	return row


func _on_property_action_pressed(action: String, cell: Cell):
	if game_controller == null or _property_manager_player == null:
		return

	match action:
		"build":
			game_controller.build_on_property(_property_manager_player, cell)
		"sell":
			game_controller.sell_house_on_property(_property_manager_player, cell)
		"mortgage":
			game_controller.mortgage_property(_property_manager_player, cell)
		"unmortgage":
			game_controller.unmortgage_property(_property_manager_player, cell)
		"protect":
			game_controller.build_protection_tower_for_current_player(cell)

	show_property_manager(_property_manager_player)


func show_teleport_chooser(player: Player, board: Board):
	if teleport_panel == null or board == null:
		return

	teleport_panel.visible = true
	teleport_panel.get_node("Root/Title").text = player.name + " chon diem du lich"

	for child in teleport_list.get_children():
		teleport_list.remove_child(child)
		child.queue_free()

	for i in range(board.cells.size()):
		var cell = board.get_cell(i)
		if cell == null:
			continue
		teleport_list.add_child(_create_teleport_row(i, cell))


func _create_teleport_row(index: int, cell: Cell) -> Control:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(640, 36)
	row.add_theme_constant_override("separation", 8)

	var owner_name = "Chua co chu"
	if cell.cell_owner:
		owner_name = cell.cell_owner.name

	var info = Label.new()
	info.custom_minimum_size = Vector2(500, 32)
	info.add_theme_font_size_override("font_size", 12)
	info.text = (
		"%02d" % index
		+ " | " + cell.cell_name
		+ " | " + cell.cell_type
		+ " | Gia $" + str(cell.get_modified_price())
		+ " | Thue $" + str(cell.get_current_rent(7))
		+ " | " + owner_name
	)
	row.add_child(info)

	var choose_btn = Button.new()
	choose_btn.text = "Den"
	choose_btn.custom_minimum_size = Vector2(70, 30)
	choose_btn.pressed.connect(func(): _on_teleport_selected(index))
	row.add_child(choose_btn)

	return row


func _on_teleport_selected(index: int):
	teleport_panel.visible = false
	emit_signal("teleport_cell_selected", index)


func show_turn(player_index):
	var pname = ""
	if game_controller and player_index < game_controller.game_state.players.size():
		pname = game_controller.game_state.players[player_index].name
	else:
		pname = "Player " + str(player_index + 1)
	call_deferred("_update_turn_label_ascii", pname)
	label.text = "Lượt: " + pname


func _update_turn_label_ascii(pname: String):
	var turn_text = ""
	if game_controller:
		turn_text = " | Turn " + str(game_controller.game_state.turn_number)
	label.text = "Luot: " + pname + turn_text


func show_message(text: String):
	if message_label:
		message_label.text = text
	print("[UI] ", text)


func play_sfx(kind: String):
	# Placeholder routing for future sound assets.
	# Current project only ships dice roll audio, so this intentionally no-ops.
	print("[SFX placeholder] ", kind)


func show_toast_and_wait(title: String, text: String, color: Color, amount: int = 0, duration: float = 0.9):
	show_card_popup(title, text, color, amount)
	await get_tree().create_timer(duration).timeout
	if card_panel and card_panel.visible:
		card_panel.visible = false


func show_transaction_popup(from_player: Player, to_player: Player, amount: int, reason: String):
	var text = ""
	if to_player:
		text = from_player.name + " tra $" + str(amount) + " cho " + to_player.name + "\n" + reason
	else:
		text = from_player.name + " tra $" + str(amount) + "\n" + reason

	show_message(text)
	await show_toast_and_wait("Tien thue", text, Color(1.0, 0.72, 0.22), -amount, 1.0)


func show_buy_prompt(player: Player, cell: Cell):
	if buy_panel == null:
		return
	set_roll_enabled(false)
	buy_panel.visible = true
	buy_panel.get_node("VBox/BuyTitle").text = "🏠 Mua " + cell.cell_name + "?"
	buy_panel.get_node("VBox/BuyInfo").text = "Giá: $" + str(cell.price) + "  |  Thuê: $" + str(cell.rent_price) + "\nSố dư: $" + str(player.state.balance)

	buy_panel.get_node("VBox/BuyTitle").text = "Mua " + cell.cell_name + "?"
	buy_panel.get_node("VBox/BuyInfo").text = "Gia: $" + str(cell.get_modified_price()) + "  |  Thue: $" + str(cell.get_current_rent(7)) + "\nSo du: $" + str(player.state.balance)

var _current_build_cell: Cell = null

func show_build_prompt(player: Player, cell: Cell):
	if build_panel == null:
		return
	_current_build_cell = cell
	set_roll_enabled(false)
	build_panel.visible = true
	var next_level = min(cell.house_count + 1, 5)
	var type_name = "Khach san" if next_level == 5 else "Nha cap " + str(next_level)
	var current_rent = cell.get_current_rent(7)
	var next_rent = cell.get_rent_preview_for_level(next_level, 7)
	build_panel.get_node("VBox/BuildTitle").text = "Xay " + type_name + "?"
	build_panel.get_node("VBox/BuildInfo").text = (
		cell.cell_name
		+ "\nHien tai: " + cell.get_build_level_name()
		+ " | Tiep theo: " + type_name
		+ "\nThue: $" + str(current_rent) + " -> $" + str(next_rent)
		+ "\nChi phi: $" + str(cell.house_cost) + " | So du: $" + str(player.state.balance)
	)


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


func show_game_over_with_rankings(winner: Player, rankings: Array):
	if game_over_panel == null:
		return
	set_roll_enabled(false)
	game_over_panel.visible = true
	var winner_name = winner.name if winner else "Khong co"
	game_over_panel.get_node("VBox/WinnerLabel").text = winner_name + " CHIEN THANG!"

	var details = "Hang | Nguoi choi | Tien | Dat | Tong tai san\n"
	var rank = 1
	for row in rankings:
		var p = row["player"]
		details += (
			str(rank)
			+ ". " + p.name
			+ " | $" + str(row["cash"])
			+ " | " + str(row["properties"])
			+ " | $" + str(row["net_worth"])
			+ "\n"
		)
		rank += 1
	game_over_panel.get_node("VBox/DetailsLabel").text = details


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
		_current_build_cell.play_upgrade_effect()
		var level_name = _current_build_cell.get_build_level_name()
		show_message("Nang cap thanh cong: " + _current_build_cell.cell_name + " -> " + level_name)
		await show_toast_and_wait(
			"Nang cap thanh cong",
			_current_build_cell.cell_name + " da len " + level_name,
			Color(0.35, 1.0, 0.55),
			0,
			0.9
		)
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
var victory_mode_option: OptionButton
var max_turns_input: SpinBox

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

	var mode_box = HBoxContainer.new()
	mode_box.alignment = BoxContainer.ALIGNMENT_CENTER

	var mode_label = Label.new()
	mode_label.text = "Che do thang:"
	mode_label.custom_minimum_size = Vector2(110, 32)
	mode_box.add_child(mode_label)

	victory_mode_option = OptionButton.new()
	victory_mode_option.custom_minimum_size = Vector2(170, 32)
	victory_mode_option.add_item("Pha san", 0)
	victory_mode_option.add_item("Gioi han luot", 1)
	victory_mode_option.item_selected.connect(_on_victory_mode_selected)
	mode_box.add_child(victory_mode_option)

	var turns_label = Label.new()
	turns_label.text = "So luot:"
	turns_label.custom_minimum_size = Vector2(70, 32)
	mode_box.add_child(turns_label)

	max_turns_input = SpinBox.new()
	max_turns_input.min_value = 5
	max_turns_input.max_value = 200
	max_turns_input.step = 1
	max_turns_input.value = 30
	max_turns_input.custom_minimum_size = Vector2(90, 32)
	max_turns_input.editable = false
	mode_box.add_child(max_turns_input)

	main_vbox.add_child(mode_box)
	
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


func _on_victory_mode_selected(index: int):
	if max_turns_input:
		max_turns_input.editable = index == 1

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
	if victory_mode_option and victory_mode_option.selected == 1:
		game_controller.game_state.victory_mode = "turn_limit"
		game_controller.game_state.max_turns = int(max_turns_input.value)
	else:
		game_controller.game_state.victory_mode = "bankruptcy"
		game_controller.game_state.max_turns = 0

	var current_id = 0
	for p in added_players:
		game_controller.game_state.add_player(current_id, p["name"], p["avatar_id"])
		current_id += 1
		
	setup_panel.queue_free()
	update_player_info(game_controller.game_state.players)
	emit_signal("setup_finished")
