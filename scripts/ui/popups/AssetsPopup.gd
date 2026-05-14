extends Control
class_name AssetsPopup

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")
const UIFactory = preload("res://scripts/ui/UIFactory.gd")

signal closed
signal mortgage_requested

var title_label: Label
var asset_view: VBoxContainer
var rows: VBoxContainer
var total_label: Label
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
	panel.position = Vector2(180, 70)
	panel.size = Vector2(920, 590)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	# Header with icon + title + close
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color("0759A8")
	header_style.set_border_width_all(0)
	header_style.set_corner_radius_all(14)
	header_style.set_content_margin_all(12)
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", header_style)
	root.add_child(header_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header_panel.add_child(header)

	var city_icon := UIFactory.icon("city", CoTyPhuTheme.GOLD, Vector2(56, 52))
	header.add_child(city_icon)

	title_label = UIFactory.label("Tài sản của bạn", 36, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0.1, 0.4, 0.6))
	title_label.add_theme_constant_override("outline_size", 5)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var close := _close_button()
	close.pressed.connect(func(): visible = false; emit_signal("closed"))
	header.add_child(close)

	asset_view = VBoxContainer.new()
	asset_view.add_theme_constant_override("separation", 10)
	root.add_child(asset_view)

	# Column headers row
	var col_row := HBoxContainer.new()
	col_row.add_theme_constant_override("separation", 6)
	asset_view.add_child(col_row)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(10, 0)
	col_row.add_child(spacer)
	for item in [["", 62], ["Tên tài sản", 190], ["Nhóm màu", 130], ["Cấp hiện tại", 125], ["Tiền thuê", 120], ["Thế chấp", 145], ["Giá trị ước tính", 150], ["", 38]]:
		var lbl := UIFactory.label(item[0], 16, CoTyPhuTheme.TEXT_BLUE, HORIZONTAL_ALIGNMENT_CENTER)
		lbl.custom_minimum_size = Vector2(item[1], 28)
		col_row.add_child(lbl)

	# Rows in scroll
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 270)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	asset_view.add_child(scroll)

	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)

	# Total row
	var total_style := StyleBoxFlat.new()
	total_style.bg_color = Color("FFF0D0")
	total_style.border_color = Color("D4AA60")
	total_style.set_border_width_all(2)
	total_style.set_corner_radius_all(12)
	total_style.set_content_margin_all(12)
	var summary := PanelContainer.new()
	summary.name = "Summary"
	summary.add_theme_stylebox_override("panel", total_style)
	asset_view.add_child(summary)

	var srow := HBoxContainer.new()
	summary.add_child(srow)
	var total_icon := UIFactory.icon("money", CoTyPhuTheme.GOLD, Vector2(30, 30))
	srow.add_child(total_icon)
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(8, 0)
	srow.add_child(spacer2)
	srow.add_child(UIFactory.label("Tổng giá trị ước tính:", 22, CoTyPhuTheme.TEXT_DARK))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	srow.add_child(sp)
	total_label = UIFactory.label("$0", 34, CoTyPhuTheme.TEXT_GREEN, HORIZONTAL_ALIGNMENT_RIGHT)
	total_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.2))
	total_label.add_theme_constant_override("outline_size", 3)
	total_label.custom_minimum_size = Vector2(190, 48)
	srow.add_child(total_label)

	# Buttons
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 30)
	root.add_child(buttons)

	var close_bottom := _styled_button("Đóng", CoTyPhuTheme.BLUE, Vector2(220, 62))
	var mortgage := _styled_button("🔒  Thế chấp", CoTyPhuTheme.ORANGE, Vector2(240, 62))
	buttons.add_child(close_bottom)
	buttons.add_child(mortgage)
	close_bottom.pressed.connect(func(): visible = false; emit_signal("closed"))
	mortgage.pressed.connect(func(): emit_signal("mortgage_requested"))

func show_assets(player: Player) -> void:
	_player = player
	visible = true
	_show_assets_view()
	for child in rows.get_children():
		child.queue_free()
	var total := 0
	if player.properties.is_empty():
		rows.add_child(UIFactory.label("Chưa có tài sản", 22, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	for cell: Cell in player.properties:
		var estimated := cell.get_modified_price() + cell.house_count * cell.house_cost
		total += estimated
		rows.add_child(_row(cell, estimated))
	total_label.text = UIFactory.format_money(total)
	_animate_open()

func _show_assets_view() -> void:
	asset_view.visible = true
	if _player != null:
		title_label.text = "Tài sản của " + _player.name
	else:
		title_label.text = "Tài sản của bạn"

func _row(cell: Cell, estimated: int) -> Control:
	var group_color := CoTyPhuTheme.group_color(cell.color_group)

	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	outer.custom_minimum_size = Vector2(0, 68)

	# Color strip
	var strip_style := StyleBoxFlat.new()
	strip_style.bg_color = group_color
	strip_style.set_border_width_all(0)
	strip_style.set_corner_radius_all(10)
	strip_style.corner_radius_top_right = 0
	strip_style.corner_radius_bottom_right = 0
	var strip := PanelContainer.new()
	strip.custom_minimum_size = Vector2(8, 0)
	strip.add_theme_stylebox_override("panel", strip_style)
	outer.add_child(strip)

	# Row card
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color("FFFAF0")
	row_style.border_color = Color("E8D8A8")
	row_style.set_border_width_all(1)
	row_style.border_width_left = 0
	row_style.set_corner_radius_all(10)
	row_style.corner_radius_top_left = 0
	row_style.corner_radius_bottom_left = 0
	row_style.set_content_margin_all(8)
	var row_panel := PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.add_theme_stylebox_override("panel", row_style)
	outer.add_child(row_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row_panel.add_child(row)

	# Icon
	var icon_type := _icon_for_group(cell.color_group)
	row.add_child(UIFactory.icon(icon_type, group_color, Vector2(54, 52)))

	# Name
	var name_lbl := UIFactory.label(cell.cell_name, 20, CoTyPhuTheme.TEXT_DARK)
	name_lbl.custom_minimum_size = Vector2(185, 50)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_lbl)

	# Color group badge
	row.add_child(_group_badge(cell.color_group, group_color))

	# Level with home icon
	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 4)
	level_row.alignment = BoxContainer.ALIGNMENT_CENTER
	level_row.custom_minimum_size = Vector2(125, 50)
	row.add_child(level_row)
	level_row.add_child(UIFactory.icon("home", CoTyPhuTheme.GREEN, Vector2(24, 24)))
	level_row.add_child(UIFactory.label(str(cell.house_count), 22, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER))

	# Rent with money icon
	var rent_row := HBoxContainer.new()
	rent_row.add_theme_constant_override("separation", 4)
	rent_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rent_row.custom_minimum_size = Vector2(120, 50)
	row.add_child(rent_row)
	rent_row.add_child(UIFactory.icon("money", CoTyPhuTheme.GREEN, Vector2(22, 22)))
	rent_row.add_child(UIFactory.label(UIFactory.format_money(cell.get_current_rent(7)), 20, CoTyPhuTheme.TEXT_DARK))

	# Mortgage badge
	var is_mortgaged := cell.is_mortgaged
	var mort_badge := _mortgage_badge(is_mortgaged)
	mort_badge.custom_minimum_size.x = 145
	row.add_child(mort_badge)

	# Estimated value
	var val_lbl := UIFactory.label(UIFactory.format_money(estimated), 22, CoTyPhuTheme.TEXT_GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	val_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.2))
	val_lbl.add_theme_constant_override("outline_size", 2)
	val_lbl.custom_minimum_size = Vector2(148, 50)
	row.add_child(val_lbl)

	# Arrow
	var arrow := UIFactory.label("›", 30, CoTyPhuTheme.BLUE, HORIZONTAL_ALIGNMENT_CENTER)
	arrow.custom_minimum_size = Vector2(36, 50)
	row.add_child(arrow)

	return outer

func _group_badge(group_name: String, color: Color) -> Control:
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = color
	badge_style.set_border_width_all(0)
	badge_style.set_corner_radius_all(10)
	badge_style.set_content_margin_all(6)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(128, 42)
	badge.add_theme_stylebox_override("panel", badge_style)
	var display_name := ""
	match group_name:
		"red": display_name = "Đỏ"
		"blue": display_name = "Xanh dương"
		"green": display_name = "Xanh lá"
		"light_blue": display_name = "Xanh nhạt"
		"yellow": display_name = "Vàng"
		"orange": display_name = "Cam"
		"pink": display_name = "Hồng"
		_: display_name = group_name.capitalize()
	var lbl := UIFactory.label(display_name, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	lbl.add_theme_constant_override("outline_size", 2)
	badge.add_child(lbl)
	return badge

func _mortgage_badge(is_mortgaged: bool) -> Control:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("F0F8FF") if not is_mortgaged else Color("FFF0F0")
	style.border_color = Color("88BBDD") if not is_mortgaged else CoTyPhuTheme.RED
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(6)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", style)
	var lbl_text := "Đã thế chấp" if is_mortgaged else "Chưa thế chấp"
	var lbl_color := CoTyPhuTheme.RED if is_mortgaged else CoTyPhuTheme.TEXT_GREEN
	var lbl := UIFactory.label(lbl_text, 16, lbl_color, HORIZONTAL_ALIGNMENT_CENTER)
	badge.add_child(lbl)
	return badge

func _icon_for_group(group: String) -> String:
	match group:
		"green": return "palm"
		"blue": return "bridge"
		"red": return "pagoda"
		"yellow": return "home"
		"orange": return "city"
		_: return "home"

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
	btn.custom_minimum_size = Vector2(52, 52)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", CoTyPhuTheme.button(CoTyPhuTheme.RED.lightened(0.15), 14))
	btn.add_theme_stylebox_override("pressed", CoTyPhuTheme.button(CoTyPhuTheme.RED.darkened(0.2), 14))
	return btn

func _styled_button(text: String, color: Color, min_size: Vector2) -> Button:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.35)
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(8)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", CoTyPhuTheme.button(color.lightened(0.12), 16))
	btn.add_theme_stylebox_override("pressed", CoTyPhuTheme.button(color.darkened(0.2), 16))
	btn.mouse_entered.connect(func(): btn.scale = Vector2(1.04, 1.04))
	btn.mouse_exited.connect(func(): btn.scale = Vector2.ONE)
	return btn

func _animate_open() -> void:
	modulate.a = 0
	scale = Vector2(0.92, 0.92)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.2)
