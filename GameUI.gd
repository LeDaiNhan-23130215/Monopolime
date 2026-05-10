extends Node
class_name GameUI

# Signal báo GameController rằng người chơi đã xử lý xong ô đất (landing)
signal ui_action_done

# ─── Dice nodes ──────────────────────────────────────────────────────
@onready var label            : Label               = get_node("UI/Result")
@onready var timer            : Timer               = get_node("UI/DiceTimer")
@onready var double_label     : Label               = get_node("UI/IsDoubleLabel")
@onready var dice1_sprite     : Sprite2D            = get_node("UI/Dice1")
@onready var dice2_sprite     : Sprite2D            = get_node("UI/Dice2")
@onready var audio_roll       : AudioStreamPlayer2D = get_node("UI/AudioRoll")
@onready var roll_button      : TextureButton       = get_node("UI/Roll Dice")

@onready var save_load_menu = get_node("SaveLoadMenu")
# ─── Nút quản lý tài sản luôn hiện suốt lượt (bất kỳ ô nào) ────────
@onready var btn_open_manage  : Button         = get_node("UI/BtnOpenManage")

# ─── UC7 panels ──────────────────────────────────────────────────────

@onready var action_popup     : PanelContainer = get_node("UI/ActionPopup")
@onready var btn_buy          : Button         = get_node("UI/ActionPopup/VBox/BtnBuy")
@onready var btn_build        : Button         = get_node("UI/ActionPopup/VBox/BtnBuild")
@onready var btn_mortgage     : Button         = get_node("UI/ActionPopup/VBox/BtnMortgage")
@onready var btn_redeem       : Button         = get_node("UI/ActionPopup/VBox/BtnRedeem")
@onready var btn_sell_house   : Button         = get_node("UI/ActionPopup/VBox/BtnSellHouse")
@onready var btn_sell         : Button         = get_node("UI/ActionPopup/VBox/BtnSell")
@onready var btn_close_action : Button         = get_node("UI/ActionPopup/VBox/BtnClose")

@onready var prop_popup       : PanelContainer = get_node("UI/PropertyPopup")
@onready var popup_title      : Label          = get_node("UI/PropertyPopup/VBox/Title")
@onready var prop_list        : ItemList       = get_node("UI/PropertyPopup/VBox/PropertyList")
@onready var btn_pp_confirm   : Button         = get_node("UI/PropertyPopup/VBox/HBox/BtnConfirm")
@onready var btn_pp_cancel    : Button         = get_node("UI/PropertyPopup/VBox/HBox/BtnCancel")



# ─── Dice textures ───────────────────────────────────────────────────
var dice_textures: Array = [
	preload("res://resources/dices/dice1.jpg"),
	preload("res://resources/dices/dice2.jpg"),
	preload("res://resources/dices/dice3.jpg"),
	preload("res://resources/dices/dice4.jpg"),
	preload("res://resources/dices/dice5.jpg"),
	preload("res://resources/dices/dice6.jpg"),
]

# ─── Shared state ────────────────────────────────────────────────────
var rolling    := false
var roll_time  := 0.0
var base_scale := Vector2.ONE

var paused_for_menu := false
var game_controller : GameController

# ─── UC7 internal state ──────────────────────────────────────────────
var _player   : Player       = null
var _am       : AssetManager = null
var _action   : String       = ""
var _cell     : PropertyCell = null
var _buy_cell : PropertyCell = null

# Phân biệt 2 chế độ mở UC7:
#   _mandatory = true  → do landing (GameController đang await ui_action_done)
#   _mandatory = false → người chơi chủ động bấm nút (KHÔNG await)
var _mandatory := false

# ─── UC09 Event & Player Panel ──────────────────────────────────────
signal buy_decision_made(want_to_buy: bool)

var _ev_overlay    : ColorRect     = null
var _ev_panel      : Panel         = null
var _ev_icon       : Label         = null
var _ev_title      : Label         = null
var _ev_desc       : Label         = null
var _ev_btn_box    : HBoxContainer = null
var _ev_callback   : Callable

var _buy_panel     : Panel         = null

var _pp_panel      : Panel         = null
var _pp_content    : VBoxContainer = null

# ═════════════════════════════════════════════════════════════════════
# _ready
# ═════════════════════════════════════════════════════════════════════
func _ready() -> void:
	var tex_size     : float = dice1_sprite.texture.get_size().x
	var scale_factor : float = 64.0 / tex_size
	base_scale = Vector2.ONE * scale_factor
	dice1_sprite.scale = base_scale
	dice2_sprite.scale = base_scale

	# FIX HITBOX: CanvasLayer phải follow viewport để mouse coords khớp UI
	# khi window bị resize khác resolution gốc
	var canvas_layer = get_node("UI") as CanvasLayer
	if canvas_layer:
		canvas_layer.follow_viewport_enabled = true

	action_popup.visible = false
	prop_popup.visible   = false

	# FIX: connect item_selected trong code để chắc chắn hoạt động
	if not prop_list.item_selected.is_connected(_on_property_list_item_selected):
		prop_list.item_selected.connect(_on_property_list_item_selected)

	if btn_open_manage:
		btn_open_manage.visible = false
		if not btn_open_manage.pressed.is_connected(_on_btn_open_manage_pressed):
			btn_open_manage.pressed.connect(_on_btn_open_manage_pressed)

	save_load_menu.menu_closed.connect(_on_save_load_menu_closed)
	save_load_menu.save_slot_requested.connect(_on_save_slot_requested)
	save_load_menu.load_slot_requested.connect(_on_load_slot_requested)

	_create_uc09_ui()


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") and not save_load_menu.visible:
		_open_save_load_menu()
		get_viewport().set_input_as_handled()


func _open_save_load_menu():
	save_load_menu.open_menu()
	_set_roll_button_enabled(false)
	if not get_tree().paused:
		get_tree().paused = true
		paused_for_menu = true


func _on_save_load_menu_closed():
	_set_roll_button_enabled(true)
	if paused_for_menu:
		get_tree().paused = false
		paused_for_menu = false


func _set_roll_button_enabled(enabled: bool):
	if roll_button:
		roll_button.disabled = not enabled


# ═════════════════════════════════════════════════════════════════════
# DICE
# ═════════════════════════════════════════════════════════════════════
func show_turn(player_index: int) -> void:
	var player = game_controller.get_current_player()
	var pname = player.name if player else ("P%d" % (player_index + 1))
	label.text = "Lượt của %s" % pname
	# FIX: Luôn hiện nút quản lý tài sản khi đến lượt (bất kỳ ô nào - BR-16)
	if btn_open_manage:
		btn_open_manage.text    = "⚙ Quản lý tài sản (%s)" % pname
		btn_open_manage.visible = true

func start_dice_animation() -> void:
	rolling   = true
	roll_time = 0.0
	timer.start()
	audio_roll.play()
	shake()

func show_result(result) -> void:
	label.text = "Xúc xắc: %d + %d = %d" % [result.dice1, result.dice2, result.total()]
	audio_roll.stop()

func show_double() -> void:
	double_label.visible = true
	double_label.text    = "DOUBLE!"
	await get_tree().create_timer(2.0).timeout
	double_label.visible = false

func show_jail() -> void:
	label.text = "VÀO TÙ!"

func set_roll_enabled(enabled: bool) -> void:
	roll_button.disabled = not enabled
	# FIX: Ẩn nút quản lý khi bắt đầu lượt mới (enabled=true = lượt tiếp theo)
	if enabled and btn_open_manage:
		btn_open_manage.visible = false

func show_message(text: String) -> void:
	label.text = text

func _on_dice_timer_timeout() -> void:
	if not rolling:
		return
	roll_time += timer.wait_time
	dice1_sprite.texture  = dice_textures[randi_range(0, 5)]
	dice2_sprite.texture  = dice_textures[randi_range(0, 5)]
	dice1_sprite.rotation = randf_range(-0.3, 0.3)
	dice2_sprite.rotation = randf_range(-0.3, 0.3)
	_bounce(dice1_sprite)
	_bounce(dice2_sprite)
	if roll_time >= 0.7:
		timer.stop()
		rolling = false
		var result = game_controller.final_result
		dice1_sprite.texture  = dice_textures[result.dice1 - 1]
		dice2_sprite.texture  = dice_textures[result.dice2 - 1]
		dice1_sprite.rotation = 0.0
		dice2_sprite.rotation = 0.0
		await game_controller.resolve_roll()

func _bounce(sprite: Sprite2D) -> void:
	sprite.scale = base_scale
	var tw = create_tween()
	tw.tween_property(sprite, "scale", base_scale * 1.2, 0.1)
	tw.tween_property(sprite, "scale", base_scale, 0.1)

func shake() -> void:
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return
	for i in range(5):
		cam.offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		await get_tree().create_timer(0.03).timeout
	cam.offset = Vector2.ZERO


func _on_roll_dice_pressed() -> void:
	if save_load_menu.visible:
		return
	game_controller.roll_dice()
# ═════════════════════════════════════════════════════════════════════
# UC7 – ENTRY POINTS
# ═════════════════════════════════════════════════════════════════════

# Gọi khi đáp xuống ô chưa có chủ (bắt buộc xử lý)
func prompt_buy_or_pass(player: Player, cell: PropertyCell, am: AssetManager) -> void:
	_player    = player
	_am        = am
	_buy_cell  = cell
	_mandatory = true
	var pd = cell.data as PropertyData
	show_message("%s đứng trên %s ($%d)" % [player.name, cell.data.cell_name, pd.buy_price if pd else 0])
	_open_action_menu()

func _on_save_slot_requested(slot_id: int):
	game_controller.save_game(slot_id)
	save_load_menu.refresh_slots()


func _on_load_slot_requested(slot_id: int):
	game_controller.load_game(slot_id)


func is_dice_rolling() -> bool:
	return rolling

func auto_mortgage_for_test(player: Player, amount_needed: int):
	print("--- [Auto Test] Đang tự động bán đất để trả nợ cho ", player.name, " ---")
	
	var target_balance = player.balance + amount_needed
	
	for cell in player.properties:
		if not cell.is_mortgaged and player.balance < target_balance:
			var amount = cell.mortgage_property()
			print("> Tự động thế chấp: ", cell.cell_name, " lấy $", amount)
			
	# Chờ 1.5 giây để bạn kịp nhìn console
	await get_tree().create_timer(1.5).timeout 
	
	# Quan trọng: Kích hoạt lại lượt đi cho GameController
	print("Đã xoay đủ tiền, tiếp tục game!")
	
	game_controller.emit_signal("turn_action_completed")
# Gọi khi đáp xuống đất của mình (bắt buộc xử lý)
func show_asset_management(player: Player, am: AssetManager) -> void:
	_player    = player
	_am        = am
	_buy_cell  = null
	_mandatory = true
	_open_action_menu()

# FIX: Gọi khi người chơi chủ động bấm nút quản lý (tự nguyện, bất kỳ ô nào)
func _on_btn_open_manage_pressed() -> void:
	# Nếu đang trong mandatory mode, mở lại action menu (không thay đổi state)
	if _mandatory and _player != null:
		_open_action_menu()
		return
	var player = game_controller.get_current_player()
	if player == null or player.is_bankrupt():
		return
	_player    = player
	_am        = game_controller.asset_manager
	_buy_cell  = null
	_mandatory = false
	_open_action_menu()

func hide_manage_button() -> void:
	action_popup.visible = false
	prop_popup.visible   = false

# Gọi khi thực sự hoàn thành xong hành động (emit signal nếu mandatory)
func _done_with_action() -> void:
	var was_mandatory = _mandatory
	_player    = null
	_am        = null
	_buy_cell  = null
	_cell      = null
	_action    = ""
	_mandatory = false
	hide_manage_button()
	if was_mandatory:
		emit_signal("ui_action_done")

func _open_action_menu() -> void:
	if _player == null:
		return
	var all_cells    = game_controller.board.cells
	var can_build    = false
	var has_props    = false
	var has_mortgage = false

	var has_houses = false
	for c in _player.properties:
		if c is PropertyCell:
			has_props = true
			if c.is_mortgaged:
				has_mortgage = true
			if c.house_count > 0 or c.has_hotel:
				has_houses = true
			if not c.is_mortgaged and not c.has_hotel:
				if PropertyController.can_build_on(c, _player, all_cells):
					can_build = true

	btn_buy.visible        = (_buy_cell != null)
	btn_build.visible      = can_build
	btn_mortgage.visible   = has_props
	btn_redeem.visible     = has_mortgage
	# Nút bán nhà: chỉ hiện khi có ít nhất 1 nhà hoặc khách sạn
	btn_sell_house.visible = has_houses
	btn_sell.visible       = has_props

	# FIX: Text nút phân theo chế độ
	if btn_close_action:
		btn_close_action.text = "Kết thúc lượt" if _mandatory else "Đóng"

	# FIX: Đóng popup con trước khi hiện ActionPopup
	prop_popup.visible   = false
	action_popup.visible = true

# FIX: "Kết thúc lượt" / "Đóng"
# mandatory → end turn (emit signal)
# chủ động → chỉ ẩn menu, btn_open_manage VẪN hiện
func _on_btn_close_action_pressed() -> void:
	action_popup.visible = false
	if _mandatory:
		_done_with_action()
	else:
		# Chỉ đóng menu, không xóa trạng thái, không ẩn btn_open_manage
		_player   = null
		_am       = null
		_buy_cell = null
		_cell     = null
		_action   = ""
			# btn_open_manage vẫn hiện để người chơi mở lại bất cứ lúc nào


# ═════════════════════════════════════════════════════════════════════
# ACTIONS
# ═════════════════════════════════════════════════════════════════════
func _on_btn_buy_pressed() -> void:
	if _buy_cell == null or _player == null:
		return
	action_popup.visible = false
	var ok = _am.buy_property(_player, _buy_cell)
	if ok:
		show_message("Mua thành công!")
	else:
		show_message("Không đủ tiền! Ô đất này chưa có chủ sở hữu.")
	_done_with_action()

func _on_btn_build_pressed() -> void:
	action_popup.visible = false
	_action = "build"
	var all_cells = game_controller.board.cells
	var eligible: Array = []
	for c in _player.properties:
		if c is PropertyCell and not c.is_mortgaged and not c.has_hotel:
			if PropertyController.can_build_on(c, _player, all_cells):
				eligible.append(c)
	_open_prop_popup("Chọn ô để xây nhà / khách sạn", eligible)

func _on_btn_mortgage_pressed() -> void:
	action_popup.visible = false
	_action = "mortgage"
	var eligible: Array = []
	for c in _player.properties:
		if c is PropertyCell and not c.is_mortgaged and c.house_count == 0 and not c.has_hotel:
			eligible.append(c)
	_open_prop_popup("Chọn ô để thế chấp (nhận 50% giá trị)", eligible)

func _on_btn_redeem_pressed() -> void:
	action_popup.visible = false
	_action = "redeem"
	var eligible: Array = []
	for c in _player.properties:
		if c is PropertyCell and c.is_mortgaged:
			eligible.append(c)
	_open_prop_popup("Chọn ô để chuộc lại (+10% lãi)", eligible)

# Bán nhà / khách sạn về Ngân hàng
func _on_btn_sell_house_pressed() -> void:
	action_popup.visible = false
	_action = "sell_house"
	var eligible: Array = []
	for c in _player.properties:
		if c is PropertyCell and (c.house_count > 0 or c.has_hotel):
			eligible.append(c)
	_open_prop_popup("Chọn ô để bán nhà / khách sạn (nhận 50% chi phí xây)", eligible)

# Bán đất về Ngân hàng
func _on_btn_sell_pressed() -> void:
	action_popup.visible = false
	_action = "sell"
	var eligible: Array = []
	for c in _player.properties:
		if c is PropertyCell:
			eligible.append(c)
	_open_prop_popup("Chọn ô muốn bán về Ngân hàng (nhận 50% giá mua)", eligible)




# ═════════════════════════════════════════════════════════════════════
# PROPERTY POPUP
# ═════════════════════════════════════════════════════════════════════
func _open_prop_popup(title: String, cells: Array) -> void:
	if cells.is_empty():
		show_message("Không có ô đất phù hợp!")
		# FIX: Quay lại ActionPopup thay vì đóng hẳn
		_open_action_menu()
		return
	popup_title.text = title
	prop_list.clear()
	_cell = null
	# FIX: Luôn disable Confirm khi mới mở - phải chọn item trước
	if btn_pp_confirm:
		btn_pp_confirm.disabled = true
	for c in cells:
		if c is PropertyCell:
			var info = c.data.cell_name
			if c.is_mortgaged:      info += " [Thế chấp]"
			elif c.has_hotel:       info += " [Khách sạn]"
			elif c.house_count > 0: info += " [%d nhà]" % c.house_count
			prop_list.add_item(info)
			prop_list.set_item_metadata(prop_list.item_count - 1, c)
	prop_popup.visible = true

# FIX: Enable Confirm ngay khi chọn item trong list
func _on_property_list_item_selected(index: int) -> void:
	_cell = prop_list.get_item_metadata(index)
	if btn_pp_confirm:
		btn_pp_confirm.disabled = (_cell == null)

# FIX: Hủy trong PropertyPopup → quay lại ActionPopup (không đóng hẳn)
func _on_btn_pp_cancel_pressed() -> void:
	prop_popup.visible = false
	_cell   = null
	_action = ""
	_open_action_menu()

func _on_btn_pp_confirm_pressed() -> void:
	if _cell == null:
		return
	prop_popup.visible = false
	var current_action = _action
	_action = ""
	match current_action:
		"build":
			var ok = _am.build_house(_player, _cell)
			show_message("Xây thành công!" if ok else "Xây thất bại!")
			_done_with_action()
		"mortgage":
			var ok = _am.mortgage_property(_player, _cell)
			show_message("Thế chấp thành công!" if ok else "Thế chấp thất bại!")
			_done_with_action()
		"redeem":
			var ok = _am.redeem_property(_player, _cell)
			show_message("Chuộc lại thành công!" if ok else "Chuộc lại thất bại!")
			_done_with_action()
		"sell_house":
			var ok = _am.sell_house_to_bank(_player, _cell)
			show_message("Bán nhà thành công!" if ok else "Bán nhà thất bại!")
			_done_with_action()
		"sell":
			if _cell.house_count > 0 or _cell.has_hotel:
				show_message("Phải bán hết nhà / khách sạn trước khi bán đất!")
				_open_action_menu()
				return
			if _cell.is_mortgaged:
				show_message(_cell.data.cell_name + " đang thế chấp! Hãy chuộc lại trước.")
				_open_action_menu()
				return
			var ok = _am.sell_property_to_bank(_player, _cell)
			show_message("Bán đất thành công!" if ok else "Bán đất thất bại!")
			_done_with_action()


# ═════════════════════════════════════════════════════════════════════
# REQUEST MORTGAGE (khi thiếu tiền trả thuê – AF7.7)
# ═════════════════════════════════════════════════════════════════════
func request_mortgage(player: Player, amount_needed: int) -> void:
	_player    = player
	_am        = game_controller.asset_manager
	_mandatory = true
	show_message("%s thiếu $%d! Hãy thế chấp hoặc bán nhà / đất." % [player.name, amount_needed])
	btn_buy.visible        = false
	btn_build.visible      = false
	btn_redeem.visible     = false
	btn_mortgage.visible   = true
	btn_sell_house.visible = true
	btn_sell.visible       = true
	action_popup.visible   = true


# ═════════════════════════════════════════════════════════════════════
# UC09 – EVENT POPUP & PLAYER PANEL
# ═════════════════════════════════════════════════════════════════════

func _create_uc09_ui() -> void:
	# --- Overlay ---
	_ev_overlay = ColorRect.new()
	_ev_overlay.color = Color(0, 0, 0, 0.55)
	_ev_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ev_overlay.visible = false
	get_node("UI").add_child(_ev_overlay)

	# --- Event Panel ---
	_ev_panel = Panel.new()
	_ev_panel.set_size(Vector2(440, 340))
	_ev_panel.set_position(Vector2(300, 130))
	_ev_panel.visible = false
	var es = StyleBoxFlat.new()
	es.bg_color = Color(0.08, 0.06, 0.18, 0.97)
	es.set_border_width_all(3)
	es.border_color = Color(0.6, 0.4, 1.0)
	es.set_corner_radius_all(16)
	_ev_panel.add_theme_stylebox_override("panel", es)

	var ev_vbox = VBoxContainer.new()
	ev_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	ev_vbox.offset_left = 24; ev_vbox.offset_top = 18
	ev_vbox.offset_right = -24; ev_vbox.offset_bottom = -18
	ev_vbox.add_theme_constant_override("separation", 10)
	_ev_panel.add_child(ev_vbox)

	_ev_icon = Label.new()
	_ev_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ev_icon.add_theme_font_size_override("font_size", 40)
	ev_vbox.add_child(_ev_icon)

	_ev_title = Label.new()
	_ev_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ev_title.add_theme_font_size_override("font_size", 22)
	_ev_title.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	ev_vbox.add_child(_ev_title)

	ev_vbox.add_child(HSeparator.new())

	_ev_desc = Label.new()
	_ev_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ev_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ev_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ev_desc.add_theme_font_size_override("font_size", 16)
	_ev_desc.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85))
	ev_vbox.add_child(_ev_desc)

	_ev_btn_box = HBoxContainer.new()
	_ev_btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_ev_btn_box.add_theme_constant_override("separation", 12)
	ev_vbox.add_child(_ev_btn_box)

	get_node("UI").add_child(_ev_panel)

	# --- Player Panel (bảng tài sản bên phải) ---
	_pp_panel = Panel.new()
	_pp_panel.set_size(Vector2(210, 580))
	_pp_panel.set_position(Vector2(868, 15))
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.12, 0.92)
	ps.set_border_width_all(1)
	ps.border_color = Color(0.4, 0.4, 0.8)
	ps.set_corner_radius_all(8)
	_pp_panel.add_theme_stylebox_override("panel", ps)

	var pp_title = Label.new()
	pp_title.text = "📊 Bảng Tài Sản"
	pp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pp_title.add_theme_font_size_override("font_size", 14)
	pp_title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	pp_title.set_position(Vector2(0, 6))
	pp_title.set_size(Vector2(210, 26))
	_pp_panel.add_child(pp_title)

	# ScrollContainer để không bị chồng chéo khi nhiều tài sản
	var scroll = ScrollContainer.new()
	scroll.set_position(Vector2(5, 36))
	scroll.set_size(Vector2(200, 538))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pp_panel.add_child(scroll)

	_pp_content = VBoxContainer.new()
	_pp_content.custom_minimum_size = Vector2(196, 0)
	_pp_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pp_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_pp_content)

	get_node("UI").add_child(_pp_panel)


# Gọi từ EventHandler để hiển thị popup thẻ Cơ Hội / Khí Vận
func show_event_popup(
		title: String, description: String,
		choices: Array, callback: Callable,
		card_type: String = "") -> void:
	print("--- SHOW EVENT POPUP: ", title, " ---")
	_ev_callback = callback

	match card_type:
		"chance":
			_ev_icon.text = "🎴"
			_ev_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			var s = _ev_panel.get_theme_stylebox("panel").duplicate()
			s.border_color = Color(1.0, 0.75, 0.1)
			_ev_panel.add_theme_stylebox_override("panel", s)
		"community":
			_ev_icon.text = "🎁"
			_ev_title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
			var s = _ev_panel.get_theme_stylebox("panel").duplicate()
			s.border_color = Color(0.2, 0.8, 1.0)
			_ev_panel.add_theme_stylebox_override("panel", s)
		_:
			_ev_icon.text = "⚡"

	_ev_title.text = title
	_ev_desc.text  = description

	for child in _ev_btn_box.get_children():
		child.queue_free()

	for i in range(choices.size()):
		var btn = Button.new()
		btn.text = choices[i]
		btn.custom_minimum_size = Vector2(130, 44)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_ev_btn_pressed.bind(i))
		_ev_btn_box.add_child(btn)

	_ev_overlay.visible = true
	_ev_panel.visible   = true
	_ev_panel.move_to_front()


func _on_ev_btn_pressed(choice_index: int) -> void:
	_ev_overlay.visible = false
	_ev_panel.visible   = false
	if _ev_callback.is_valid():
		_ev_callback.call(choice_index)


# Cập nhật bảng tài sản từ snapshot do GameController cung cấp
func refresh_player_panel(snapshot: Array) -> void:
	if _pp_panel == null or _pp_content == null:
		return

	for child in _pp_content.get_children():
		child.queue_free()

	var player_colors = [
		Color(0.3, 0.5, 1.0), Color(1.0, 0.35, 0.35),
		Color(0.2, 0.85, 0.4), Color(1.0, 0.85, 0.1)
	]
	var player_emojis = ["🔵", "🔴", "🟢", "🟡"]

	for p in snapshot:
		var card = Panel.new()
		card.custom_minimum_size = Vector2(192, 0)
		var pid: int = p["id"]
		var pc: Color = player_colors[pid % player_colors.size()]
		var cs = StyleBoxFlat.new()
		cs.bg_color = Color(pc.r * 0.22, pc.g * 0.22, pc.b * 0.22, 0.95)
		cs.border_width_left = 3
		cs.border_color = pc
		cs.set_corner_radius_all(6)
		cs.content_margin_left   = 8
		cs.content_margin_right  = 6
		cs.content_margin_top    = 7
		cs.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", cs)

		var vb = VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.add_theme_constant_override("separation", 4)
		card.add_child(vb)

		var name_lbl = Label.new()
		var jail_tag = " 🔒" if p["in_jail"] else ""
		name_lbl.text = player_emojis[pid % player_emojis.size()] + " " + p["name"] + jail_tag
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", pc)
		vb.add_child(name_lbl)

		var bal_lbl = Label.new()
		bal_lbl.text = "💰 $" + str(p["balance"])
		bal_lbl.add_theme_font_size_override("font_size", 13)
		bal_lbl.add_theme_color_override(
			"font_color",
			Color.LIME_GREEN if p["balance"] >= 200 else Color.TOMATO
		)
		vb.add_child(bal_lbl)

		if p["properties"].size() > 0:
			var pt = Label.new()
			pt.text = "🏠 BĐS (%d):" % p["properties"].size()
			pt.add_theme_font_size_override("font_size", 12)
			pt.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
			vb.add_child(pt)
			for pname in p["properties"]:
				var pl = Label.new()
				pl.text = "  • " + pname
				pl.add_theme_font_size_override("font_size", 12)
				pl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
				pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				vb.add_child(pl)
		else:
			var no_p = Label.new()
			no_p.text = "  (chưa có đất)"
			no_p.add_theme_font_size_override("font_size", 12)
			no_p.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			vb.add_child(no_p)

		_pp_content.add_child(card)
