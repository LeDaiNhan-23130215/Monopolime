extends Control
class_name BuildPopup

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")
const UIFactory = preload("res://scripts/ui/UIFactory.gd")

signal upgrade_selected(cell: Cell)
signal closed

var cash_label: Label
var rows: VBoxContainer
var _player: Player

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()
	UIFactory.make_responsive(self)

func _build() -> void:
	add_child(UIFactory.dim_overlay())

	# Main panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("FFF8EC")
	panel_style.border_color = Color("57C6FF")
	panel_style.set_border_width_all(5)
	panel_style.set_corner_radius_all(22)
	panel_style.set_content_margin_all(20)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 20
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(170, 70)
	panel.size = Vector2(940, 560)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	# Header bar
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color("0759A8")
	header_style.border_color = Color("2EC4FF")
	header_style.set_border_width_all(0)
	header_style.set_corner_radius_all(14)
	header_style.set_content_margin_all(12)
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", header_style)
	root.add_child(header_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header_panel.add_child(header)

	var house_icon := UIFactory.icon("home", CoTyPhuTheme.GOLD, Vector2(52, 46))
	header.add_child(house_icon)

	var title := UIFactory.label("Xây nhà / Nâng cấp", 34, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_outline_color", Color(0, 0.1, 0.4, 0.6))
	title.add_theme_constant_override("outline_size", 5)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	# Cash display
	var cash_row := HBoxContainer.new()
	cash_row.add_theme_constant_override("separation", 6)
	cash_row.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(cash_row)
	cash_row.add_child(UIFactory.icon("money", CoTyPhuTheme.GREEN, Vector2(28, 28)))
	cash_label = UIFactory.label("$0", 22, CoTyPhuTheme.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	cash_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	cash_label.add_theme_constant_override("outline_size", 3)
	cash_label.custom_minimum_size = Vector2(130, 40)
	cash_row.add_child(cash_label)

	var close := _close_button()
	close.pressed.connect(func(): visible = false; emit_signal("closed"))
	header.add_child(close)

	# Column headers
	var col_headers := HBoxContainer.new()
	col_headers.add_theme_constant_override("separation", 6)
	root.add_child(col_headers)
	var header_spacer := Control.new()
	header_spacer.custom_minimum_size = Vector2(10, 0)
	col_headers.add_child(header_spacer)
	for item in [["", 58], ["Tên tài sản", 170], ["Hiện tại", 95], ["Tiền thuê", 95], ["Chi phí nâng cấp", 130], ["Cấp công trình", 335], ["", 130]]:
		var lbl := UIFactory.label(item[0], 15, Color("8B4513"), HORIZONTAL_ALIGNMENT_CENTER)
		lbl.custom_minimum_size = Vector2(item[1], 28)
		col_headers.add_child(lbl)

	# Scroll for rows
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)

	# Note
	var note_style := StyleBoxFlat.new()
	note_style.bg_color = Color("FFF0D0")
	note_style.border_color = Color("D4B870")
	note_style.set_border_width_all(1)
	note_style.set_corner_radius_all(8)
	note_style.set_content_margin_all(8)
	var note_panel := PanelContainer.new()
	note_panel.add_theme_stylebox_override("panel", note_style)
	root.add_child(note_panel)
	var note_row := HBoxContainer.new()
	note_row.add_theme_constant_override("separation", 6)
	note_row.alignment = BoxContainer.ALIGNMENT_CENTER
	note_panel.add_child(note_row)
	var info_icon := UIFactory.label("ⓘ", 18, CoTyPhuTheme.BLUE)
	info_icon.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	info_icon.add_theme_constant_override("outline_size", 0)
	note_row.add_child(info_icon)
	var note := UIFactory.label("Nâng cấp để tăng tiền thuê khi người chơi khác dừng chân tại ô của bạn.", 16, Color("6E6250"), HORIZONTAL_ALIGNMENT_CENTER)
	note.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	note.add_theme_constant_override("outline_size", 0)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note_row.add_child(note)

func show_build_options(player: Player, properties: Array = []) -> void:
	_player = player
	visible = true
	cash_label.text = "$" + str(player.state.balance)
	for child in rows.get_children():
		child.queue_free()
	var source := properties if not properties.is_empty() else player.properties
	var added := 0
	for cell: Cell in source:
		if cell.cell_type == "property":
			rows.add_child(_row(cell))
			added += 1
	if added == 0:
		rows.add_child(UIFactory.label("Bạn chưa có bất động sản để nâng cấp.", 22, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	_animate_open()

func _row(cell: Cell) -> Control:
	var group_color := CoTyPhuTheme.group_color(cell.color_group)
	var can_build := cell.can_build_house()

	# Outer row container
	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	outer.custom_minimum_size = Vector2(0, 88)

	# Colored left accent strip
	var strip_style := StyleBoxFlat.new()
	strip_style.bg_color = group_color
	strip_style.set_border_width_all(0)
	strip_style.set_corner_radius_all(10)
	strip_style.corner_radius_top_right = 0
	strip_style.corner_radius_bottom_right = 0
	var strip := PanelContainer.new()
	strip.custom_minimum_size = Vector2(10, 0)
	strip.add_theme_stylebox_override("panel", strip_style)
	outer.add_child(strip)

	# Inner card
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color.WHITE if can_build else Color("FFF5F5")
	card_style.border_color = group_color
	card_style.set_border_width_all(2)
	card_style.border_width_left = 0
	card_style.set_corner_radius_all(10)
	card_style.corner_radius_top_left = 0
	card_style.corner_radius_bottom_left = 0
	card_style.set_content_margin_all(8)
	card_style.shadow_color = Color(0, 0, 0, 0.1)
	card_style.shadow_size = 3
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", card_style)
	outer.add_child(card)

	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(inner)

	# Property icon
	var prop_icon_type := _icon_for_group(cell.color_group)
	var prop_icon := UIFactory.icon(prop_icon_type, group_color, Vector2(52, 52))
	inner.add_child(prop_icon)

	# Name
	var name_lbl := UIFactory.label(cell.cell_name, 20, group_color)
	name_lbl.custom_minimum_size = Vector2(175, 50)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inner.add_child(name_lbl)

	# Current level badge
	var level_badge := _level_badge("Cấp " + str(cell.house_count), CoTyPhuTheme.BLUE)
	level_badge.custom_minimum_size = Vector2(90, 50)
	inner.add_child(level_badge)

	# Rent
	var rent_lbl := UIFactory.label(UIFactory.format_money(cell.get_current_rent(7)), 20, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	rent_lbl.custom_minimum_size = Vector2(92, 50)
	inner.add_child(rent_lbl)

	# Upgrade cost
	var cost_color := CoTyPhuTheme.TEXT_GREEN if can_build else CoTyPhuTheme.RED
	var cost_lbl := UIFactory.label(UIFactory.format_money(cell.house_cost), 20, cost_color, HORIZONTAL_ALIGNMENT_CENTER)
	cost_lbl.custom_minimum_size = Vector2(124, 50)
	inner.add_child(cost_lbl)

	# Progress
	var progress_bar := _build_progress(cell.house_count)
	progress_bar.custom_minimum_size = Vector2(330, 60)
	inner.add_child(progress_bar)

	# Upgrade button + reason
	var btn_col := VBoxContainer.new()
	btn_col.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_col.custom_minimum_size = Vector2(120, 0)
	inner.add_child(btn_col)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = CoTyPhuTheme.GREEN if can_build else Color("8A8A8A")
	btn_style.border_color = (CoTyPhuTheme.GREEN.lightened(0.35)) if can_build else Color("AAAAAA")
	btn_style.set_border_width_all(3)
	btn_style.set_corner_radius_all(16)
	btn_style.set_content_margin_all(8)
	btn_style.shadow_color = Color(0, 0, 0, 0.3)
	btn_style.shadow_size = 5
	btn_style.shadow_offset = Vector2(0, 3)

	var btn := Button.new()
	btn.text = "Nâng cấp"
	btn.custom_minimum_size = Vector2(114, 50)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.disabled = not can_build
	btn.pressed.connect(func(c := cell): emit_signal("upgrade_selected", c))
	btn_col.add_child(btn)

	if not can_build:
		var reason := UIFactory.label(cell.get_build_block_reason(), 13, CoTyPhuTheme.RED, HORIZONTAL_ALIGNMENT_CENTER)
		reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reason.custom_minimum_size = Vector2(114, 0)
		btn_col.add_child(reason)

	return outer

func _build_progress(level: int) -> Control:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	container.alignment = BoxContainer.ALIGNMENT_CENTER

	var stages := [
		["home", "Nhà 1"],
		["home", "Nhà 2"],
		["home", "Nhà 3"],
		["home", "Nhà 4"],
		["pagoda", "Khách sạn"],
	]

	for i in range(stages.size()):
		var active := level > i
		var icon_color := CoTyPhuTheme.GREEN if active else Color("C8C8C8")
		# Hotel stage gets red color when active
		if i == 4 and active:
			icon_color = CoTyPhuTheme.RED
		var stage := VBoxContainer.new()
		stage.alignment = BoxContainer.ALIGNMENT_CENTER
		stage.custom_minimum_size = Vector2(54, 56)
		var icon_size := 28 + i * 2
		var house := UIFactory.icon(stages[i][0], icon_color, Vector2(icon_size, icon_size))
		stage.add_child(house)
		var stage_lbl_color := Color("777777")
		if active:
			stage_lbl_color = CoTyPhuTheme.RED if i == 4 else CoTyPhuTheme.TEXT_GREEN
		var stage_lbl := UIFactory.label(stages[i][1], 10, stage_lbl_color, HORIZONTAL_ALIGNMENT_CENTER)
		stage_lbl.add_theme_constant_override("outline_size", 0)
		stage_lbl.custom_minimum_size = Vector2(54, 12)
		stage.add_child(stage_lbl)
		container.add_child(stage)

		if i < stages.size() - 1:
			var arrow := UIFactory.label("→", 14, Color("AAAAAA"), HORIZONTAL_ALIGNMENT_CENTER)
			arrow.custom_minimum_size = Vector2(10, 0)
			arrow.add_theme_constant_override("outline_size", 0)
			container.add_child(arrow)

	return container

func _level_badge(text: String, color: Color) -> Control:
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = color.darkened(0.1)
	badge_style.border_color = color
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(10)
	badge_style.set_content_margin_all(6)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", badge_style)
	var lbl := UIFactory.label(text, 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	lbl.add_theme_constant_override("outline_size", 2)
	badge.add_child(lbl)
	return badge

func _close_button() -> Button:
	var style := StyleBoxFlat.new()
	style.bg_color = CoTyPhuTheme.RED
	style.border_color = CoTyPhuTheme.RED.lightened(0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(4)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	var btn := Button.new()
	btn.text = "✕"
	btn.custom_minimum_size = Vector2(50, 50)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", CoTyPhuTheme.button(CoTyPhuTheme.RED.lightened(0.15), 14))
	btn.add_theme_stylebox_override("pressed", CoTyPhuTheme.button(CoTyPhuTheme.RED.darkened(0.2), 14))
	return btn

func _icon_for_group(group: String) -> String:
	match group:
		"green": return "palm"
		"blue": return "bridge"
		"red": return "pagoda"
		"yellow": return "home"
		"orange": return "city"
		_: return "home"

func _animate_open() -> void:
	modulate.a = 0
	scale = Vector2(0.92, 0.92)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.2)
