extends Control
class_name SetupScreen

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")
const UIFactory = preload("res://scripts/ui/UIFactory.gd")
const SetupBoardPreview = preload("res://scripts/ui/SetupBoardPreview.gd")

signal start_requested(settings: Dictionary)
signal back_requested

const DESIGN_SIZE := Vector2(1280, 720)
const PLAYER_NAMES := ["Người chơi 1", "Máy 2", "Máy 3", "Máy 4"]
const PLAYER_TYPES := ["Người chơi", "Máy", "Máy", "Máy"]
const COLORS := [Color("#2D8CFF"), Color("#E94C3D"), Color("#48B82E"), Color("#F6A623")]
const AVATAR_TEXTURES := [
	preload("res://resources/ui/avatars/avatar_boy.jpg"),
	preload("res://resources/ui/avatars/avatar_girl.jpg"),
	preload("res://resources/ui/avatars/avatar_cat.jpg"),
	preload("res://resources/ui/avatars/avatar_robot.jpg"),
]
const AVATAR_NAMES := ["Bé trai", "Bé gái", "Mèo", "Robot"]

var player_count := 4
var player_rows: Array = []
var player_list: VBoxContainer
var starting_money: SpinBox
var max_turns: SpinBox
var count_buttons := {}
var avatar_overlay: Control = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	UIFactory.make_responsive(self, DESIGN_SIZE)
	_refresh_rows()

func _build() -> void:
	# Beautiful gradient blue background matching image
	var bg := ColorRect.new()
	bg.color = Color("#07408A")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Geometric patterns overlay could be added here
	var pattern := ColorRect.new()
	pattern.color = Color(0, 0, 0, 0.1)
	pattern.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pattern)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 20)
	root.add_theme_constant_override("margin_top", 10)
	root.add_theme_constant_override("margin_right", 20)
	root.add_theme_constant_override("margin_bottom", 16)
	add_child(root)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	root.add_child(page)

	page.add_child(_build_top_bar())
	page.add_child(_build_main_content())
	page.add_child(_build_bottom_buttons())

func _build_top_bar() -> Control:
	var top_bar := Control.new()
	top_bar.custom_minimum_size = Vector2(0, 80)
	
	var help_btn := _top_icon_button("📖", "Hướng dẫn")
	help_btn.position = Vector2(10, 0)
	top_bar.add_child(help_btn)

	var logo_wrap := HBoxContainer.new()
	logo_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_bar.add_child(logo_wrap)
	
	var logo_art := UIFactory.icon("city", CoTyPhuTheme.GOLD, Vector2(80, 80))
	logo_wrap.add_child(logo_art)
	var logo_text := UIFactory.label("Cờ Tỷ Phú", 56, CoTyPhuTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	logo_text.add_theme_color_override("font_outline_color", Color(0.1, 0.2, 0.6, 0.8))
	logo_text.add_theme_constant_override("outline_size", 8)
	logo_wrap.add_child(logo_text)

	var settings_btn := _top_icon_button("⚙", "Cài đặt")
	settings_btn.position = Vector2(1240 - 80, 0) # 1280 - 40 - margin
	top_bar.add_child(settings_btn)

	# Animation
	logo_wrap.scale = Vector2(0.9, 0.9)
	logo_wrap.modulate.a = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(logo_wrap, "scale", Vector2.ONE, 0.4)
	tween.parallel().tween_property(logo_wrap, "modulate:a", 1.0, 0.3)
	return top_bar

func _top_icon_button(icon_text: String, label_text: String) -> Control:
	var btn_col := VBoxContainer.new()
	btn_col.custom_minimum_size = Vector2(80, 80)
	btn_col.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var circle_style := StyleBoxFlat.new()
	circle_style.bg_color = Color("#E6F2FF")
	circle_style.set_corner_radius_all(30)
	circle_style.shadow_color = Color(0, 0, 0, 0.3)
	circle_style.shadow_size = 4
	
	var btn := Button.new()
	btn.text = icon_text
	btn.custom_minimum_size = Vector2(50, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color("#07408A"))
	btn.add_theme_stylebox_override("normal", circle_style)
	btn.add_theme_stylebox_override("hover", circle_style)
	btn.add_theme_stylebox_override("pressed", circle_style)
	btn_col.add_child(btn)
	
	var lbl := UIFactory.label(label_text, 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	btn_col.add_child(lbl)
	return btn_col

func _build_main_content() -> Control:
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 20)
	main.add_child(_build_left_preview_panel())
	main.add_child(_build_right_setup_panel())
	return main

func _build_left_preview_panel() -> Control:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0B63BC")
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(14)
	panel_style.shadow_color = Color(0, 0, 0, 0.3)
	panel_style.shadow_size = 8
	var panel := PanelContainer.new()
	panel.name = "LeftPreviewPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 0.38
	panel.add_theme_stylebox_override("panel", panel_style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var preview: Control = SetupBoardPreview.new()
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(preview)

	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color("#1171D1")
	info_style.set_corner_radius_all(12)
	info_style.set_content_margin_all(10)
	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", info_style)
	box.add_child(info)
	
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_child(info_row)
	info_row.add_child(UIFactory.icon("dice", Color.WHITE, Vector2(50, 50)))
	var copy := UIFactory.label("Mua đất, xây nhà, thu tiền thuê và trở thành tỷ phú! Người chơi cuối cùng còn lại tiền sẽ là người chiến thắng.", 15, Color.WHITE)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(copy)
	return panel

func _build_right_setup_panel() -> Control:
	var root_control := Control.new()
	root_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_control.size_flags_stretch_ratio = 0.62

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#FFF6E5")
	panel_style.border_color = Color("#07408A")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(20)
	panel_style.shadow_color = Color(0, 0, 0, 0.4)
	panel_style.shadow_size = 10
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", panel_style)
	root_control.add_child(panel)

	var v_box := VBoxContainer.new()
	v_box.add_theme_constant_override("separation", 14)
	panel.add_child(v_box)

	# Spacer for ribbon
	var ribbon_spacer := Control.new()
	ribbon_spacer.custom_minimum_size = Vector2(0, 10)
	v_box.add_child(ribbon_spacer)

	v_box.add_child(_build_player_count_selector())
	
	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color("#E5D0B0")
	sep_style.thickness = 2
	sep.add_theme_stylebox_override("separator", sep_style)
	v_box.add_child(sep)

	v_box.add_child(_build_player_table_header())

	player_list = VBoxContainer.new()
	player_list.add_theme_constant_override("separation", 8)
	v_box.add_child(player_list)
	for i in range(4):
		player_rows.append(_make_player_row(i))

	var sep2 := HSeparator.new()
	sep2.add_theme_stylebox_override("separator", sep_style)
	v_box.add_child(sep2)

	v_box.add_child(_build_game_options())

	# Floating Title Ribbon
	var ribbon_style := StyleBoxFlat.new()
	ribbon_style.bg_color = Color("#1171D1")
	ribbon_style.border_color = Color("#5CC2FF")
	ribbon_style.set_border_width_all(2)
	ribbon_style.set_corner_radius_all(12)
	ribbon_style.corner_radius_top_left = 0
	ribbon_style.corner_radius_top_right = 0
	ribbon_style.set_content_margin_all(8)
	var ribbon := PanelContainer.new()
	ribbon.custom_minimum_size = Vector2(320, 46)
	ribbon.add_theme_stylebox_override("panel", ribbon_style)
	
	var ribbon_wrapper := Control.new()
	ribbon_wrapper.set_anchors_preset(Control.PRESET_TOP_WIDE)
	root_control.add_child(ribbon_wrapper)
	
	ribbon.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ribbon.position = Vector2(-160, -2) # Centered horizontally, sticking out of top
	ribbon_wrapper.add_child(ribbon)

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 12)
	ribbon.add_child(title_row)
	var star_l := UIFactory.label("★", 20, CoTyPhuTheme.GOLD)
	var title := UIFactory.label("Thiết lập trò chơi", 22, Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color(0, 0.1, 0.4, 0.5))
	title.add_theme_constant_override("outline_size", 3)
	var star_r := UIFactory.label("★", 20, CoTyPhuTheme.GOLD)
	title_row.add_child(star_l)
	title_row.add_child(title)
	title_row.add_child(star_r)

	return root_control

func _build_player_count_selector() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.custom_minimum_size = Vector2(0, 42)
	row.add_child(UIFactory.label("Số người chơi", 20, CoTyPhuTheme.TEXT_DARK))
	
	var btn_box := HBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 0) # Tab style
	row.add_child(btn_box)

	for count in [2, 3, 4]:
		var is_selected: bool = (count == player_count)
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = CoTyPhuTheme.ORANGE if is_selected else Color.WHITE
		btn_style.border_color = Color("#C0B090")
		btn_style.set_border_width_all(2)
		if count == 2:
			btn_style.corner_radius_top_left = 12
			btn_style.corner_radius_bottom_left = 12
		elif count == 4:
			btn_style.corner_radius_top_right = 12
			btn_style.corner_radius_bottom_right = 12
			btn_style.border_width_left = 0
		else:
			btn_style.border_width_left = 0
		
		var btn := Button.new()
		btn.text = str(count)
		btn.custom_minimum_size = Vector2(64, 40)
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", Color.WHITE if is_selected else CoTyPhuTheme.TEXT_BLUE)
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_stylebox_override("hover", btn_style)
		btn.add_theme_stylebox_override("pressed", btn_style)
		btn.pressed.connect(_set_player_count.bind(count))
		count_buttons[count] = btn
		btn_box.add_child(btn)
	return row

func _build_player_table_header() -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	header.custom_minimum_size = Vector2(0, 20)
	header.add_child(_header_cell("Người chơi", 56))
	header.add_child(_header_cell("Loại", 122))
	header.add_child(_header_cell("Nhân vật", 60))
	header.add_child(_header_cell("Tên người chơi", 175))
	header.add_child(_header_cell("Màu sắc / Quân cờ", 188))
	return header

func _build_game_options() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.custom_minimum_size = Vector2(0, 60)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	row.add_child(_stepper_panel("Tiền khởi điểm", "money", "$", 1500, 500, 5000, 100, true))
	
	var sep := VSeparator.new()
	var sep_style := StyleBoxLine.new(); sep_style.color = Color("#E5D0B0"); sep_style.vertical = true; sep_style.thickness = 2
	sep.add_theme_stylebox_override("separator", sep_style)
	row.add_child(sep)
	
	row.add_child(_stepper_panel("Số lượt tối đa", "hourglass", "", 40, 10, 100, 5, false))
	return row

func _build_bottom_buttons() -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 70)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)

	var start_btn := _action_button("🎲  Bắt đầu", CoTyPhuTheme.GREEN, Vector2(280, 60))
	start_btn.pressed.connect(_on_start)
	row.add_child(start_btn)

	var back_btn := _action_button("↩  Quay lại", CoTyPhuTheme.BLUE, Vector2(220, 60))
	back_btn.pressed.connect(func(): emit_signal("back_requested"))
	row.add_child(back_btn)
	return row

func _action_button(text: String, color: Color, size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = size
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	btn.add_theme_constant_override("outline_size", 3)
	
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(6)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", CoTyPhuTheme.button(color.lightened(0.12), 16))
	btn.add_theme_stylebox_override("pressed", CoTyPhuTheme.button(color.darkened(0.2), 16))
	btn.mouse_entered.connect(func(): btn.scale = Vector2(1.03, 1.03))
	btn.mouse_exited.connect(func(): btn.scale = Vector2.ONE)
	return btn

func _header_cell(text: String, width: int) -> Label:
	var label := UIFactory.label(text, 15, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(width, 20)
	return label

func _make_player_row(index: int) -> Dictionary:
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color("#FAF3E6")
	row_style.border_color = Color("#D8C8B0")
	row_style.set_border_width_all(2)
	row_style.set_corner_radius_all(12)
	row_style.set_content_margin_all(0)
	var row_panel := PanelContainer.new()
	row_panel.name = "PlayerRow" + str(index + 1)
	row_panel.custom_minimum_size = Vector2(0, 56)
	row_panel.add_theme_stylebox_override("panel", row_style)
	player_list.add_child(row_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row_panel.add_child(row)

	var color_index := index
	var avatar_index := index

	# Number Badge
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = COLORS[color_index]
	badge_style.set_border_width_all(0)
	badge_style.set_corner_radius_all(10)
	badge_style.corner_radius_top_right = 0
	badge_style.corner_radius_bottom_right = 0
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(56, 56)
	badge.add_theme_stylebox_override("panel", badge_style)
	row.add_child(badge)
	var num_lbl := UIFactory.label(str(index + 1), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	num_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.25))
	num_lbl.add_theme_constant_override("outline_size", 3)
	badge.add_child(num_lbl)

	# Type Dropdown
	var type_btn := OptionButton.new()
	type_btn.custom_minimum_size = Vector2(122, 38)
	type_btn.add_theme_font_size_override("font_size", 16)
	type_btn.add_theme_color_override("font_color", CoTyPhuTheme.TEXT_BLUE if index == 0 else CoTyPhuTheme.RED)
	type_btn.add_item("👤 Người chơi")
	type_btn.add_item("🤖 Máy")
	type_btn.selected = 0 if PLAYER_TYPES[index] == "Người chơi" else 1
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color.WHITE
	btn_style.border_color = Color("#C0B090")
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(8)
	btn_style.set_content_margin_all(4)
	type_btn.add_theme_stylebox_override("normal", btn_style)
	type_btn.add_theme_stylebox_override("hover", btn_style)
	type_btn.add_theme_stylebox_override("pressed", btn_style)
	var t_col := VBoxContainer.new(); t_col.alignment = BoxContainer.ALIGNMENT_CENTER
	t_col.add_child(type_btn)
	row.add_child(t_col)

	# Avatar / Character picker
	var avatar_picker := _make_avatar_picker(avatar_index)
	var av_col := VBoxContainer.new()
	av_col.alignment = BoxContainer.ALIGNMENT_CENTER
	av_col.custom_minimum_size = Vector2(60, 0)
	var av_btn: Button = avatar_picker["control"]
	av_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	av_col.add_child(av_btn)
	row.add_child(av_col)

	# Name LineEdit
	var name_edit := LineEdit.new()
	name_edit.text = PLAYER_NAMES[index]
	name_edit.placeholder_text = "Nhập tên..."
	name_edit.max_length = 16
	name_edit.custom_minimum_size = Vector2(175, 38)
	name_edit.add_theme_font_size_override("font_size", 17)
	name_edit.add_theme_color_override("font_color", CoTyPhuTheme.TEXT_DARK)
	var edit_style := StyleBoxFlat.new()
	edit_style.bg_color = Color.WHITE
	edit_style.border_color = Color("#C0B090")
	edit_style.set_border_width_all(2)
	edit_style.set_corner_radius_all(8)
	edit_style.set_content_margin_all(6)
	var edit_focus := edit_style.duplicate()
	edit_focus.border_color = CoTyPhuTheme.BLUE
	edit_focus.bg_color = Color("#F4FAFF")
	name_edit.add_theme_stylebox_override("normal", edit_style)
	name_edit.add_theme_stylebox_override("focus", edit_focus)
	var n_col := VBoxContainer.new(); n_col.alignment = BoxContainer.ALIGNMENT_CENTER
	n_col.add_child(name_edit)
	row.add_child(n_col)

	# Color / Token selector — clickable dots + token preview
	var token_data := _make_token_picker(index, color_index)
	row.add_child(token_data["control"])

	var data := {
		"row": row_panel,
		"badge_panel": badge,
		"badge_style": badge_style,
		"type": type_btn,
		"name": name_edit,
		"avatar_index": avatar_index,
		"avatar_picker": avatar_picker,
		"color_index": color_index,
		"token_picker": token_data,
	}

	# Wire interactions
	avatar_picker["pressed"].connect(func(): _open_avatar_chooser(index, data))
	for i in range(token_data["dots"].size()):
		var btn: Button = token_data["dots"][i]
		btn.pressed.connect(_on_color_picked.bind(index, i))

	# Auto-fill default name with avatar name if user hasn't typed yet
	name_edit.text_submitted.connect(func(_t): name_edit.release_focus())

	return data

func _make_avatar_picker(avatar_index: int) -> Dictionary:
	var size := Vector2(48, 48)
	var btn := Button.new()
	btn.custom_minimum_size = size
	btn.flat = true
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color.WHITE
	bg_style.border_color = Color("#C0B090")
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(10)
	var hover_style := bg_style.duplicate()
	hover_style.border_color = CoTyPhuTheme.BLUE
	btn.add_theme_stylebox_override("normal", bg_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.tooltip_text = "Chọn nhân vật"

	var tex := TextureRect.new()
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.offset_left = 4
	tex.offset_top = 4
	tex.offset_right = -4
	tex.offset_bottom = -4
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.texture = AVATAR_TEXTURES[avatar_index]
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tex)

	return {"control": btn, "texture_rect": tex, "pressed": btn.pressed}

func _make_token_picker(row_index: int, color_index: int) -> Dictionary:
	var box := HBoxContainer.new()
	box.custom_minimum_size = Vector2(188, 50)
	box.add_theme_constant_override("separation", 4)
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	# Token preview that mirrors the selected color
	var token_preview := UIFactory.icon("token", COLORS[color_index], Vector2(26, 34))
	box.add_child(token_preview)

	var dots: Array = []
	var dot_panels: Array = []
	for i in range(4):
		var dot_btn := Button.new()
		dot_btn.flat = true
		dot_btn.custom_minimum_size = Vector2(26, 26)
		dot_btn.tooltip_text = "Chọn màu " + ["xanh dương", "đỏ", "xanh lá", "vàng"][i]

		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = COLORS[i]
		dot_style.border_color = COLORS[i].darkened(0.25)
		dot_style.set_border_width_all(2)
		dot_style.set_corner_radius_all(14)
		dot_style.shadow_color = Color(0, 0, 0, 0.25)
		dot_style.shadow_size = 2
		var dot_hover := dot_style.duplicate()
		dot_hover.border_color = Color.WHITE
		dot_hover.set_border_width_all(3)
		dot_btn.add_theme_stylebox_override("normal", dot_style)
		dot_btn.add_theme_stylebox_override("hover", dot_hover)
		dot_btn.add_theme_stylebox_override("pressed", dot_style)
		dot_btn.add_theme_stylebox_override("focus", dot_style)

		var check := Label.new()
		check.text = "✓" if i == color_index else ""
		check.add_theme_font_size_override("font_size", 18)
		check.add_theme_color_override("font_color", Color.WHITE)
		check.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
		check.add_theme_constant_override("outline_size", 2)
		check.set_anchors_preset(Control.PRESET_FULL_RECT)
		check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot_btn.add_child(check)

		dots.append(dot_btn)
		dot_panels.append(check)
		box.add_child(dot_btn)

	return {"control": box, "dots": dots, "checks": dot_panels, "token_preview": token_preview}

func _on_color_picked(row_index: int, new_color_index: int) -> void:
	if row_index < 0 or row_index >= player_rows.size():
		return
	var data: Dictionary = player_rows[row_index]
	data["color_index"] = new_color_index
	# Update checkmarks
	var checks: Array = data["token_picker"]["checks"]
	for i in range(checks.size()):
		var lbl: Label = checks[i]
		lbl.text = "✓" if i == new_color_index else ""
	# Update token preview color by re-creating icon
	var preview: Control = data["token_picker"]["token_preview"]
	if preview and preview.has_method("configure"):
		preview.configure("token", COLORS[new_color_index], "")
	# Update number-badge color
	var badge_style: StyleBoxFlat = data["badge_style"]
	badge_style.bg_color = COLORS[new_color_index]

func _open_avatar_chooser(row_index: int, data: Dictionary) -> void:
	if avatar_overlay and is_instance_valid(avatar_overlay):
		avatar_overlay.queue_free()
	avatar_overlay = _build_avatar_overlay(row_index, data)
	add_child(avatar_overlay)

func _build_avatar_overlay(row_index: int, data: Dictionary) -> Control:
	var dim := UIFactory.dim_overlay()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim_btn := Button.new()
	dim_btn.flat = true
	dim_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_btn.pressed.connect(func():
		if avatar_overlay and is_instance_valid(avatar_overlay):
			avatar_overlay.queue_free()
			avatar_overlay = null
	)
	dim.add_child(dim_btn)

	# Center the modal using a CenterContainer so it works regardless of viewport size
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#FFF8EC")
	panel_style.border_color = CoTyPhuTheme.BLUE
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(20)
	panel_style.set_content_margin_all(20)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 16
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.custom_minimum_size = Vector2(420, 320)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 10)
	col.add_child(title_row)
	title_row.add_child(UIFactory.label("★", 22, CoTyPhuTheme.GOLD))
	title_row.add_child(UIFactory.label("Chọn nhân vật", 26, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	title_row.add_child(UIFactory.label("★", 22, CoTyPhuTheme.GOLD))

	var grid := HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 14)
	col.add_child(grid)

	for i in range(AVATAR_TEXTURES.size()):
		var item := VBoxContainer.new()
		item.alignment = BoxContainer.ALIGNMENT_CENTER
		item.add_theme_constant_override("separation", 4)

		var btn := Button.new()
		btn.flat = true
		btn.custom_minimum_size = Vector2(96, 96)
		var item_style := StyleBoxFlat.new()
		item_style.bg_color = Color.WHITE
		item_style.border_color = Color("#C0B090") if i != data["avatar_index"] else CoTyPhuTheme.GREEN
		item_style.set_border_width_all(3 if i == data["avatar_index"] else 2)
		item_style.set_corner_radius_all(14)
		var item_hover := item_style.duplicate()
		item_hover.border_color = CoTyPhuTheme.BLUE
		item_hover.set_border_width_all(3)
		btn.add_theme_stylebox_override("normal", item_style)
		btn.add_theme_stylebox_override("hover", item_hover)
		btn.add_theme_stylebox_override("pressed", item_hover)
		btn.add_theme_stylebox_override("focus", item_hover)

		var tex := TextureRect.new()
		tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex.offset_left = 6
		tex.offset_top = 6
		tex.offset_right = -6
		tex.offset_bottom = -6
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.texture = AVATAR_TEXTURES[i]
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex)

		btn.pressed.connect(_on_avatar_picked.bind(row_index, i))
		item.add_child(btn)
		item.add_child(UIFactory.label(AVATAR_NAMES[i], 14, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
		grid.add_child(item)

	# Close button
	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(close_row)

	var close_btn := Button.new()
	close_btn.text = "Đóng"
	close_btn.custom_minimum_size = Vector2(140, 40)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = CoTyPhuTheme.BLUE
	close_style.set_corner_radius_all(12)
	close_style.set_content_margin_all(6)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_style)
	close_btn.add_theme_stylebox_override("pressed", close_style)
	close_btn.pressed.connect(func():
		if avatar_overlay and is_instance_valid(avatar_overlay):
			avatar_overlay.queue_free()
			avatar_overlay = null
	)
	close_row.add_child(close_btn)

	return dim

func _on_avatar_picked(row_index: int, avatar_index: int) -> void:
	if row_index < 0 or row_index >= player_rows.size():
		return
	var data: Dictionary = player_rows[row_index]
	data["avatar_index"] = avatar_index
	var tex_rect: TextureRect = data["avatar_picker"]["texture_rect"]
	tex_rect.texture = AVATAR_TEXTURES[avatar_index]
	# If user hasn't customized name (still default), suggest avatar name
	var current_name: String = data["name"].text.strip_edges()
	if current_name == PLAYER_NAMES[row_index]:
		# leave as-is — user may want their player number
		pass
	if avatar_overlay and is_instance_valid(avatar_overlay):
		avatar_overlay.queue_free()
		avatar_overlay = null

func _stepper_panel(label_text: String, icon_kind: String, prefix: String, value: int, min_value: int, max_value: int, step: int, is_money: bool) -> Control:
	var panel := HBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 12)

	panel.add_child(UIFactory.icon(icon_kind, CoTyPhuTheme.GREEN if is_money else CoTyPhuTheme.ORANGE, Vector2(36, 36)))

	var text_box := VBoxContainer.new()
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 4)
	panel.add_child(text_box)
	
	var lbl := UIFactory.label(label_text, 16, CoTyPhuTheme.TEXT_DARK)
	text_box.add_child(lbl)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 6)
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_child(controls)
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = CoTyPhuTheme.GREEN
	btn_style.set_border_width_all(0)
	btn_style.set_corner_radius_all(6)
	var minus := Button.new(); minus.text = "-"; minus.custom_minimum_size = Vector2(30, 30)
	minus.add_theme_stylebox_override("normal", btn_style); minus.add_theme_font_size_override("font_size", 20)
	
	var value_box := SpinBox.new()
	value_box.min_value = min_value
	value_box.max_value = max_value
	value_box.step = step
	value_box.value = value
	value_box.prefix = prefix
	value_box.custom_minimum_size = Vector2(100, 30)
	value_box.add_theme_font_size_override("font_size", 18)
	value_box.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var plus := Button.new(); plus.text = "+"; plus.custom_minimum_size = Vector2(30, 30)
	plus.add_theme_stylebox_override("normal", btn_style); plus.add_theme_font_size_override("font_size", 20)
	
	minus.pressed.connect(func(): value_box.value = max(value_box.min_value, value_box.value - value_box.step))
	plus.pressed.connect(func(): value_box.value = min(value_box.max_value, value_box.value + value_box.step))
	controls.add_child(minus)
	controls.add_child(value_box)
	controls.add_child(plus)

	if is_money:
		starting_money = value_box
	else:
		max_turns = value_box
	return panel

func _set_player_count(count: int) -> void:
	player_count = count
	for key in count_buttons.keys():
		var btn: Button = count_buttons[key]
		var is_selected: bool = (key == count)
		var btn_style := btn.get_theme_stylebox("normal").duplicate()
		btn_style.bg_color = CoTyPhuTheme.ORANGE if is_selected else Color.WHITE
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_stylebox_override("hover", btn_style)
		btn.add_theme_stylebox_override("pressed", btn_style)
		btn.add_theme_color_override("font_color", Color.WHITE if is_selected else CoTyPhuTheme.TEXT_BLUE)
	_refresh_rows()

func _refresh_rows() -> void:
	for i in range(player_rows.size()):
		player_rows[i]["row"].visible = i < player_count

func _on_start() -> void:
	var players := []
	for i in range(player_count):
		var data: Dictionary = player_rows[i]
		players.append({
			"name": data["name"].text.strip_edges(),
			"is_ai": data["type"].selected == 1,
			"color_index": int(data.get("color_index", i)),
			"avatar_id": int(data.get("avatar_index", i)),
		})
	emit_signal("start_requested", {
		"players": players,
		"starting_money": int(starting_money.value),
		"max_turns": int(max_turns.value),
		"victory_mode": "turn_limit",
	})
