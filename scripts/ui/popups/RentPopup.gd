extends Control
class_name RentPopup

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")
const UIFactory = preload("res://scripts/ui/UIFactory.gd")

signal rent_confirmed
signal view_assets_requested

var title_label: Label
var subtitle_label: Label
var land_value: Label
var owner_value: Label
var rent_value: Label
var flow_payer: Control
var flow_amount: Label
var flow_owner: Control
var left_money: Label
var right_money: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()
	UIFactory.make_responsive(self)

func _build() -> void:
	add_child(UIFactory.dim_overlay())

	# Outer panel (warm cream)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("FFF8EC")
	panel_style.border_color = Color("F0A030")
	panel_style.set_border_width_all(5)
	panel_style.set_corner_radius_all(22)
	panel_style.set_content_margin_all(20)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 20
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(310, 110)
	panel.size = Vector2(660, 510)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	# Header row with title + stars + close
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(header)

	var star_l := UIFactory.label("★", 26, CoTyPhuTheme.GOLD)
	var star_r := UIFactory.label("★", 26, CoTyPhuTheme.GOLD)
	title_label = UIFactory.label("Trả tiền thuê", 38, CoTyPhuTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.add_theme_color_override("font_outline_color", Color(0.4, 0.2, 0.0, 0.55))
	title_label.add_theme_constant_override("outline_size", 5)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(star_l)
	header.add_child(title_label)
	header.add_child(star_r)
	var close_btn := _close_button()
	close_btn.pressed.connect(func(): emit_signal("rent_confirmed"); visible = false)
	header.add_child(close_btn)

	# Subtitle
	subtitle_label = UIFactory.label("Bạn đã dừng chân tại đất của người chơi khác!", 20, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(subtitle_label)

	# Details card
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color.WHITE
	detail_style.border_color = Color("E8D8A8")
	detail_style.set_border_width_all(2)
	detail_style.set_corner_radius_all(14)
	detail_style.set_content_margin_all(16)
	detail_style.shadow_color = Color(0, 0, 0, 0.1)
	detail_style.shadow_size = 4
	var detail_card := PanelContainer.new()
	detail_card.add_theme_stylebox_override("panel", detail_style)
	root.add_child(detail_card)

	var detail_grid := VBoxContainer.new()
	detail_grid.add_theme_constant_override("separation", 8)
	detail_card.add_child(detail_grid)

	# Land row
	var land_row := HBoxContainer.new()
	land_row.add_theme_constant_override("separation", 10)
	detail_grid.add_child(land_row)
	land_row.add_child(UIFactory.icon("home", CoTyPhuTheme.GREEN, Vector2(30, 30)))
	land_row.add_child(UIFactory.label("Đất:", 20, CoTyPhuTheme.TEXT_DARK))
	var land_sp := Control.new(); land_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	land_row.add_child(land_sp)
	land_value = UIFactory.label("", 22, CoTyPhuTheme.TEXT_GREEN, HORIZONTAL_ALIGNMENT_RIGHT)
	land_row.add_child(land_value)

	# Owner row
	var owner_row := HBoxContainer.new()
	owner_row.add_theme_constant_override("separation", 10)
	detail_grid.add_child(owner_row)
	owner_row.add_child(UIFactory.icon("token", CoTyPhuTheme.RED, Vector2(30, 30)))
	owner_row.add_child(UIFactory.label("Chủ sở hữu:", 20, CoTyPhuTheme.TEXT_DARK))
	var own_sp := Control.new(); own_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner_row.add_child(own_sp)
	owner_value = UIFactory.label("", 22, CoTyPhuTheme.RED, HORIZONTAL_ALIGNMENT_RIGHT)
	owner_row.add_child(owner_value)

	# Rent row
	var rent_row := HBoxContainer.new()
	rent_row.add_theme_constant_override("separation", 10)
	detail_grid.add_child(rent_row)
	rent_row.add_child(UIFactory.icon("money", CoTyPhuTheme.GREEN, Vector2(30, 30)))
	rent_row.add_child(UIFactory.label("Tiền thuê:", 20, CoTyPhuTheme.TEXT_DARK))
	var rent_sp := Control.new(); rent_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rent_row.add_child(rent_sp)
	rent_value = UIFactory.label("", 22, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_RIGHT)
	rent_row.add_child(rent_value)

	# Money flow visualization
	var flow_style := StyleBoxFlat.new()
	flow_style.bg_color = Color("F8F0E0")
	flow_style.border_color = Color("D8C890")
	flow_style.set_border_width_all(2)
	flow_style.set_corner_radius_all(14)
	flow_style.set_content_margin_all(16)
	var flow_panel := PanelContainer.new()
	flow_panel.add_theme_stylebox_override("panel", flow_style)
	root.add_child(flow_panel)

	var flow_row := HBoxContainer.new()
	flow_row.add_theme_constant_override("separation", 0)
	flow_row.alignment = BoxContainer.ALIGNMENT_CENTER
	flow_panel.add_child(flow_row)

	# Payer token
	var payer_col := VBoxContainer.new()
	payer_col.alignment = BoxContainer.ALIGNMENT_CENTER
	payer_col.add_theme_constant_override("separation", 4)
	flow_row.add_child(payer_col)
	flow_payer = UIFactory.icon("token", CoTyPhuTheme.BLUE, Vector2(52, 60))
	payer_col.add_child(flow_payer)
	var payer_badge_style := StyleBoxFlat.new()
	payer_badge_style.bg_color = CoTyPhuTheme.BLUE
	payer_badge_style.set_border_width_all(0)
	payer_badge_style.set_corner_radius_all(8)
	payer_badge_style.set_content_margin_all(4)
	var payer_badge := PanelContainer.new()
	payer_badge.add_theme_stylebox_override("panel", payer_badge_style)
	var payer_lbl := UIFactory.label("Bạn", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	payer_lbl.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	payer_lbl.add_theme_constant_override("outline_size", 0)
	payer_badge.add_child(payer_lbl)
	payer_col.add_child(payer_badge)

	# Arrow + amount
	var mid_col := VBoxContainer.new()
	mid_col.alignment = BoxContainer.ALIGNMENT_CENTER
	mid_col.add_theme_constant_override("separation", 2)
	mid_col.custom_minimum_size = Vector2(180, 0)
	flow_row.add_child(mid_col)
	var arrow_l := UIFactory.label("→", 36, CoTyPhuTheme.ORANGE, HORIZONTAL_ALIGNMENT_CENTER)
	mid_col.add_child(arrow_l)
	var money_icon := UIFactory.icon("money", CoTyPhuTheme.GREEN, Vector2(56, 42))
	money_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mid_col.add_child(money_icon)
	flow_amount = UIFactory.label("$0", 30, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	flow_amount.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.25))
	flow_amount.add_theme_constant_override("outline_size", 3)
	mid_col.add_child(flow_amount)
	var arrow_r := UIFactory.label("→", 36, CoTyPhuTheme.ORANGE, HORIZONTAL_ALIGNMENT_CENTER)
	mid_col.add_child(arrow_r)

	# Owner token
	var owner_col := VBoxContainer.new()
	owner_col.alignment = BoxContainer.ALIGNMENT_CENTER
	owner_col.add_theme_constant_override("separation", 4)
	flow_row.add_child(owner_col)
	flow_owner = UIFactory.icon("token", CoTyPhuTheme.RED, Vector2(52, 60))
	owner_col.add_child(flow_owner)
	var owner_badge_style := StyleBoxFlat.new()
	owner_badge_style.bg_color = CoTyPhuTheme.RED
	owner_badge_style.set_border_width_all(0)
	owner_badge_style.set_corner_radius_all(8)
	owner_badge_style.set_content_margin_all(4)
	var owner_badge_cont := PanelContainer.new()
	owner_badge_cont.add_theme_stylebox_override("panel", owner_badge_style)
	var owner_badge_lbl := UIFactory.label("Người chơi", 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	owner_badge_lbl.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	owner_badge_lbl.add_theme_constant_override("outline_size", 0)
	owner_badge_cont.add_child(owner_badge_lbl)
	owner_col.add_child(owner_badge_cont)

	# Buttons
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	root.add_child(buttons)

	var pay := _styled_button("💵  Trả tiền", CoTyPhuTheme.GREEN, Vector2(260, 68))
	var assets := _styled_button("📁  Xem tài sản", CoTyPhuTheme.BLUE, Vector2(240, 68))
	buttons.add_child(pay)
	buttons.add_child(assets)
	pay.pressed.connect(func(): visible = false; emit_signal("rent_confirmed"))
	assets.pressed.connect(func(): emit_signal("view_assets_requested"))

	# Floating money labels with sparkles
	left_money = _float_money_label("-$0", CoTyPhuTheme.RED)
	left_money.position = Vector2(116, 332)
	add_child(left_money)
	right_money = _float_money_label("+$0", Color("55E842"))
	right_money.position = Vector2(986, 332)
	add_child(right_money)

	_add_sparkles_to(left_money)
	_add_sparkles_to(right_money)

func show_rent(payer: Player, owner: Player, cell: Cell, amount: int) -> void:
	visible = true
	var owner_name := owner.name if owner else "Ngân hàng"
	land_value.text = cell.cell_name
	owner_value.text = owner_name
	rent_value.text = "$" + str(amount)
	flow_amount.text = "$" + str(amount)
	left_money.text = "-$" + str(amount)
	right_money.text = "+$" + str(amount)
	_animate_money()

func _float_money_label(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 44)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	lbl.add_theme_constant_override("outline_size", 5)
	return lbl

func _add_sparkles_to(parent: Label) -> void:
	# 4 small white sparkle stars around the floating amount
	for offset in [Vector2(-26, -8), Vector2(110, -10), Vector2(-18, 36), Vector2(118, 36)]:
		var spark := Label.new()
		spark.text = "✦"
		spark.add_theme_font_size_override("font_size", 22)
		spark.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		spark.add_theme_color_override("font_outline_color", Color(1, 0.85, 0.2, 0.7))
		spark.add_theme_constant_override("outline_size", 3)
		spark.position = offset
		parent.add_child(spark)

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

func _styled_button(text: String, color: Color, min_size: Vector2) -> Button:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.35)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(8)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", CoTyPhuTheme.button(color.lightened(0.12), 18))
	btn.add_theme_stylebox_override("pressed", CoTyPhuTheme.button(color.darkened(0.2), 18))
	btn.mouse_entered.connect(func(): btn.scale = Vector2(1.04, 1.04))
	btn.mouse_exited.connect(func(): btn.scale = Vector2.ONE)
	return btn

func _animate_money() -> void:
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.22)
	
	# Wait for popup to settle
	tween.tween_interval(0.2)
	
	# Reset money labels
	left_money.position = Vector2(116, 332)
	right_money.position = Vector2(986, 332)
	left_money.modulate.a = 1.0
	right_money.modulate.a = 1.0
	left_money.scale = Vector2(0.6, 0.6)
	right_money.scale = Vector2(0.6, 0.6)
	left_money.show()
	right_money.show()
	
	# Pop in
	tween.parallel().tween_property(left_money, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(right_money, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE)
	
	# Wait a bit, then float up and fade
	tween.tween_interval(0.5)
	tween.parallel().tween_property(left_money, "position:y", 232, 1.0).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(right_money, "position:y", 232, 1.0).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(left_money, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(right_money, "modulate:a", 0.0, 1.0)
