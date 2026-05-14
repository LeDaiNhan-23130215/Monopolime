extends Control
class_name MainGameHUD

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")
const UIFactory = preload("res://scripts/ui/UIFactory.gd")

signal roll_pressed
signal assets_pressed
signal build_pressed
signal trade_pressed
signal rules_pressed
signal end_turn_pressed

const DESIGN_SIZE := Vector2(1280, 720)

var turn_label: Label
var current_player_label: Label
var message_label: RichTextLabel
var dice_1: Control
var dice_2: Control
var result_label: Label
var roll_button: Button
var assets_button: Button
var build_button: Button
var trade_button: Button
var end_turn_button: Button
var player_list: VBoxContainer
var history_list: VBoxContainer
var history_scroll: ScrollContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	UIFactory.make_responsive(self, DESIGN_SIZE)

func _build() -> void:
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_theme_constant_override("separation", 0)
	add_child(page)

	# 1. Top Bar (Full width, no margins)
	page.add_child(_build_top_bar())

	# 2. Main Body with margins
	var body := MarginContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("margin_left", 10)
	body.add_theme_constant_override("margin_top", 8)
	body.add_theme_constant_override("margin_right", 10)
	body.add_theme_constant_override("margin_bottom", 8)
	page.add_child(body)

	var vbody := VBoxContainer.new()
	vbody.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbody.add_theme_constant_override("separation", 8)
	body.add_child(vbody)

	vbody.add_child(_build_main_area())
	vbody.add_child(_build_action_bar())

func _build_top_bar() -> Control:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color("#06336F")
	top_style.border_color = Color("#1E88E5")
	top_style.set_border_width_all(0)
	top_style.border_width_bottom = 4
	top_style.set_corner_radius_all(0)
	top_style.corner_radius_bottom_left = 24
	top_style.corner_radius_bottom_right = 24
	top_style.shadow_color = Color(0, 0, 0, 0.4)
	top_style.shadow_size = 8
	top_style.shadow_offset = Vector2(0, 4)
	
	var top := PanelContainer.new()
	top.name = "TopBar"
	top.custom_minimum_size = Vector2(0, 76)
	top.add_theme_stylebox_override("panel", top_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	top.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(row)

	# Logo area
	var logo_icon := UIFactory.icon("city", CoTyPhuTheme.GOLD, Vector2(56, 56))
	row.add_child(logo_icon)
	var logo := UIFactory.label("Cờ Tỷ Phú", 36, CoTyPhuTheme.GOLD)
	logo.add_theme_color_override("font_outline_color", Color("#06336F"))
	logo.add_theme_constant_override("outline_size", 6)
	logo.custom_minimum_size = Vector2(190, 44)
	row.add_child(logo)

	var spacer_left := Control.new()
	spacer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer_left)

	# Turn counter
	var turn_panel := _mini_pill_panel()
	row.add_child(turn_panel)
	var turn_row := HBoxContainer.new()
	turn_row.add_theme_constant_override("separation", 8)
	turn_panel.add_child(turn_row)
	var cal_icon := UIFactory.icon("hourglass", Color("#FFCA28"), Vector2(28, 28))
	turn_row.add_child(cal_icon)
	turn_label = UIFactory.label("Lượt 1", 22, Color("#FFCA28"), HORIZONTAL_ALIGNMENT_CENTER)
	turn_label.custom_minimum_size = Vector2(90, 36)
	turn_row.add_child(turn_label)

	# Current player
	var player_turn_panel := _mini_pill_panel()
	row.add_child(player_turn_panel)
	var pt_row := HBoxContainer.new()
	pt_row.add_theme_constant_override("separation", 10)
	player_turn_panel.add_child(pt_row)
	var avatar_icon := UIFactory.icon("token", Color("2D8CFF"), Vector2(30, 30))
	pt_row.add_child(avatar_icon)
	current_player_label = UIFactory.label("Đến lượt: Người chơi 1", 22, Color("#FFCA28"), HORIZONTAL_ALIGNMENT_LEFT)
	current_player_label.custom_minimum_size = Vector2(240, 36)
	pt_row.add_child(current_player_label)

	var spacer_right := Control.new()
	spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer_right)

	var rules_btn := _icon_button("?")
	rules_btn.tooltip_text = "Luật chơi"
	var settings := _icon_button("⚙")
	rules_btn.pressed.connect(func(): emit_signal("rules_pressed"))
	row.add_child(rules_btn)
	row.add_child(settings)
	
	return top

func _mini_pill_panel() -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#03204C")
	style.border_color = Color("#115BA3")
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(8)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style)
	return p

func _icon_button(text: String) -> Button:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0A4E99")
	style.border_color = Color("#2994FF")
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(48, 48)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	return btn

func _build_main_area() -> Control:
	var main := HBoxContainer.new()
	main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 10)

	# LEFT PANEL
	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.custom_minimum_size = Vector2(190, 0)
	left.add_theme_constant_override("separation", 10)
	main.add_child(left)

	# Notification panel
	var alert_style := StyleBoxFlat.new()
	alert_style.bg_color = Color("#FCEBAE")
	alert_style.border_color = Color("#F3C94E")
	alert_style.set_border_width_all(3)
	alert_style.set_corner_radius_all(16)
	alert_style.set_content_margin_all(8)
	alert_style.shadow_color = Color(0, 0, 0, 0.2)
	alert_style.shadow_size = 6
	var alert := PanelContainer.new()
	alert.custom_minimum_size = Vector2(0, 62)
	alert.add_theme_stylebox_override("panel", alert_style)
	left.add_child(alert)
	
	var alert_row := HBoxContainer.new()
	alert_row.add_theme_constant_override("separation", 8)
	alert_row.alignment = BoxContainer.ALIGNMENT_CENTER
	alert.add_child(alert_row)
	
	var star := UIFactory.label("⭐", 20, CoTyPhuTheme.GOLD)
	alert_row.add_child(star)
	
	message_label = RichTextLabel.new()
	message_label.bbcode_enabled = true
	message_label.text = "[center]Sẵn sàng [color=#2D8CFF]Bắt đầu[/color]![/center]"
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.fit_content = true
	message_label.add_theme_font_size_override("normal_font_size", 14)
	message_label.add_theme_color_override("default_color", Color("#4A3000"))
	alert_row.add_child(message_label)
	
	var mega := UIFactory.label("📢", 22, Color.WHITE)
	mega.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	mega.add_theme_constant_override("outline_size", 2)
	alert_row.add_child(mega)
	left.add_child(_build_dice_panel())
	left.add_child(_build_history_panel())
	# BOARD SAFE SPACE
	var board_space := Control.new()
	board_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(board_space)

	# RIGHT PANEL (Player Roster)
	var right_scroll := ScrollContainer.new()
	right_scroll.custom_minimum_size = Vector2(220, 0)
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(right_scroll)

	player_list = VBoxContainer.new()
	player_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_list.add_theme_constant_override("separation", 8)
	right_scroll.add_child(player_list)
	
	return main

func _build_dice_panel() -> Control:
	var dice_style := StyleBoxFlat.new()
	dice_style.bg_color = Color("#0D47A1")
	dice_style.border_color = Color("#42A5F5")
	dice_style.set_border_width_all(3)
	dice_style.set_corner_radius_all(20)
	dice_style.set_content_margin_all(10)
	dice_style.shadow_color = Color(0, 0, 0, 0.4)
	dice_style.shadow_size = 8
	var dice_panel := PanelContainer.new()
	dice_panel.name = "DicePanel"
	dice_panel.custom_minimum_size = Vector2(0, 184)
	dice_panel.add_theme_stylebox_override("panel", dice_style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	dice_panel.add_child(box)
	
	var xuc_label := UIFactory.label("XÚC XẮC", 18, Color("#BBDEFB"), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(xuc_label)

	var dice_bg := PanelContainer.new()
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("#082B6B")
	bg_style.set_corner_radius_all(12)
	bg_style.set_content_margin_all(10)
	dice_bg.add_theme_stylebox_override("panel", bg_style)
	box.add_child(dice_bg)

	var dice_row := HBoxContainer.new()
	dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_row.add_theme_constant_override("separation", 16)
	dice_bg.add_child(dice_row)

	dice_1 = _dice_face_panel(4)
	dice_2 = _dice_face_panel(3)
	dice_row.add_child(dice_1)
	dice_row.add_child(dice_2)

	var result_title := UIFactory.label("★ KẾT QUẢ ★", 15, Color("#BBDEFB"), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(result_title)
	result_label = UIFactory.label("7", 36, Color("#FFCA28"), HORIZONTAL_ALIGNMENT_CENTER)
	result_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	result_label.add_theme_constant_override("outline_size", 5)
	box.add_child(result_label)
	return dice_panel

func _build_history_panel() -> Control:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#FFF8EC")
	style.border_color = Color("#57C6FF")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(8)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 5

	var panel := PanelContainer.new()
	panel.name = "TurnHistoryPanel"
	panel.custom_minimum_size = Vector2(0, 220)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	panel.add_child(root)

	var title := UIFactory.label("Lịch sử", 17, Color("#06336F"), HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_outline_color", Color("#FFFDF4"))
	title.add_theme_constant_override("outline_size", 3)
	root.add_child(title)

	history_scroll = ScrollContainer.new()
	history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(history_scroll)

	history_list = VBoxContainer.new()
	history_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_list.add_theme_constant_override("separation", 4)
	history_scroll.add_child(history_list)
	add_history_entry("Bắt đầu ván chơi.")

	return panel

func _build_action_bar() -> Control:
	var shell := MarginContainer.new()
	shell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color("#06336F")
	bar_style.border_color = Color("#1E88E5")
	bar_style.set_border_width_all(3)
	bar_style.set_corner_radius_all(20)
	bar_style.set_content_margin_all(6)
	bar_style.shadow_color = Color(0, 0, 0, 0.4)
	bar_style.shadow_size = 8
	
	var panel := PanelContainer.new()
	panel.name = "ActionBar"
	panel.custom_minimum_size = Vector2(0, 62)
	panel.add_theme_stylebox_override("panel", bar_style)
	shell.add_child(panel)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	roll_button = _action_button("🎲 Tung", Color("#4CAF50"), Vector2(132, 46))
	assets_button = _action_button("📁 Tài sản", Color("#1E88E5"), Vector2(120, 46))
	build_button = _action_button("🏠 Xây", Color("#FFA000"), Vector2(112, 46))
	trade_button = _action_button("🔄 Đổi", Color("#8E24AA"), Vector2(112, 46))
	end_turn_button = _action_button("🚩 Hết lượt", Color("#E53935"), Vector2(132, 46))

	for button in [roll_button, assets_button, build_button, trade_button, end_turn_button]:
		row.add_child(button)

	roll_button.pressed.connect(func(): emit_signal("roll_pressed"))
	assets_button.pressed.connect(func(): emit_signal("assets_pressed"))
	build_button.pressed.connect(func(): emit_signal("build_pressed"))
	trade_button.pressed.connect(func(): emit_signal("trade_pressed"))
	end_turn_button.pressed.connect(func(): emit_signal("end_turn_pressed"))
	return shell

func _action_button(text: String, color: Color, min_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	btn.add_theme_constant_override("outline_size", 3)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.border_color = color.lightened(0.25)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(14)
	normal_style.shadow_color = Color(0, 0, 0, 0.4)
	normal_style.shadow_size = 4
	normal_style.shadow_offset = Vector2(0, 2)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.12)
	
	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	pressed_style.shadow_size = 0
	pressed_style.shadow_offset = Vector2.ZERO

	var disabled_style := StyleBoxFlat.new()
	disabled_style.bg_color = Color("555555")
	disabled_style.border_color = Color("777777")
	disabled_style.set_border_width_all(2)
	disabled_style.set_corner_radius_all(14)

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	btn.mouse_entered.connect(func(): btn.scale = Vector2(1.03, 1.03))
	btn.mouse_exited.connect(func(): btn.scale = Vector2.ONE)
	return btn

func _dice_face_panel(value: int) -> Control:
	var DiceFaceClass = load("res://scripts/ui/DiceFace.gd")
	var dice = DiceFaceClass.new()
	dice.set_value(value)
	return dice

func set_roll_enabled(enabled: bool) -> void:
	if roll_button:
		roll_button.disabled = not enabled

func set_turn(turn_number: int, player_name: String) -> void:
	turn_label.text = "Lượt " + str(turn_number)
	current_player_label.text = "Đến lượt: " + player_name

func set_message(text: String, is_bbcode: bool = false) -> void:
	if is_bbcode:
		message_label.text = text
	else:
		message_label.text = "[center]" + text + "[/center]"
		
	# Animate the text change
	message_label.modulate.a = 0.0
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(message_label, "modulate:a", 1.0, 0.3)



func set_dice(a: int, b: int) -> void:
	dice_1.set_value(a)
	dice_2.set_value(b)
	result_label.text = str(a + b)

func update_players(players: Array, active_index: int, rankings := {}) -> void:
	for child in player_list.get_children():
		child.queue_free()

	for i in range(players.size()):
		var p: Player = players[i]
		var active := i == active_index
		var color_idx := i
		if p and p.has_meta("color_index"):
			color_idx = int(p.get_meta("color_index"))
		var color := CoTyPhuTheme.player_color(color_idx)
		player_list.add_child(_build_player_card(p, i, active, color))

func add_history_entry(text: String, color: Color = Color("#2E2A22")) -> void:
	if history_list == null:
		return
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color("#FFFAF0")
	row_style.border_color = Color("#E8D8A8")
	row_style.set_border_width_all(1)
	row_style.set_corner_radius_all(8)
	row_style.set_content_margin_all(5)
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", row_style)

	var label := Label.new()
	label.text = "• " + text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	history_list.add_child(row)
	while history_list.get_child_count() > 8:
		history_list.get_child(0).queue_free()
	call_deferred("_scroll_history_to_bottom")

func _scroll_history_to_bottom() -> void:
	if history_scroll == null:
		return
	await get_tree().process_frame
	var bar := history_scroll.get_v_scroll_bar()
	if bar:
		history_scroll.scroll_vertical = int(bar.max_value)

func _build_player_card(p: Player, index: int, active: bool, color: Color) -> Control:
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#FFF6E5")
	card_style.border_color = color
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(16)
	card_style.set_content_margin_all(6)
	card_style.shadow_color = Color(0, 0, 0, 0.25)
	card_style.shadow_size = 4
	card_style.shadow_offset = Vector2(0, 2)
	var card := PanelContainer.new()
	card.name = "PlayerCard" + str(index + 1)
	card.custom_minimum_size = Vector2(235, 82)
	card.add_theme_stylebox_override("panel", card_style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)

	# Left colored Pawn icon
	var token_icon := UIFactory.icon("token", color, Vector2(30, 38))
	var icon_box := VBoxContainer.new()
	icon_box.alignment = BoxContainer.ALIGNMENT_CENTER
	icon_box.custom_minimum_size = Vector2(34, 0)
	icon_box.add_child(token_icon)
	row.add_child(icon_box)

	# Info column
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)

	# Title row (Number + Name + Badge)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 4)
	info.add_child(title_row)
	
	var num_panel_style := StyleBoxFlat.new()
	num_panel_style.bg_color = color
	num_panel_style.set_corner_radius_all(14)
	num_panel_style.set_content_margin_all(2)
	num_panel_style.shadow_color = Color(0, 0, 0, 0.25)
	num_panel_style.shadow_size = 2
	var num_panel := PanelContainer.new()
	num_panel.add_theme_stylebox_override("panel", num_panel_style)
	num_panel.custom_minimum_size = Vector2(24, 24)
	var num_lbl := Label.new()
	num_lbl.text = str(index + 1)
	num_lbl.add_theme_font_size_override("font_size", 13)
	num_lbl.add_theme_color_override("font_color", Color.WHITE)
	num_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	num_lbl.add_theme_constant_override("outline_size", 2)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num_panel.add_child(num_lbl)
	title_row.add_child(num_panel)
	
	var name_label := UIFactory.label(p.name, 14, Color("#0D47A1"))
	name_label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	name_label.add_theme_constant_override("outline_size", 0)
	title_row.add_child(name_label)

	if active:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_row.add_child(spacer)
		
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color("#FFCA28")
		badge_style.border_color = Color("#E0A810")
		badge_style.set_border_width_all(1)
		badge_style.set_corner_radius_all(8)
		badge_style.set_content_margin_all(4)
		var badge_panel := PanelContainer.new()
		badge_panel.add_theme_stylebox_override("panel", badge_style)
		var badge := Label.new()
		badge.text = "Đang lượt"
		badge.add_theme_font_size_override("font_size", 10)
		badge.add_theme_color_override("font_color", Color("#3D2A00"))
		badge.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
		badge.add_theme_constant_override("outline_size", 0)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_panel.add_child(badge)
		title_row.add_child(badge_panel)

	var cash := p.state.balance if p.state else 0
	var money_row := HBoxContainer.new()
	money_row.add_theme_constant_override("separation", 6)
	info.add_child(money_row)
	money_row.add_child(UIFactory.icon("money", Color("#4CAF50"), Vector2(15, 15)))
	var money_lbl := UIFactory.label("Tiền: $" + str(cash), 12, Color.BLACK)
	money_row.add_child(money_lbl)

	var asset_row := HBoxContainer.new()
	asset_row.add_theme_constant_override("separation", 6)
	info.add_child(asset_row)
	asset_row.add_child(UIFactory.icon("home", Color("#4CAF50"), Vector2(15, 15)))
	var asset_lbl := UIFactory.label("Tài sản: " + str(p.properties.size()), 12, Color.BLACK)
	asset_row.add_child(asset_lbl)

	var status_text := "Bình thường" if not p.is_bankrupt() else "Phá sản"
	var status_color := Color("#4CAF50") if not p.is_bankrupt() else Color("#E53935")
	var st_lbl := UIFactory.label("TT: " + status_text, 11, status_color)
	info.add_child(st_lbl)

	return card
