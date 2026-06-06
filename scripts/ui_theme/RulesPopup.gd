extends Control
class_name RulesPopup

# ════════════════════════════════════════════════════════════════════
# Popup HƯỚNG DẪN luật chơi + thông tin bộ thẻ (Cơ Hội / Khí Vận).
# Thuần giao diện. Dữ liệu thẻ đọc TỪ EventHandler của E (không sửa logic):
# chỉ tạo một instance tạm để đọc mảng thẻ rồi giải phóng.
# ════════════════════════════════════════════════════════════════════

const Palette = preload("res://scripts/ui_theme/CoTyPhuPalette.gd")
const Icon    = preload("res://scripts/ui_theme/IllustratedIcon.gd")

signal closed

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()

func _build() -> void:
	# --- Lớp mờ nền (full rect) ---
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# --- CenterContainer phủ full rect → panel LUÔN tự căn giữa mọi độ phân giải ---
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# --- Panel chính: giới hạn kích thước, tự co theo nội dung ---
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", Palette.panel_style(Color("#FFF8EC"), Color("#57C6FF"), 22, 5))
	panel.custom_minimum_size = Vector2(720, 520)
	center.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	# --- Header ---
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", Palette.panel_style(Palette.BG_BLUE, Palette.BG_BLUE, 14, 0))
	root.add_child(header_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header_panel.add_child(header)

	var dice_icon := Icon.new()
	dice_icon.custom_minimum_size = Vector2(46, 44)
	dice_icon.configure("dice", Palette.GOLD)
	header.add_child(dice_icon)

	var title := _label("Hướng dẫn luật chơi", 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(48, 48)
	Palette.style_button(close_btn, Palette.RED, 22)
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	# --- Vùng cuộn nội dung ---
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 390)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	# --- Danh sách luật ---
	var rules := [
		["1", "Đổ xúc xắc", "Đi theo tổng điểm xúc xắc và xử lý ô vừa dừng lại. Tung đôi (double) được đi thêm lượt."],
		["2", "Mua tài sản", "Ô đất chưa có chủ có thể mua nếu bạn đủ tiền. Nếu từ chối sẽ chuyển sang đấu giá."],
		["3", "Trả tiền thuê", "Dừng trên tài sản của người khác thì phải trả tiền thuê theo cấp công trình."],
		["4", "Xây nhà / Khách sạn", "Sở hữu đủ nhóm màu để xây nhà cấp 1–4, rồi nâng cấp lên khách sạn."],
		["5", "Thế chấp / Chuộc lại", "Khi thiếu tiền có thể thế chấp tài sản nhận 50% giá trị; chuộc lại tốn thêm 10% lãi."],
		["6", "Vào tù", "Tung đôi 3 lần liên tiếp hoặc dừng ô Go To Jail sẽ vào tù. Có thể dùng thẻ Ra Tù Miễn Phí."],
		["7", "Phá sản", "Không thể trả nợ sau khi xử lý hết tài sản thì người chơi bị loại."],
	]
	for r in rules:
		content.add_child(_rule_row(r[0], r[1], r[2]))

	# --- Thông tin bộ thẻ (đọc từ EventHandler của E) ---
	var decks := _read_decks()
	content.add_child(_deck_section("Bộ thẻ Cơ Hội", "Rút khi dừng vào ô Cơ Hội",
		decks["chance"], Palette.BG_BLUE, Palette.GOLD, "dice"))
	content.add_child(_deck_section("Bộ thẻ Khí Vận", "Rút khi dừng vào ô Khí Vận",
		decks["community"], Color("#0B6B38"), Color("#FFD95A"), "gift"))

	# --- Nút đóng dưới cùng ---
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var ok_btn := Button.new()
	ok_btn.text = "Đã hiểu"
	ok_btn.custom_minimum_size = Vector2(200, 52)
	Palette.style_button(ok_btn, Palette.BLUE, 22)
	ok_btn.pressed.connect(_on_close)
	row.add_child(ok_btn)


# Đọc 2 bộ thẻ từ E mà không can thiệp logic: tạo instance tạm rồi giải phóng.
func _read_decks() -> Dictionary:
	var result := {"chance": [], "community": []}
	var eh = EventHandler.new()
	if eh:
		if "chance_cards" in eh:
			result["chance"] = eh.chance_cards.duplicate(true)
		if "community_chest_cards" in eh:
			result["community"] = eh.community_chest_cards.duplicate(true)
		eh.free()
	return result


func show_rules() -> void:
	visible = true
	move_to_front()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)

func _on_close() -> void:
	visible = false
	emit_signal("closed")


# ─── Helpers dựng UI ────────────────────────────────────────────────
func _label(text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("outline_size", 3)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

func _rule_row(number: String, heading: String, description: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.panel_style(Color("#FFFAF0"), Color("#E8D8A8"), 10, 1))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(40, 40)
	badge.add_theme_stylebox_override("panel", Palette.panel_style(Palette.BLUE, Palette.BLUE, 10, 0))
	badge.add_child(_label(number, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	row.add_child(badge)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)
	box.add_child(_label(heading, 19, Palette.TEXT_DARK))
	var desc := _label(description, 15, Color("#4E4638"))
	desc.add_theme_constant_override("outline_size", 0)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc)
	return panel

func _deck_section(title: String, subtitle: String, cards: Array, base_color: Color, accent: Color, icon_kind: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.panel_style(Color("#FFFDF4"), accent, 14, 3))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", Palette.panel_style(base_color, accent, 12, 2))
	box.add_child(head)
	var head_col := VBoxContainer.new()
	head_col.add_theme_constant_override("separation", 2)
	head.add_child(head_col)
	head_col.add_child(_label(title.to_upper(), 22, accent, HORIZONTAL_ALIGNMENT_CENTER))
	head_col.add_child(_label(subtitle, 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))

	for i in range(cards.size()):
		box.add_child(_card_row(i + 1, cards[i], base_color, icon_kind))
	return panel

func _card_row(index: int, card: Dictionary, base_color: Color, icon_kind: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.panel_style(Color("#FFFAEC"), Color("#E8D8A8"), 8, 1))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(34, 34)
	badge.add_theme_stylebox_override("panel", Palette.panel_style(base_color, base_color, 8, 0))
	badge.add_child(_label(str(index), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	row.add_child(badge)

	var ic := Icon.new()
	ic.custom_minimum_size = Vector2(34, 34)
	ic.configure(_icon_for_type(str(card.get("type", "")), icon_kind), base_color)
	row.add_child(ic)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 1)
	row.add_child(box)

	# Tiêu đề thẻ: bỏ emoji prefix nếu có, dùng phần mô tả của E
	var title_txt := str(card.get("title", "Thẻ"))
	box.add_child(_label(title_txt, 14, Palette.TEXT_DARK))
	var desc := _label(str(card.get("desc", "")).replace("\n", " "), 12, Color("#4E4638"))
	desc.add_theme_constant_override("outline_size", 0)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc)
	return panel

func _icon_for_type(card_type: String, fallback: String) -> String:
	match card_type:
		"reward":   return "money"
		"penalty":  return "money"
		"move":     return "city"
		"jail":     return "jail"
		"card":     return "trophy"
		"birthday": return "gift"
		"choice":   return "hourglass"
	return fallback
