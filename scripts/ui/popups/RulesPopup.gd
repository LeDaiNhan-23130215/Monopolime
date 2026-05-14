extends Control
class_name RulesPopup

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")
const UIFactory = preload("res://scripts/ui/UIFactory.gd")

signal closed

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()
	UIFactory.make_responsive(self)

func _build() -> void:
	add_child(UIFactory.dim_overlay())

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
	panel.position = Vector2(260, 92)
	panel.size = Vector2(760, 520)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color("0759A8")
	header_style.set_corner_radius_all(14)
	header_style.set_content_margin_all(12)
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", header_style)
	root.add_child(header_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header_panel.add_child(header)
	header.add_child(UIFactory.icon("dice", CoTyPhuTheme.GOLD, Vector2(52, 48)))

	var title := UIFactory.label("Hướng dẫn luật chơi", 34, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_outline_color", Color(0, 0.1, 0.4, 0.6))
	title.add_theme_constant_override("outline_size", 5)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close := _close_button()
	close.pressed.connect(func(): visible = false; emit_signal("closed"))
	header.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 330)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var rule_list := VBoxContainer.new()
	rule_list.add_theme_constant_override("separation", 8)
	rule_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rule_list)

	for rule in [
		["1", "Đổ xúc xắc", "Đi theo tổng điểm xúc xắc và xử lý ô vừa dừng lại."],
		["2", "Mua tài sản", "Ô đất chưa có chủ có thể mua nếu bạn đủ tiền."],
		["3", "Trả tiền thuê", "Dừng trên tài sản của người khác thì phải trả thuê theo cấp công trình."],
		["4", "Nâng cấp nhà", "Sở hữu đủ nhóm màu để nâng cấp từ cấp 1 đến cấp 4. Cấp 4 là công trình lớn nhất."],
		["5", "Thế chấp", "Khi thiếu tiền, có thể thế chấp tài sản để nhận tiền tạm thời."],
		["6", "Phá sản", "Không thể trả nợ sau khi xử lý tài sản thì người chơi bị loại."],
		["7", "Mục tiêu", "Trở thành người còn lại cuối cùng hoặc có tổng tài sản cao nhất."]
	]:
		rule_list.add_child(_rule_row(rule[0], rule[1], rule[2]))

	var close_bottom := _styled_button("Đã hiểu", CoTyPhuTheme.BLUE, Vector2(220, 58))
	close_bottom.pressed.connect(func(): visible = false; emit_signal("closed"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	row.add_child(close_bottom)

func show_rules() -> void:
	visible = true
	modulate.a = 0
	scale = Vector2(0.92, 0.92)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.2)

func _rule_row(number: String, heading: String, description: String) -> Control:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("FFFAF0")
	style.border_color = Color("E8D8A8")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = CoTyPhuTheme.BLUE
	badge_style.set_corner_radius_all(10)
	badge_style.set_content_margin_all(6)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(38, 38)
	badge.add_theme_stylebox_override("panel", badge_style)
	badge.add_child(UIFactory.label(number, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	row.add_child(badge)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	text_box.add_child(UIFactory.label(heading, 19, CoTyPhuTheme.TEXT_DARK))
	var desc := UIFactory.label(description, 15, Color("#4E4638"))
	desc.add_theme_constant_override("outline_size", 0)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(desc)
	return panel

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
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_stylebox_override("normal", CoTyPhuTheme.button(color, 16))
	btn.add_theme_stylebox_override("hover", CoTyPhuTheme.button(color.lightened(0.12), 16))
	btn.add_theme_stylebox_override("pressed", CoTyPhuTheme.button_pressed(color, 16))
	return btn
