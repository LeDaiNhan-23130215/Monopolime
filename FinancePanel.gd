extends RefCounted
class_name FinancePanel

# ════════════════════════════════════════════════════════════════════
# FinancePanel – Giao diện cho FinanceManager (UC-6)
# Hiển thị: số dư, lịch sử giao dịch, thống kê tài chính
# 
# Chỉ thuần: tiền vào / tiền ra / chuyển khoản / tổng quan
# ════════════════════════════════════════════════════════════════════

const CoTyPhuPalette = preload("res://scripts/ui_theme/CoTyPhuPalette.gd")

const MAX_LOG     := 40   # Số dòng lịch sử tối đa lưu trong RAM
const PANEL_W     := 480.0
const PANEL_H     := 520.0

# ─── Nodes ───────────────────────────────────────────────────────────
var _overlay      : ColorRect
var _panel        : Panel
var _title        : Label
var _tab_bar      : HBoxContainer

var _page_overview: Control
var _page_history : Control
var _page_transfer: Control

# Overview page
var _ov_scroll    : ScrollContainer
var _ov_content   : VBoxContainer

# History page
var _hist_scroll  : ScrollContainer
var _hist_list    : VBoxContainer
var _hist_clear_btn: Button

# Transfer page
var _tf_from_opt  : OptionButton
var _tf_to_opt    : OptionButton
var _tf_amount    : LineEdit
var _tf_result    : Label
var _tf_confirm   : Button

var _btn_close    : Button
var _interest_btn : Button

# ─── Runtime state ───────────────────────────────────────────────────
var _ui_root      : Node           # CanvasLayer "UI"
var _players      : Array          # Array[Player]
var _log          : Array = []     # Array[Dictionary] giao dịch gần đây

# Callback khi đóng (tuỳ chọn)
var on_closed     : Callable


# ════════════════════════════════════════════════════════════════════
# Khởi tạo – gọi 1 lần, truyền node CanvasLayer "UI" và danh sách players
# ════════════════════════════════════════════════════════════════════
func setup(ui_layer: Node, players: Array) -> void:
	_ui_root = ui_layer
	_players = players
	_build_panel()


# ════════════════════════════════════════════════════════════════════
# Mở panel (tự cập nhật dữ liệu trước khi hiện)
# ════════════════════════════════════════════════════════════════════
func open(players: Array = []) -> void:
	if players.size() > 0:
		_players = players
	_refresh_overview()
	_refresh_history()
	_refresh_transfer_opts()
	_switch_tab(0)
	if _overlay:
		_overlay.visible = true
	if _panel:
		_panel.visible = true


func close() -> void:
	if _overlay:
		_overlay.visible = false
	if _panel:
		_panel.visible = false
	if on_closed.is_valid():
		on_closed.call()


# ════════════════════════════════════════════════════════════════════
# Ghi log giao dịch (gọi từ GameController/FinanceManager khi xảy ra)
# ════════════════════════════════════════════════════════════════════
func log_transaction(action: String, player_name: String,
		amount: int, success: bool, note: String = "") -> void:
	var entry := {
		"action":      action,
		"player":      player_name,
		"amount":      amount,
		"success":     success,
		"note":        note,
		"time":        Time.get_ticks_msec()
	}
	_log.push_front(entry)
	if _log.size() > MAX_LOG:
		_log.resize(MAX_LOG)

	# Nếu panel đang mở thì cập nhật luôn
	if _panel and _panel.visible:
		_refresh_history()


# ════════════════════════════════════════════════════════════════════
# BUILD
# ════════════════════════════════════════════════════════════════════
func _build_panel() -> void:
	# --- Overlay ---
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.55)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	_ui_root.add_child(_overlay)

	# --- Panel chính ---
	_panel = Panel.new()
	_panel.set_size(Vector2(PANEL_W, PANEL_H))
	_panel.visible = false

	var sbox := StyleBoxFlat.new()
	sbox.bg_color      = Color("#0B1437")
	sbox.border_color  = Color("#FFC832")
	sbox.set_border_width_all(3)
	sbox.set_corner_radius_all(18)
	sbox.set_content_margin_all(0)
	sbox.shadow_color  = Color(0, 0, 0, 0.45)
	sbox.shadow_size   = 12
	sbox.shadow_offset = Vector2(0, 6)
	_panel.add_theme_stylebox_override("panel", sbox)

	# --- Root VBox ---
	var root_v := VBoxContainer.new()
	root_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_v.offset_left = 18; root_v.offset_top = 14
	root_v.offset_right = -18; root_v.offset_bottom = -14
	root_v.add_theme_constant_override("separation", 10)
	_panel.add_child(root_v)

	# --- Header row ---
	var header := HBoxContainer.new()
	root_v.add_child(header)

	var icon_lbl := Label.new()
	icon_lbl.text = "💰"
	icon_lbl.add_theme_font_size_override("font_size", 26)
	header.add_child(icon_lbl)

	_title = Label.new()
	_title.text = " Tài Chính"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color("#FFF1D4"))
	header.add_child(_title)

	_btn_close = Button.new()
	_btn_close.text = "✕"
	_btn_close.flat = true
	_btn_close.add_theme_font_size_override("font_size", 20)
	_btn_close.add_theme_color_override("font_color", Color("#E94C3D"))
	_btn_close.pressed.connect(close)
	header.add_child(_btn_close)

	root_v.add_child(_make_separator())

	# --- Tab bar ---
	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 6)
	root_v.add_child(_tab_bar)

	for i in range(3):
		var tab_btn := Button.new()
		tab_btn.text  = ["📊 Tổng quan", "📜 Lịch sử", "↔ Chuyển khoản"][i]
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.custom_minimum_size = Vector2(0, 36)
		var tab_idx := i
		tab_btn.pressed.connect(func(): _switch_tab(tab_idx))
		_tab_bar.add_child(tab_btn)

	root_v.add_child(_make_separator())

	# --- Pages container ---
	var pages := Control.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_v.add_child(pages)

	_page_overview = _build_overview_page()
	_page_history  = _build_history_page()
	_page_transfer = _build_transfer_page()

	for pg in [_page_overview, _page_history, _page_transfer]:
		pg.set_anchors_preset(Control.PRESET_FULL_RECT)
		pg.offset_left = 0; pg.offset_top = 0
		pg.offset_right = 0; pg.offset_bottom = 0
		pages.add_child(pg)

	_ui_root.add_child(_panel)
	_center_panel()


# ─── Overview page ────────────────────────────────────────────────
func _build_overview_page() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)

	# Nút Lãi suất
	_interest_btn = Button.new()
	_interest_btn.text = "💰 Nhận 10% lãi suất (Tất cả người chơi)"
	_interest_btn.custom_minimum_size = Vector2(0, 36)
	CoTyPhuPalette.style_button(_interest_btn, Color("#2E8B57"), 14)
	_interest_btn.pressed.connect(_on_interest_pressed)
	page.add_child(_interest_btn)

	# Container danh sách người chơi
	_ov_scroll = ScrollContainer.new()
	_ov_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ov_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(_ov_scroll)

	_ov_content = VBoxContainer.new()
	_ov_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ov_content.add_theme_constant_override("separation", 8)
	_ov_scroll.add_child(_ov_content)

	return page


func _refresh_overview() -> void:
	if _ov_content == null:
		return
	for c in _ov_content.get_children():
		c.queue_free()

	if _players.is_empty():
		_make_info_label(_ov_content, "Chưa có dữ liệu người chơi.")
		return

	for p in _players:
		if not (p is Player):
			continue
		var card := _build_player_finance_card(p)
		_ov_content.add_child(card)


func _build_player_finance_card(p: Player) -> Control:
	var c_idx := p.player_id % 4
	var p_color := CoTyPhuPalette.player_color(c_idx)

	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(p_color.r, p_color.g, p_color.b, 0.15)
	cs.border_color = p_color
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(10)
	cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)

	# Tên + bankrupt badge
	var name_row := HBoxContainer.new()
	vb.add_child(name_row)

	var name_lbl := Label.new()
	name_lbl.text = p.name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", p_color)
	name_row.add_child(name_lbl)

	if p.is_bankrupt():
		var bk := Label.new()
		bk.text = "⛔ Phá sản"
		bk.add_theme_font_size_override("font_size", 13)
		bk.add_theme_color_override("font_color", CoTyPhuPalette.RED)
		name_row.add_child(bk)

	# Số dư nổi bật
	var balance_row := HBoxContainer.new()
	vb.add_child(balance_row)

	var b_icon := Label.new()
	b_icon.text = "💵 Số dư: "
	b_icon.add_theme_font_size_override("font_size", 14)
	b_icon.add_theme_color_override("font_color", Color("#D0C8B8"))
	balance_row.add_child(b_icon)

	var b_val := Label.new()
	b_val.text = "$%d" % p.balance
	b_val.add_theme_font_size_override("font_size", 18)
	b_val.add_theme_color_override("font_color",
		CoTyPhuPalette.GREEN if p.balance >= 0 else CoTyPhuPalette.RED)
	balance_row.add_child(b_val)

	# Khả năng tổng (tiền + thế chấp tối đa)
	var cap := p.get_total_capacity()
	var cap_lbl := Label.new()
	cap_lbl.text = "🏦 Tổng tài lực (tiền + có thể thế chấp): $%d" % cap
	cap_lbl.add_theme_font_size_override("font_size", 13)
	cap_lbl.add_theme_color_override("font_color", Color("#A0B8D8"))
	vb.add_child(cap_lbl)

	# Số bất động sản
	var own_count := p.properties.size()
	var mortgaged := 0
	var with_house := 0
	for cell in p.properties:
		if cell is PropertyCell:
			if cell.is_mortgaged:
				mortgaged += 1
			if cell.house_count > 0 or cell.has_hotel:
				with_house += 1

	var prop_lbl := Label.new()
	prop_lbl.text = "🏠 Tài sản: %d ô  •  Thế chấp: %d  •  Có nhà/KS: %d" \
		% [own_count, mortgaged, with_house]
	prop_lbl.add_theme_font_size_override("font_size", 13)
	prop_lbl.add_theme_color_override("font_color", Color("#C0C8D8"))
	vb.add_child(prop_lbl)

	# Thẻ đặc biệt
	if p.special_card.size() > 0:
		var sc_lbl := Label.new()
		sc_lbl.text = "🃏 Thẻ ra tù: %d" % p.special_card.size()
		sc_lbl.add_theme_font_size_override("font_size", 13)
		sc_lbl.add_theme_color_override("font_color", CoTyPhuPalette.GOLD)
		vb.add_child(sc_lbl)

	return card


# ─── History page ─────────────────────────────────────────────────
func _build_history_page() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 6)

	var top_row := HBoxContainer.new()
	page.add_child(top_row)

	var hist_title := Label.new()
	hist_title.text = "📜 Lịch sử giao dịch gần đây"
	hist_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hist_title.add_theme_font_size_override("font_size", 15)
	hist_title.add_theme_color_override("font_color", Color("#FFF1D4"))
	top_row.add_child(hist_title)

	_hist_clear_btn = Button.new()
	_hist_clear_btn.text = "🗑 Xóa"
	CoTyPhuPalette.style_button(_hist_clear_btn, Color("#9A6B66"), 12)
	_hist_clear_btn.pressed.connect(_on_clear_history)
	top_row.add_child(_hist_clear_btn)

	_hist_scroll = ScrollContainer.new()
	_hist_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hist_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(_hist_scroll)

	_hist_list = VBoxContainer.new()
	_hist_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hist_list.add_theme_constant_override("separation", 4)
	_hist_scroll.add_child(_hist_list)

	return page


func _refresh_history() -> void:
	if _hist_list == null:
		return
	for c in _hist_list.get_children():
		c.queue_free()

	if _log.is_empty():
		_make_info_label(_hist_list, "Chưa có giao dịch nào.")
		return

	for entry in _log:
		_hist_list.add_child(_build_log_row(entry))


func _build_log_row(entry: Dictionary) -> Control:
	var success : bool   = entry.get("success", true)
	var action  : String = entry.get("action", "")
	var player  : String = entry.get("player", "")
	var amount  : int    = entry.get("amount", 0)
	var note    : String = entry.get("note", "")

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Icon trạng thái
	var icon := Label.new()
	icon.text = "✅" if success else "❌"
	icon.add_theme_font_size_override("font_size", 14)
	icon.custom_minimum_size = Vector2(24, 0)
	row.add_child(icon)

	# Loại giao dịch + người chơi
	var act_lbl := Label.new()
	act_lbl.text = "[%s] %s" % [_action_label(action), player]
	act_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	act_lbl.add_theme_font_size_override("font_size", 13)
	act_lbl.add_theme_color_override("font_color", Color("#D8D0C0") if success else Color("#E87070"))
	act_lbl.clip_text = true
	row.add_child(act_lbl)

	# Số tiền
	if amount != 0:
		var amt_lbl := Label.new()
		amt_lbl.text = ("+" if amount > 0 else "") + "$%d" % amount
		amt_lbl.add_theme_font_size_override("font_size", 14)
		amt_lbl.add_theme_color_override("font_color",
			CoTyPhuPalette.GREEN if amount > 0 else CoTyPhuPalette.RED)
		amt_lbl.custom_minimum_size = Vector2(80, 0)
		amt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(amt_lbl)

	# Ghi chú phụ (tooltip-style nhỏ bên dưới)
	if note != "":
		var wrapper := VBoxContainer.new()
		wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var main_row_inner := HBoxContainer.new()
		main_row_inner.add_child(act_lbl)
		wrapper.add_child(main_row_inner)
		var note_lbl := Label.new()
		note_lbl.text = note
		note_lbl.add_theme_font_size_override("font_size", 11)
		note_lbl.add_theme_color_override("font_color", Color("#808898"))
		note_lbl.clip_text = true
		wrapper.add_child(note_lbl)
		# Thay act_lbl gốc bằng wrapper
		act_lbl.get_parent().remove_child(act_lbl)
		row.add_child(wrapper)

	return row


func _action_label(action: String) -> String:
	match action:
		"add":      return "Nhận tiền"
		"deduct":   return "Trừ tiền"
		"transfer": return "Chuyển khoản"
		"interest": return "Nhận lãi suất"
		"buy":      return "Mua đất"
		"build":    return "Xây nhà"
		"mortgage": return "Thế chấp"
		"redeem":   return "Chuộc lại"
		"sell_house": return "Bán nhà"
		"sell":     return "Bán đất"
		"auction":  return "Đấu giá"
		"trade":    return "Trao đổi"
		"tax":      return "Thuế"
		"rent":     return "Tiền thuê"
		_:          return action.capitalize()


func _on_clear_history() -> void:
	_log.clear()
	_refresh_history()


# ─── Transfer page ────────────────────────────────────────────────
func _build_transfer_page() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.text = "↔ Chuyển tiền giữa người chơi"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("#FFF1D4"))
	page.add_child(title)

	# From
	var from_row := HBoxContainer.new()
	from_row.add_theme_constant_override("separation", 8)
	page.add_child(from_row)
	var from_lbl := Label.new()
	from_lbl.text = "Từ:"
	from_lbl.custom_minimum_size = Vector2(80, 0)
	from_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	from_lbl.add_theme_color_override("font_color", Color("#D8D0C0"))
	from_row.add_child(from_lbl)
	_tf_from_opt = OptionButton.new()
	_tf_from_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	from_row.add_child(_tf_from_opt)

	# To
	var to_row := HBoxContainer.new()
	to_row.add_theme_constant_override("separation", 8)
	page.add_child(to_row)
	var to_lbl := Label.new()
	to_lbl.text = "Đến:"
	to_lbl.custom_minimum_size = Vector2(80, 0)
	to_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	to_lbl.add_theme_color_override("font_color", Color("#D8D0C0"))
	to_row.add_child(to_lbl)
	_tf_to_opt = OptionButton.new()
	_tf_to_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	to_row.add_child(_tf_to_opt)

	# Amount
	var amt_row := HBoxContainer.new()
	amt_row.add_theme_constant_override("separation", 8)
	page.add_child(amt_row)
	var amt_lbl := Label.new()
	amt_lbl.text = "Số tiền:"
	amt_lbl.custom_minimum_size = Vector2(80, 0)
	amt_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amt_lbl.add_theme_color_override("font_color", Color("#D8D0C0"))
	amt_row.add_child(amt_lbl)
	_tf_amount = LineEdit.new()
	_tf_amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tf_amount.placeholder_text = "Nhập số tiền (VD: 200)"
	_tf_amount.text_changed.connect(_on_tf_amount_changed)
	amt_row.add_child(_tf_amount)

	# Kết quả preview
	_tf_result = Label.new()
	_tf_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tf_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tf_result.add_theme_font_size_override("font_size", 13)
	_tf_result.add_theme_color_override("font_color", Color("#A0B8D8"))
	page.add_child(_tf_result)

	# Confirm
	_tf_confirm = Button.new()
	_tf_confirm.text = "✅ Xác nhận chuyển khoản"
	_tf_confirm.custom_minimum_size = Vector2(0, 42)
	CoTyPhuPalette.style_button(_tf_confirm, CoTyPhuPalette.GREEN, 14)
	_tf_confirm.pressed.connect(_on_tf_confirm_pressed)
	page.add_child(_tf_confirm)

	# Ghi chú
	var note := Label.new()
	note.text = "⚠ Chức năng này chỉ dành cho quản trị viên / debug.\nLogic game thực tế điều phối qua FinanceManager."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color("#706858"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(note)

	return page


func _refresh_transfer_opts() -> void:
	if _tf_from_opt == null or _tf_to_opt == null:
		return
	_tf_from_opt.clear()
	_tf_to_opt.clear()

	for p in _players:
		if p is Player:
			var label := "%s ($%d)" % [p.name, p.balance]
			_tf_from_opt.add_item(label)
			_tf_to_opt.add_item(label)

	# Mặc định to = người thứ hai (nếu có)
	if _tf_to_opt.item_count > 1:
		_tf_to_opt.select(1)

	_update_transfer_preview()


func _on_tf_amount_changed(_text: String) -> void:
	_update_transfer_preview()


func _update_transfer_preview() -> void:
	if _tf_result == null:
		return
	var from_idx := _tf_from_opt.selected if _tf_from_opt else 0
	var to_idx   := _tf_to_opt.selected if _tf_to_opt else 0
	var amt_str  := _tf_amount.text.strip_edges() if _tf_amount else ""
	var amount   := int(amt_str) if amt_str.is_valid_int() else -1

	if _players.is_empty() or from_idx < 0 or to_idx < 0:
		_tf_result.text = ""
		return

	if from_idx == to_idx:
		_tf_result.text = "⚠ Người gửi và người nhận giống nhau."
		_tf_result.add_theme_color_override("font_color", CoTyPhuPalette.ORANGE)
		return

	if amount <= 0:
		_tf_result.text = "Nhập số tiền hợp lệ (> 0)."
		_tf_result.add_theme_color_override("font_color", Color("#A0B8D8"))
		return

	if from_idx >= _players.size() or to_idx >= _players.size():
		return

	var from_p : Player = _players[from_idx]
	var to_p   : Player = _players[to_idx]

	if not FinanceManager.can_afford(from_p, amount):
		_tf_result.text = "❌ %s không đủ tiền (có $%d, cần $%d)." \
			% [from_p.name, from_p.balance, amount]
		_tf_result.add_theme_color_override("font_color", CoTyPhuPalette.RED)
	else:
		_tf_result.text = "✅ %s chuyển $%d → %s\n   Số dư sau: %s còn $%d | %s nhận $%d" \
			% [from_p.name, amount, to_p.name,
			   from_p.name, from_p.balance - amount,
			   to_p.name, to_p.balance + amount]
		_tf_result.add_theme_color_override("font_color", CoTyPhuPalette.GREEN)


func _on_tf_confirm_pressed() -> void:
	if _tf_amount == null:
		return
	var from_idx := _tf_from_opt.selected
	var to_idx   := _tf_to_opt.selected
	var amt_str  := _tf_amount.text.strip_edges()

	if not amt_str.is_valid_int():
		_tf_result.text = "❌ Số tiền không hợp lệ."
		return

	var amount := int(amt_str)
	if amount <= 0:
		_tf_result.text = "❌ Số tiền phải lớn hơn 0."
		return

	if from_idx == to_idx:
		_tf_result.text = "❌ Người gửi và người nhận không được trùng."
		return

	if from_idx >= _players.size() or to_idx >= _players.size():
		return

	var from_p : Player = _players[from_idx]
	var to_p   : Player = _players[to_idx]

	var ok := FinanceManager.transfer(from_p, to_p, amount)
	if ok:
		log_transaction("transfer", from_p.name, -amount, true,
			"→ " + to_p.name + " +$" + str(amount))
		log_transaction("transfer", to_p.name, amount, true,
			"← " + from_p.name)
		_tf_amount.text = ""
		_refresh_transfer_opts()
		_tf_result.text = "✅ Chuyển khoản thành công!"
		_tf_result.add_theme_color_override("font_color", CoTyPhuPalette.GREEN)
	else:
		_tf_result.text = "❌ Chuyển khoản thất bại: %s không đủ tiền." % from_p.name
		_tf_result.add_theme_color_override("font_color", CoTyPhuPalette.RED)


# ════════════════════════════════════════════════════════════════════
# Tab switching
# ════════════════════════════════════════════════════════════════════
func _switch_tab(index: int) -> void:
	var pages := [_page_overview, _page_history, _page_transfer]
	for i in range(pages.size()):
		if pages[i]:
			pages[i].visible = (i == index)

	# Style tab buttons
	for i in range(_tab_bar.get_child_count()):
		var btn := _tab_bar.get_child(i) as Button
		if btn == null:
			continue
		if i == index:
			CoTyPhuPalette.style_button(btn, CoTyPhuPalette.PANEL_BLUE, 13)
		else:
			CoTyPhuPalette.style_button(btn, Color("#1E2A50"), 12)

	# Refresh trang đang mở
	match index:
		0: _refresh_overview()
		1: _refresh_history()
		2: _refresh_transfer_opts()


# ════════════════════════════════════════════════════════════════════
# Layout helpers
# ════════════════════════════════════════════════════════════════════
func _center_panel() -> void:
	if _panel == null or _ui_root == null:
		return
	# Đọc kích thước viewport từ scene tree
	var vp_size : Vector2
	if _ui_root.get_viewport():
		vp_size = _ui_root.get_viewport().get_visible_rect().size
	else:
		vp_size = Vector2(1024, 600)
	var pw : float = PANEL_W
	var ph : float = minf(PANEL_H, vp_size.y - 40.0)
	_panel.set_size(Vector2(pw, ph))
	_panel.set_position((vp_size - Vector2(pw, ph)) * 0.5)


func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	return sep


func _make_info_label(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color("#706858"))
	lbl.add_theme_font_size_override("font_size", 14)
	parent.add_child(lbl)


func _on_interest_pressed() -> void:
	if _players.is_empty():
		return

	# Áp dụng lãi suất cho tất cả người chơi
	for p in _players:
		if p is Player and not p.is_bankrupt():
			var interest = FinanceManager.apply_interest(p, 10.0)
			if interest > 0:
				log_transaction(
					"interest", 
					p.name, 
					interest, 
					true, 
					"Lãi suất 10%"
				)

	# Cập nhật lại UI sau khi thay đổi số dư
	_refresh_overview()
	_refresh_transfer_opts()
