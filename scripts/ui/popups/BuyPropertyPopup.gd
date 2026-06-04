extends Control
class_name BuyPropertyPopup

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")
const UIFactory = preload("res://scripts/ui/UIFactory.gd")

signal buy_selected(accepted: bool)

var title_label: Label
var property_art: Control
var name_label: Label
var group_label: Label
var price_label: Label
var rent_label: Label
var color_label: Label
var upgrade_label: Label
var cash_label: Label
var buy_button: Button
var _name_banner: PanelContainer

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
	panel.position = Vector2(260, 90)
	panel.size = Vector2(760, 540)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	# Header
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color("0759A8")
	header_style.set_border_width_all(0)
	header_style.set_corner_radius_all(14)
	header_style.set_content_margin_all(12)
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", header_style)
	root.add_child(header_panel)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 10)
	header_panel.add_child(header)

	title_label = UIFactory.label("★ Mua bất động sản ★", 36, CoTyPhuTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0.1, 0.4, 0.6))
	title_label.add_theme_constant_override("outline_size", 5)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var close_btn := _close_button()
	close_btn.pressed.connect(func(): _emit(false))
	header.add_child(close_btn)

	# Body: property card + info
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	root.add_child(body)

	# Property card (left)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("FFF0D4")
	card_style.border_color = CoTyPhuTheme.GOLD
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(16)
	card_style.set_content_margin_all(12)
	card_style.shadow_color = Color(0, 0, 0, 0.2)
	card_style.shadow_size = 8
	var card := PanelContainer.new()
	card.name = "PropertyCard"
	card.custom_minimum_size = Vector2(228, 310)
	card.add_theme_stylebox_override("panel", card_style)
	body.add_child(card)

	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 10)
	card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(card_box)

	# Name banner in card
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = CoTyPhuTheme.GREEN
	banner_style.border_color = CoTyPhuTheme.GREEN.darkened(0.25)
	banner_style.set_border_width_all(2)
	banner_style.set_corner_radius_all(10)
	banner_style.set_content_margin_all(8)
	_name_banner = PanelContainer.new()
	_name_banner.add_theme_stylebox_override("panel", banner_style)
	card_box.add_child(_name_banner)
	name_label = UIFactory.label("Nha Trang", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	name_label.add_theme_constant_override("outline_size", 3)
	_name_banner.add_child(name_label)

	# Property illustration
	property_art = UIFactory.icon("home", CoTyPhuTheme.GREEN, Vector2(190, 158))
	card_box.add_child(property_art)

	# Color group section
	card_box.add_child(UIFactory.label("Nhóm màu", 18, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	group_label = UIFactory.label("Xanh lá", 26, CoTyPhuTheme.TEXT_GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	group_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.2))
	group_label.add_theme_constant_override("outline_size", 3)
	card_box.add_child(group_label)

	# Info section (right)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(info)

	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color.WHITE
	info_style.border_color = Color("E8D8A8")
	info_style.set_border_width_all(2)
	info_style.set_corner_radius_all(12)
	info_style.set_content_margin_all(14)
	var info_card := PanelContainer.new()
	info_card.add_theme_stylebox_override("panel", info_style)
	info_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(info_card)

	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 8)
	info_card.add_child(info_box)

	price_label = _info_row(info_box, "🏷", "Giá mua", "$300", CoTyPhuTheme.TEXT_GREEN)
	rent_label = _info_row(info_box, "🏠", "Tiền thuê cơ bản", "$50", CoTyPhuTheme.TEXT_DARK)
	color_label = _info_row(info_box, "🎨", "Nhóm màu", "Xanh lá", CoTyPhuTheme.TEXT_GREEN)
	upgrade_label = _info_row(info_box, "🔨", "Chi phí nâng cấp", "$150", CoTyPhuTheme.TEXT_DARK)

	var sep := HSeparator.new()
	info_box.add_child(sep)

	var desc := UIFactory.label("Sở hữu tất cả bất động sản trong nhóm màu để tăng tiền thuê và xây nhà!", 19, CoTyPhuTheme.TEXT_DARK)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_box.add_child(desc)

	# Cash row
	var cash_row := HBoxContainer.new()
	cash_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cash_row.add_theme_constant_override("separation", 8)
	root.add_child(cash_row)
	cash_row.add_child(UIFactory.icon("money", CoTyPhuTheme.GREEN, Vector2(28, 28)))
	cash_label = UIFactory.label("Bạn còn $1500", 22, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	cash_row.add_child(cash_label)

	# Buttons
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 40)
	root.add_child(buttons)
	buy_button = _styled_button("🏠  Mua", CoTyPhuTheme.GREEN, Vector2(260, 72))
	var skip := _styled_button("Bỏ qua", CoTyPhuTheme.BLUE, Vector2(220, 72))
	buttons.add_child(buy_button)
	buttons.add_child(skip)
	buy_button.pressed.connect(func(): _emit(true))
	skip.pressed.connect(func(): _emit(false))

func _info_row(parent: VBoxContainer, icon_char: String, label_text: String, value: String, color: Color) -> Label:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 50)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row)

	var icon_lbl := Label.new()
	icon_lbl.text = icon_char
	icon_lbl.add_theme_font_size_override("font_size", 20)
	icon_lbl.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	icon_lbl.add_theme_constant_override("outline_size", 0)
	row.add_child(icon_lbl)

	row.add_child(UIFactory.label(label_text, 20, CoTyPhuTheme.TEXT_DARK))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var value_label := UIFactory.label(value, 26, color, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.2))
	value_label.add_theme_constant_override("outline_size", 2)
	value_label.custom_minimum_size = Vector2(150, 48)
	row.add_child(value_label)
	return value_label

func show_property(cell: Cell, player: Player) -> void:
	visible = true
	var group_color := CoTyPhuTheme.group_color(cell.color_group)
	var group_name := ""
	match cell.color_group:
		"red": group_name = "Đỏ"
		"blue": group_name = "Xanh dương"
		"green": group_name = "Xanh lá"
		"light_blue": group_name = "Xanh nhạt"
		"yellow": group_name = "Vàng"
		"orange": group_name = "Cam"
		"pink": group_name = "Hồng"
		_: group_name = cell.color_group.capitalize() if cell.color_group != "" else "Đặc biệt"

	# Update name banner color
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = group_color
	banner_style.border_color = group_color.darkened(0.25)
	banner_style.set_border_width_all(2)
	banner_style.set_corner_radius_all(10)
	banner_style.set_content_margin_all(8)
	_name_banner.add_theme_stylebox_override("panel", banner_style)

	name_label.text = cell.cell_name
	property_art.call("configure", _icon_kind_for_cell(cell), group_color, "")
	group_label.text = group_name
	group_label.add_theme_color_override("font_color", group_color)
	price_label.text = UIFactory.format_money(cell.get_modified_price())
	rent_label.text = UIFactory.format_money(cell.rent_price)
	color_label.text = group_name
	color_label.add_theme_color_override("font_color", group_color)
	upgrade_label.text = UIFactory.format_money(cell.house_cost)
	cash_label.text = "Bạn còn " + UIFactory.format_money(player.state.balance)
	buy_button.disabled = not FinanceManager.can_afford(player, cell.get_modified_price())
	_animate_open()

func _emit(accepted: bool) -> void:
	visible = false
	emit_signal("buy_selected", accepted)

func _icon_kind_for_cell(cell: Cell) -> String:
	var lower_name := cell.cell_name.to_lower()
	if lower_name.contains("nha trang") or lower_name.contains("phu quoc") or lower_name.contains("vung tau"):
		return "palm"
	if lower_name.contains("ha noi") or lower_name.contains("hue") or lower_name.contains("hoi an"):
		return "pagoda"
	if lower_name.contains("da nang"):
		return "bridge"
	if lower_name.contains("sapa") or lower_name.contains("sa pa"):
		return "home"
	if cell.cell_type == "railroad":
		return "city"
	if cell.cell_type == "utility":
		return "money"
	return "home"

func _close_button() -> Button:
	var style := StyleBoxFlat.new()
	style.bg_color = CoTyPhuTheme.RED
	style.border_color = CoTyPhuTheme.RED.lightened(0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(4)
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
	style.set_corner_radius_all(18)
	style.set_content_margin_all(10)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 26)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", CoTyPhuTheme.button(color.lightened(0.12), 18))
	btn.add_theme_stylebox_override("pressed", CoTyPhuTheme.button(color.darkened(0.2), 18))
	btn.add_theme_stylebox_override("disabled", CoTyPhuTheme.button(Color("777777"), 18))
	btn.mouse_entered.connect(func(): if not btn.disabled: btn.scale = Vector2(1.04, 1.04))
	btn.mouse_exited.connect(func(): btn.scale = Vector2.ONE)
	return btn

func _animate_open() -> void:
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.22)
