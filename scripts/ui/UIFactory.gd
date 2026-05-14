extends RefCounted
class_name UIFactory

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")
const ResponsiveCanvas = preload("res://scripts/ui/ResponsiveCanvas.gd")
const IllustratedIcon = preload("res://scripts/ui/IllustratedIcon.gd")

static func label(text: String, size: int, color: Color = Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	node.add_theme_constant_override("outline_size", 3)
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# removed clip_text to prevent labels from collapsing to 0 width
	return node

static func rich_label(text: String, size: int, color: Color = CoTyPhuTheme.TEXT_DARK) -> RichTextLabel:
	var node := RichTextLabel.new()
	node.bbcode_enabled = true
	node.text = text
	node.fit_content = true
	node.scroll_active = false
	node.add_theme_font_size_override("normal_font_size", size)
	node.add_theme_color_override("default_color", color)
	return node

static func button(text: String, color: Color, min_size := Vector2(160, 54)) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = min_size
	node.add_theme_font_size_override("font_size", 24)
	node.add_theme_color_override("font_color", Color.WHITE)
	node.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	node.add_theme_constant_override("outline_size", 4)
	node.add_theme_stylebox_override("normal", CoTyPhuTheme.button(color))
	node.add_theme_stylebox_override("hover", CoTyPhuTheme.button(color.lightened(0.12)))
	node.add_theme_stylebox_override("pressed", CoTyPhuTheme.button_pressed(color))
	node.add_theme_stylebox_override("disabled", CoTyPhuTheme.button(Color("#888888")))
	node.mouse_entered.connect(func(): node.scale = Vector2(1.03, 1.03))
	node.mouse_exited.connect(func(): node.scale = Vector2.ONE)
	return node

static func panel(name: String, style: StyleBoxFlat) -> PanelContainer:
	var node := PanelContainer.new()
	node.name = name
	node.add_theme_stylebox_override("panel", style)
	return node

static func dim_overlay() -> ColorRect:
	var node := ColorRect.new()
	node.name = "DimOverlay"
	node.color = Color(0, 0, 0, 0.68)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	return node

static func make_responsive(root: Control, base_size := ResponsiveCanvas.DEFAULT_BASE_SIZE) -> Control:
	var existing := []
	for child in root.get_children():
		existing.append(child)
	var canvas: Control = ResponsiveCanvas.new()
	canvas.name = "DesignCanvas"
	canvas.base_size = base_size
	root.add_child(canvas)
	for child in existing:
		root.remove_child(child)
		canvas.add_child(child)
		if child is Control:
			var control := child as Control
			if control.anchor_left == 0.0 and control.anchor_top == 0.0 and control.anchor_right == 1.0 and control.anchor_bottom == 1.0:
				control.offset_left = 0.0
				control.offset_top = 0.0
				control.offset_right = 0.0
				control.offset_bottom = 0.0
	canvas.size = base_size
	canvas.custom_minimum_size = base_size
	return canvas

static func icon(kind: String, color: Color, min_size := Vector2(82, 82), caption := "") -> Control:
	var node: Control = IllustratedIcon.new()
	node.custom_minimum_size = min_size
	node.size = min_size
	node.configure(kind, color, caption)
	return node

static func format_money(amount: int) -> String:
	return "$" + str(amount)

static func property_icon(cell: Cell) -> String:
	if cell == null:
		return "□"
	match cell.cell_type:
		"property":
			match cell.color_group:
				"green":
					return "▲"
				"blue":
					return "▣"
				"red":
					return "▥"
				"light_blue":
					return "♣"
				"pink":
					return "◆"
				"yellow":
					return "★"
				"orange":
					return "●"
			return "⌂"
		"railroad":
			return "▣"
		"utility":
			return "⚙"
		"tax":
			return "$"
		"chance":
			return "?"
		"community":
			return "▣"
		"jail", "go_to_jail":
			return "▦"
	return "⌂"
