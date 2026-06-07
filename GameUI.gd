extends Node
class_name GameUI

# Signal báo GameController rằng người chơi đã xử lý xong ô đất (landing)
signal ui_action_done
#---
@onready var tokens_node = get_node("../Board/Tokens")
# ─── Dice nodes ──────────────────────────────────────────────────────
@onready var label            : Label               = get_node("UI/Result")
@onready var timer            : Timer               = get_node("UI/DiceTimer")
@onready var double_label     : Label               = get_node("UI/IsDoubleLabel")
@onready var dice1_sprite     : Sprite2D            = get_node("UI/Dice1")
@onready var dice2_sprite     : Sprite2D            = get_node("UI/Dice2")
@onready var audio_roll       : AudioStreamPlayer2D = get_node("UI/AudioRoll")
@onready var roll_button      : TextureButton       = get_node("UI/Roll Dice")

@onready var save_load_menu = $UI/SaveLoadMenu
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
@onready var btn_trade        : Button         = get_node("UI/ActionPopup/VBox/BtnTrade")
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
var _dice_scale := Vector2.ONE  # scale hiển thị thực tế của dice (theo độ lớn bàn cờ)

var paused_for_menu := false
var game_controller : GameController

# ─── UC7 internal state ──────────────────────────────────────────────
var _player   : Player       = null
var _am       : AssetManager = null
var _action   : String       = ""
var _cell     : PropertyCell = null
var _buy_cell : PropertyCell = null

# ─────────────────────────────────────────────────────────────────────
# UC-10 – Trao đổi đất
# Khai báo biến trạng thái trao đổi, dùng trong suốt luồng BF 10.1.3 → 10.1.7
# ─────────────────────────────────────────────────────────────────────
# BF 10.1.3 / 10.1.5 – Lưu tạm ô đề nghị và ô yêu cầu trong quá trình chọn
var _trade_offer_cell: PropertyCell = null
var _trade_request_cell: PropertyCell = null
# BF 10.1.6 – Khoản bù tiền (mặc định 0 vì UI nhập chưa được hiện thực)
var _trade_compensation: int = 0
var _trade_payer: Player = null

# Phân biệt 2 chế độ mở UC7:
#   _mandatory = true  → do landing (GameController đang await ui_action_done)
#   _mandatory = false → người chơi chủ động bấm nút (KHÔNG await)
var _mandatory := false

# ─── UC09 Event & Player Panel ──────────────────────────────────────

var _ev_overlay    : ColorRect     = null
var _ev_panel      : Panel         = null
var _ev_icon       : Label         = null
var _ev_title      : Label         = null
var _ev_desc       : Label         = null
var _ev_btn_box    : HBoxContainer = null
var _ev_callback   : Callable

var _auction_panel  : Panel = null
var _auc_title      : Label = null
var _auc_desc       : Label = null
var _auc_current    : Label = null
var _auc_bid_input  : LineEdit = null
var _auc_btn_pass   : Button = null
var _auc_btn_bid    : Button = null
var _auc_btn_max    : Button = null
var _auc_participants: VBoxContainer = null
var _auc_callback = null
var _auc_bidder_id: int = -1

# Đấu giá: session id để hủy timer cũ khi mở phiên mới / đóng popup
var _auction_session_id := 0

var _pp_panel      : Control       = null
var _pp_content    : VBoxContainer = null

# ─── Giao diện bổ sung (background trung tâm, nút hướng dẫn, popup luật) ──
const CoTyPhuPalette = preload("res://scripts/ui_theme/CoTyPhuPalette.gd")
const RulesPopupScript = preload("res://scripts/ui_theme/RulesPopup.gd")
const FinancePanelScript = preload("res://FinancePanel.gd")
var _center_bg     : TextureRect = null
var _btn_rules     : Button      = null
var _rules_popup   : Control     = null
var _action_info   : Label       = null
var _sidebar_vbox  : VBoxContainer = null

# ─── UC-6 Finance Panel ──────────────────────────────────────────────
var _finance_panel = null   # FinancePanel (RefCounted)
var _btn_finance   : Button = null

# Layout: hằng số vùng (tính theo viewport, responsive)
const SIDEBAR_MIN := 220.0
const SIDEBAR_MAX := 300.0
const TOPBAR_H    := 52.0
const ACTION_H    := 150.0
const MARGIN      := 12.0

# ═════════════════════════════════════════════════════════════════════
# _ready
# ═════════════════════════════════════════════════════════════════════
func _ready() -> void:
	var tex_size     : float = dice1_sprite.texture.get_size().x
	var scale_factor : float = 64.0 / tex_size
	base_scale = Vector2.ONE * scale_factor
	dice1_sprite.scale = base_scale
	dice2_sprite.scale = base_scale

	# Stretch mode của project = canvas_items đã tự khớp toạ độ chuột với UI.
	# KHÔNG bật follow_viewport_enabled vì nó áp transform stretch lần 2 →
	# UI co nhỏ/dồn giữa và lệch hitbox (bấm nút không trúng).
	var canvas_layer = get_node("UI") as CanvasLayer
	if canvas_layer:
		canvas_layer.follow_viewport_enabled = false

	action_popup.visible = false
	prop_popup.visible   = false

	if not prop_list.item_selected.is_connected(_on_property_list_item_selected):
		prop_list.item_selected.connect(_on_property_list_item_selected)

	if btn_open_manage:
		btn_open_manage.visible = false
		if not btn_open_manage.pressed.is_connected(_on_btn_open_manage_pressed):
			btn_open_manage.pressed.connect(_on_btn_open_manage_pressed)

	if btn_trade:
		if not btn_trade.pressed.is_connected(_on_btn_trade_pressed):
			btn_trade.pressed.connect(_on_btn_trade_pressed)

	save_load_menu.menu_closed.connect(_on_save_load_menu_closed)
	save_load_menu.save_slot_requested.connect(_on_save_slot_requested)
	save_load_menu.load_slot_requested.connect(_on_load_slot_requested)

	_create_uc09_ui()
	_setup_visual_enhancements()
	_create_finance_panel()


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") and not save_load_menu.visible:
		_open_save_load_menu()
		get_viewport().set_input_as_handled()


func _open_save_load_menu():
	save_load_menu.open_menu()
	
	if _pp_panel:
		_pp_panel.visible = false
	
	if btn_open_manage:
		btn_open_manage.visible = false
	
	_set_roll_button_enabled(false)
	if not get_tree().paused:
		get_tree().paused = true
		paused_for_menu = true


func _on_save_load_menu_closed():
	_set_roll_button_enabled(true)
	
	if _pp_panel:
		_pp_panel.visible = true
		
	if btn_open_manage:
		btn_open_manage.visible = true
		
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
	sprite.scale = _dice_scale
	var tw = create_tween()
	tw.tween_property(sprite, "scale", _dice_scale * 1.2, 0.1)
	tw.tween_property(sprite, "scale", _dice_scale, 0.1)

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

func prompt_buy_or_pass(player: Player, cell: PropertyCell, am: AssetManager) -> void:
	_player    = player
	_am        = am
	_buy_cell  = cell
	_mandatory = true
	var pd = cell.data as PropertyData
	show_message("%s đứng trên %s ($%d)" % [player.name, cell.data.cell_name, pd.buy_price if pd else 0])
	# Hiển thị rõ mua ô nào, giá bao nhiêu (chỉ đổi text nút, không đổi logic)
	if btn_buy and pd:
		btn_buy.text = "🏠  Mua %s - $%d" % [CoTyPhuPalette.display_name(cell.data.cell_name), pd.buy_price]
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
			
	await get_tree().create_timer(1.5).timeout 
	
	print("Đã xoay đủ tiền, tiếp tục game!")
	
	game_controller.emit_signal("turn_action_completed")

func show_asset_management(player: Player, am: AssetManager) -> void:
	_player    = player
	_am        = am
	_buy_cell  = null
	_mandatory = true
	_open_action_menu()

func _on_btn_open_manage_pressed() -> void:
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

func _done_with_action() -> void:
	var was_mandatory = _mandatory
	_player    = null
	_am        = null
	_buy_cell  = null
	_cell      = null
	_action    = ""
	_mandatory = false
	_reset_trade_state()
	hide_manage_button()
	if was_mandatory:
		print("[UI] ui_action_done emitted")
		emit_signal("ui_action_done")

# ─────────────────────────────────────────────────────────────────────
# UC-10 – Helper: Reset toàn bộ biến trạng thái trao đổi
# Gọi sau khi giao dịch hoàn thành hoặc bị hủy giữa chừng
# ─────────────────────────────────────────────────────────────────────
func _reset_trade_state() -> void:
	_trade_offer_cell   = null
	_trade_request_cell = null
	_trade_compensation = 0
	_trade_payer        = null

func _open_action_menu() -> void:
	if _player == null:
		return
	var all_cells    = game_controller.board.cells
	var can_build    = false
	var has_props    = false
	var has_mortgage = false
	var other_player = _get_other_player()
	var can_trade = false

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

	if other_player != null and not other_player.is_bankrupt():
		var my_tradeable = game_controller.player_open_trade(_player)
		var their_tradeable = game_controller.player_open_trade(other_player)
		can_trade = not my_tradeable.is_empty() and not their_tradeable.is_empty()

	btn_buy.visible        = (_buy_cell != null)
	btn_build.visible      = can_build
	btn_mortgage.visible   = has_props
	btn_redeem.visible     = has_mortgage
	btn_sell_house.visible = has_houses
	btn_sell.visible       = has_props
	if btn_trade:
		btn_trade.visible  = can_trade

	if btn_close_action:
		btn_close_action.text = "Kết thúc lượt" if _mandatory else "Đóng"

	# Thông tin ngữ cảnh trên tiêu đề popup (chỉ hiển thị, không đổi logic)
	var act_title := action_popup.get_node_or_null("VBox/Title")
	if act_title and act_title is Label:
		var info := "Chọn hành động"
		if _player != null:
			info = "%s • 💰 $%d" % [_player.name, _player.balance]
			if _buy_cell != null and _buy_cell.data != null:
				var pd2 = _buy_cell.data as PropertyData
				var owner_txt := "Chưa có chủ" if _buy_cell.property_owner == null else _buy_cell.property_owner.name
				info += "\nÔ: %s ($%d) • %s" % [
					CoTyPhuPalette.display_name(_buy_cell.data.cell_name),
					pd2.buy_price if pd2 else 0,
					owner_txt
				]
		act_title.text = info
		act_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# FIX: Đóng popup con trước khi hiện ActionPopup
	prop_popup.visible   = false
	action_popup.visible = true
	# Tính lại kích thước/vị trí theo số nút đang hiện (tránh bị cắt nút)
	call_deferred("_place_action_popup")

func _on_btn_close_action_pressed() -> void:
	action_popup.visible = false
	if _mandatory:
		if _buy_cell != null and game_controller != null and _buy_cell.property_owner == null:
			await game_controller.start_auction(_buy_cell)
			_done_with_action()
		else:
			_done_with_action()
	else:
		_player   = null
		_am       = null
		_buy_cell = null
		_cell     = null
		_action   = ""
		_reset_trade_state()


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

func _on_btn_sell_house_pressed() -> void:
	action_popup.visible = false
	_action = "sell_house"
	var eligible: Array = []
	for c in _player.properties:
		if c is PropertyCell and (c.house_count > 0 or c.has_hotel):
			eligible.append(c)
	_open_prop_popup("Chọn ô để bán nhà / khách sạn (nhận 50% chi phí xây)", eligible)

func _on_btn_sell_pressed() -> void:
	action_popup.visible = false
	_action = "sell"
	var eligible: Array = []
	for c in _player.properties:
		if c is PropertyCell:
			eligible.append(c)
	_open_prop_popup("Chọn ô muốn bán về Ngân hàng (nhận 50% giá mua)", eligible)

# ─────────────────────────────────────────────────────────────────────
# BF 10.1.1 – UC-10: Handler khi Initiator bấm nút "🔄 Trao đổi đất"
# ─────────────────────────────────────────────────────────────────────
func _on_btn_trade_pressed() -> void:
	action_popup.visible = false
	_action = "trade"
	# BF 10.1.2 – Lấy danh sách ô hợp lệ của Initiator (BR-31T)
	var my_tradeable = game_controller.player_open_trade(_player)
	if my_tradeable.is_empty():
		# E10.1 – Không có ô hợp lệ
		show_message("Không có tài sản hợp lệ để trao đổi!")
		_open_action_menu()
		return
	# BF 10.1.3 – Hiển thị danh sách ô của Initiator để chọn offer_cell
	_open_trade_select_panel(my_tradeable)


# BF 10.1.3 – Mở prop_popup cho Initiator chọn offer_cell
func _open_trade_select_panel(my_cells: Array) -> void:
	_open_prop_popup("Chọn ô đất của bạn để trao đổi", my_cells)

func _open_trade_request_panel(offer_cell: PropertyCell) -> void:
	_trade_offer_cell = offer_cell
	var other = _get_other_player()
	if other == null:
		return
	var their_cells = game_controller.player_open_trade(other)
	if their_cells.is_empty():
		show_message("Đối thủ không có tài sản hợp lệ!")
		_open_action_menu()
		return
	_open_prop_popup("Chọn ô đất muốn nhận về", their_cells)



# ═════════════════════════════════════════════════════════════════════
# PROPERTY POPUP
# ═════════════════════════════════════════════════════════════════════
func _open_prop_popup(title: String, cells: Array) -> void:
	if cells.is_empty():
		show_message("Không có ô đất phù hợp!")
		_open_action_menu()
		return
	popup_title.text = title
	prop_list.clear()
	_cell = null
	if btn_pp_confirm:
		btn_pp_confirm.disabled = true
	for c in cells:
		if c is PropertyCell:
			var info = c.data.cell_name
			if c.is_mortgaged:      info += " [Thế chấp]"
			elif c.has_hotel:       info += " [Khách sạn]"
			elif c.house_count > 0: info += " [%d nhà]" % c.house_count
			if _action == "build":
				var pd = c.data as PropertyData
				if pd != null:
					if c.house_count >= 4 and not c.has_hotel:
						info += " • Nâng cấp KS: $%d" % pd.build_cost
					else:
						info += " • Xây nhà: $%d" % pd.build_cost
			prop_list.add_item(info)
			prop_list.set_item_metadata(prop_list.item_count - 1, c)
	prop_popup.visible = true

func _on_property_list_item_selected(index: int) -> void:
	_cell = prop_list.get_item_metadata(index)
	if btn_pp_confirm:
		btn_pp_confirm.disabled = (_cell == null)

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
			var build_cost = _cell.get_build_cost()
			var ok = _am.build_house(_player, _cell)
			if ok:
				show_message("Xây thành công! Đã trừ $%d" % build_cost)
			else:
				show_message("Xây thất bại!")
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
		"trade":
			if _trade_offer_cell == null:
				# BF 10.1.3 – Bước 1: Initiator vừa chọn xong offer_cell
				_trade_offer_cell = _cell
				_cell = null
				# BF 10.1.4 – Lấy danh sách ô hợp lệ của Receiver (BR-31T)
				var other = _get_other_player()
				if other == null:
					show_message("Không tìm thấy người chơi để trao đổi!")
					_open_action_menu()
					return
				var their_cells = game_controller.player_open_trade(other)
				if their_cells.is_empty():
					# E10.2 – Receiver không có ô hợp lệ
					show_message("Đối thủ không có tài sản hợp lệ!")
					_open_action_menu()
					return
				# BF 10.1.4 cont – Mở prop_popup để chọn request_cell
				# Giữ _action = "trade" để confirm lần 2 vào đúng nhánh
				_action = "trade"
				_open_prop_popup("Chọn ô đất muốn nhận về", their_cells)
			else:
				# BF 10.1.5 – Bước 2: Initiator vừa chọn xong request_cell
				_trade_request_cell = _cell
				_show_trade_compensation_dialog()

# ─────────────────────────────────────────────────────────────────────
# BF 10.1.5 – UC-10: Dialog nhập khoản bù tiền (BR-32T)
# Hiện tại chưa có UI nhập → mặc định compensation = 0, payer = null
# và gọi thẳng _send_trade_offer().
# TODO: Hiện thực AcceptDialog + LineEdit để nhập compensation.
# ─────────────────────────────────────────────────────────────────────
func _show_trade_compensation_dialog() -> void:
	_trade_compensation = 0
	_trade_payer = null
	_send_trade_offer()

# ─────────────────────────────────────────────────────────────────────
# BF 10.1.6 – UC-10: Validate đề nghị trước khi gửi (BR-31T, BR-32T)
# ─────────────────────────────────────────────────────────────────────
func _send_trade_offer() -> void:
	var other = _get_other_player()
	if other == null:
		show_message("Không tìm thấy người chơi để trao đổi!")
		_open_action_menu()
		return
	# Gọi validate_trade() kiểm tra BR-31T, BR-32T, E10.2, E10.3, E10.4
	var check = game_controller.asset_manager.validate_trade(
		_player, other, _trade_offer_cell, _trade_request_cell,
		_trade_compensation, _trade_payer)
	if not check["valid"]:
		# E10.2 / E10.3 / E10.4 – Validate thất bại
		show_message(check["reason"])
		_open_action_menu()
		return
	# Validate pass → tiến hành queue đề nghị
	_show_receiver_confirm_popup()

# ─────────────────────────────────────────────────────────────────────
# BF 10.1.7 – UC-10: Lưu đề nghị vào GameController (_pending_trade)
# Kết thúc lượt Initiator, chờ đến đầu lượt Receiver (BR-33T)
# ─────────────────────────────────────────────────────────────────────
func _show_receiver_confirm_popup() -> void:
	var other = _get_other_player()
	# Gọi player_queue_trade() → lưu vào _pending_trade trong GameController
	game_controller.player_queue_trade(
		_player, other,
		_trade_offer_cell, _trade_request_cell,
		_trade_compensation, _trade_payer
	)
	var other_name = other.name if other else "đối thủ"
	show_message("Đã gửi đề nghị trao đổi! Chờ đến lượt %s." % other_name)
	_reset_trade_state()
	_done_with_action()   # kết thúc lượt Initiator

# ─────────────────────────────────────────────────────────────────────
# BF 10.1.8 – UC-10: Hiển thị popup đề nghị cho Receiver
# Được gọi từ GameController.start_turn() khi phát hiện _pending_trade (BR-33T)
# ─────────────────────────────────────────────────────────────────────
func show_pending_trade_offer(t: Dictionary) -> void:
	var initiator: Player          = t["initiator"]
	var offer_cell: PropertyCell   = t["offer_cell"]
	var request_cell: PropertyCell = t["request_cell"]
	var compensation: int          = t["compensation"]
	var offer_name   = offer_cell.data.cell_name   if offer_cell   else "?"
	var request_name = request_cell.data.cell_name if request_cell else "?"
	# BF 10.1.8 – Xây thông báo tóm tắt đề nghị
	var msg = "%s muốn đổi [%s] lấy [%s] của bạn." % [initiator.name, offer_name, request_name]
	if compensation > 0:
		var payer: Player = t["payer"]
		msg += "\nKèm bù $%d từ %s." % [compensation, payer.name if payer else "?"]
	# BF 10.1.9 – Hiển thị show_event_popup với 2 lựa chọn (BR-33T)
	show_event_popup(
		"📦 Đề nghị trao đổi",
		msg,
		["✅ Đồng ý", "❌ Từ chối"],
		func(choice: int) -> void:
			if choice == 0:
				# BF 10.1.10 – Receiver đồng ý → gọi player_execute_trade() (BR-34T)
				# Truyền đúng initiator/receiver từ dictionary t,
				# tránh nhầm _player (lúc này _player có thể là Receiver)
				var ok = game_controller.player_execute_trade(
					t["initiator"], t["receiver"],
					t["offer_cell"], t["request_cell"],
					t["compensation"], t["payer"])
				show_message("Trao đổi thành công!" if ok else "Trao đổi thất bại!")
			else:
				# AF 10.2 – Receiver từ chối → không thay đổi trạng thái (BR-33T)
				show_message("%s đã từ chối đề nghị trao đổi." % initiator.name)
	)

func _on_receiver_accepted() -> void:
	var other = _get_other_player()
	var ok = game_controller.player_execute_trade(
		_player, other,
		_trade_offer_cell, _trade_request_cell,
		_trade_compensation, _trade_payer)
	show_message("Trao đổi thành công!" if ok else "Trao đổi thất bại!")
	_reset_trade_state()
	_done_with_action()

func _on_receiver_declined() -> void:
	show_message("Đối thủ đã từ chối đề nghị!")
	_reset_trade_state()
	_open_action_menu()

# ─────────────────────────────────────────────────────────────────────
# UC-10 – Helper: Lấy người chơi còn lại chưa phá sản
# ─────────────────────────────────────────────────────────────────────
func _get_other_player() -> Player:
	if game_controller == null:
		return null
	var all = game_controller.game_state.players
	for p in all:
		if p != _player and not p.is_bankrupt():
			return p
	return null


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
	if btn_trade:
		btn_trade.visible = false
	action_popup.visible   = true
	call_deferred("_place_action_popup")


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

	# --- Auction Panel (modal) ---
	# Đấu giá: panel riêng, modal, dùng session id để tránh timer cũ tự bấm pass vào phiên mới
	_auction_panel = Panel.new()
	_auction_panel.set_size(Vector2(520, 320))
	_auction_panel.set_position(Vector2(260, 140))
	_auction_panel.visible = false
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(0.06, 0.05, 0.12, 0.98)
	sbox.set_border_width_all(3)
	sbox.border_color = Color(0.7, 0.5, 0.95)
	sbox.set_corner_radius_all(12)
	_auction_panel.add_theme_stylebox_override("panel", sbox)

	var auc_v = VBoxContainer.new()
	auc_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	auc_v.offset_left = 18; auc_v.offset_top = 12
	auc_v.offset_right = -18; auc_v.offset_bottom = -12
	auc_v.add_theme_constant_override("separation", 8)
	_auction_panel.add_child(auc_v)

	_auc_title = Label.new()
	_auc_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_auc_title.add_theme_font_size_override("font_size", 18)
	auc_v.add_child(_auc_title)

	_auc_desc = Label.new()
	_auc_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_auc_desc.add_theme_font_size_override("font_size", 14)
	_auc_desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	auc_v.add_child(_auc_desc)

	_auc_current = Label.new()
	_auc_current.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_auc_current.add_theme_font_size_override("font_size", 16)
	auc_v.add_child(_auc_current)

	var bid_row = HBoxContainer.new()
	bid_row.add_theme_constant_override("separation", 8)
	_auc_bid_input = LineEdit.new()
	_auc_bid_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auc_bid_input.placeholder_text = "Nhập giá đặt (số nguyên)"
	bid_row.add_child(_auc_bid_input)
	_auc_btn_bid = Button.new()
	_auc_btn_bid.text = "Đặt"
	bid_row.add_child(_auc_btn_bid)
	auc_v.add_child(bid_row)

	_auc_btn_pass = Button.new()
	_auc_btn_pass.text = "Pass"
	_auc_btn_pass.custom_minimum_size = Vector2(160, 40)
	auc_v.add_child(_auc_btn_pass)

	var part_label = Label.new()
	part_label.text = "Người tham gia"
	part_label.add_theme_font_size_override("font_size", 14)
	auc_v.add_child(part_label)

	_auc_participants = VBoxContainer.new()
	_auc_participants.size_flags_vertical = Control.SIZE_EXPAND_FILL
	auc_v.add_child(_auc_participants)

	get_node("UI").add_child(_auction_panel)

	# --- Sidebar: Thông tin người chơi (container-based, responsive) ---
	_pp_panel = PanelContainer.new()
	_pp_panel.name = "PlayerSidebar"
	_pp_panel.add_theme_stylebox_override("panel",
		CoTyPhuPalette.panel_style(Color("#0B1437"), CoTyPhuPalette.PANEL_BLUE, 10, 2))

	var sb_vbox = VBoxContainer.new()
	sb_vbox.add_theme_constant_override("separation", 8)
	_pp_panel.add_child(sb_vbox)
	_sidebar_vbox = sb_vbox

	var pp_title = Label.new()
	pp_title.text = "👥 Thông tin người chơi"
	pp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pp_title.add_theme_font_size_override("font_size", 16)
	pp_title.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	sb_vbox.add_child(pp_title)
	sb_vbox.add_child(HSeparator.new())

	# ScrollContainer co giãn lấp đầy không gian còn lại
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sb_vbox.add_child(scroll)

	_pp_content = VBoxContainer.new()
	_pp_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pp_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_pp_content)

	get_node("UI").add_child(_pp_panel)


# ════════════════════════════════════════════════════════════════════
# GIAO DIỆN BỔ SUNG (chỉ hình ảnh, không đụng logic)
#   - Background trung tâm bàn cờ
#   - Nút "Hướng dẫn" + popup luật chơi (có thông tin thẻ)
#   - Tinh chỉnh style các panel/nút sẵn có
# ════════════════════════════════════════════════════════════════════
func _setup_visual_enhancements() -> void:
	var ui_layer = get_node("UI")
	if ui_layer == null:
		return

	# --- Popup hướng dẫn ---
	_rules_popup = RulesPopupScript.new()
	_rules_popup.name = "RulesPopup"
	ui_layer.add_child(_rules_popup)

	# --- Nút Hướng dẫn (góc trên trái) ---
	_btn_rules = Button.new()
	_btn_rules.name = "BtnRules"
	_btn_rules.text = "📖 Hướng dẫn"
	CoTyPhuPalette.style_button(_btn_rules, CoTyPhuPalette.GOLD, 16)
	_btn_rules.add_theme_color_override("font_color", CoTyPhuPalette.TEXT_DARK)
	_btn_rules.pressed.connect(_on_btn_rules_pressed)
	ui_layer.add_child(_btn_rules)

	# --- Nút Quản lý tài sản: chuyển hẳn VÀO sidebar (không trôi nổi) ---
	if btn_open_manage and _sidebar_vbox:
		var old_parent = btn_open_manage.get_parent()
		if old_parent:
			old_parent.remove_child(btn_open_manage)
		btn_open_manage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_open_manage.custom_minimum_size = Vector2(0, 40)
		_sidebar_vbox.add_child(btn_open_manage)

	# --- Style nhẹ cho panel/nút sẵn có ---
	_apply_existing_panel_styles()

	# --- Background trung tâm: gắn vào Board để tự căn giữa, mờ, nằm dưới ô ---
	call_deferred("_setup_center_background")

	# --- Responsive: lắng nghe đổi kích thước cửa sổ + layout lần đầu ---
	get_viewport().size_changed.connect(_relayout)
	call_deferred("_relayout")


func _setup_center_background() -> void:
	var board := get_node_or_null("../Board")
	if board == null:
		return
	if board.has_node("CenterBackground"):
		return
	var bg_path := "res://resources/ui_from_D/center_bg.png"
	if not ResourceLoader.exists(bg_path):
		return
	# Bàn cờ 6x6 ô (100px) → vùng giữa rỗng, tâm tại (300,300) trong toạ độ Board
	var spr := Sprite2D.new()
	spr.name = "CenterBackground"
	spr.texture = load(bg_path)
	spr.centered = true
	spr.position = Vector2(300, 300)
	spr.z_index = -10
	spr.modulate = Color(1, 1, 1, 0.30)
	var tex_size: Vector2 = spr.texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var target := 380.0
		var s: float = target / max(tex_size.x, tex_size.y)
		spr.scale = Vector2(s, s)
	board.add_child(spr)


# ════════════════════════════════════════════════════════════════════
# HỆ THỐNG LAYOUT RESPONSIVE
# Chia viewport thành các vùng và đặt mọi thành phần UI theo đó.
# Gọi lúc khởi tạo và mỗi khi cửa sổ đổi kích thước.
# ════════════════════════════════════════════════════════════════════
func _relayout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var sidebar_w: float = clamp(vp.x * 0.24, SIDEBAR_MIN, SIDEBAR_MAX)

	# --- Vùng: top bar (nút hướng dẫn + thanh trạng thái) ---
	if _btn_rules:
		_btn_rules.position = Vector2(MARGIN, MARGIN)
		_btn_rules.size = Vector2(150, TOPBAR_H - 2 * MARGIN + 16)
	if label:
		label.position = Vector2(MARGIN + 165, MARGIN)
		label.size = Vector2(vp.x - sidebar_w - MARGIN * 2 - 175, TOPBAR_H - 2 * MARGIN + 8)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# --- Vùng: sidebar bên phải (full height) ---
	if _pp_panel:
		_pp_panel.position = Vector2(vp.x - sidebar_w - MARGIN, MARGIN)
		_pp_panel.size = Vector2(sidebar_w, vp.y - 2 * MARGIN)

	# --- Vùng trung tâm dành cho bàn cờ: dùng GẦN HẾT chiều cao ---
	# Panel hành động là lớp nổi tạm thời (chỉ hiện khi tới ô), nên KHÔNG
	# chừa chỗ cố định cho nó nữa → bàn cờ to hết mức.
	var board_area := Rect2(
		MARGIN,
		TOPBAR_H,
		vp.x - sidebar_w - 2 * MARGIN,
		vp.y - TOPBAR_H - MARGIN
	)
	_fit_board(board_area)
	_position_dice(board_area)

	# --- Vùng: panel hành động (tự co theo số nút đang hiện, neo đáy, mọc lên) ---
	_place_action_popup()
	# Property popup: căn giữa vùng bàn cờ
	if prop_popup:
		var pw: float = min(440.0, board_area.size.x)
		var ph: float = min(400.0, board_area.size.y)
		prop_popup.offset_left = board_area.position.x + (board_area.size.x - pw) * 0.5
		prop_popup.offset_top = board_area.position.y + (board_area.size.y - ph) * 0.5
		prop_popup.offset_right = prop_popup.offset_left + pw
		prop_popup.offset_bottom = prop_popup.offset_top + ph
	# Event & auction panel: căn giữa vùng bàn cờ
	if _ev_panel:
		_ev_panel.position = board_area.position + (board_area.size - _ev_panel.size) * 0.5
	if _auction_panel:
		_auction_panel.position = board_area.position + (board_area.size - _auction_panel.size) * 0.5


# Co + căn giữa bàn cờ (Node2D) để vừa khít vùng cho trước
func _fit_board(area: Rect2) -> void:
	var board := get_node_or_null("../Board")
	if board == null:
		return
	# Bàn cờ vẽ trong vùng 600x600 (6 ô * 100px) ở toạ độ cục bộ.
	var board_px := 600.0
	var s: float = min(area.size.x, area.size.y) / board_px
	s = clamp(s, 0.1, 4.0)
	board.scale = Vector2(s, s)
	# Căn giữa vùng
	var board_size := board_px * s
	board.position = area.position + (area.size - Vector2(board_size, board_size)) * 0.5
	# Tắt auto-center cũ để không tranh chấp vị trí
	if "auto_center_in_editor" in board:
		board.auto_center_in_editor = false


# Đặt dice + nút quay vào giữa lòng bàn cờ (theo toạ độ màn hình của vùng board)
func _position_dice(area: Rect2) -> void:
	var cx := area.position.x + area.size.x * 0.5
	var cy := area.position.y + area.size.y * 0.5
	# Tỉ lệ theo độ lớn vùng board để dice/nút to lên cùng bàn cờ
	var k: float = clamp(min(area.size.x, area.size.y) / 600.0, 0.6, 3.0)
	if dice1_sprite:
		dice1_sprite.position = Vector2(cx - 70 * k, cy - 30 * k)
		dice1_sprite.scale = base_scale * k
	if dice2_sprite:
		dice2_sprite.position = Vector2(cx + 70 * k, cy - 30 * k)
		dice2_sprite.scale = base_scale * k
	_dice_scale = base_scale * k
	if roll_button:
		roll_button.offset_left = cx - 95 * k
		roll_button.offset_top = cy + 20 * k
		roll_button.offset_right = cx + 95 * k
		roll_button.offset_bottom = cy + 20 * k + 90 * k
	if double_label:
		double_label.offset_left = cx - 80
		double_label.offset_top = cy - 120 * k
		double_label.offset_right = cx + 80
		double_label.offset_bottom = cy - 120 * k + 40
		double_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Nút quay xúc xắc luôn nổi trên cùng và nhận được click
	if roll_button:
		roll_button.mouse_filter = Control.MOUSE_FILTER_STOP
		roll_button.move_to_front()
	if label == null:
		return


func _on_btn_rules_pressed() -> void:
	if _rules_popup and _rules_popup.has_method("show_rules"):
		_rules_popup.show_rules()


# Đặt panel hành động: rộng vừa phải, CAO TỰ ĐỘNG theo nội dung,
# neo ở đáy vùng board và mọc lên trên để không bao giờ cắt mất nút.
func _place_action_popup() -> void:
	if action_popup == null:
		return
	# Đợi 1 frame để VBox sắp xếp lại sau khi đổi ẩn/hiện nút → đo đúng chiều cao
	await get_tree().process_frame
	if action_popup == null or not is_instance_valid(action_popup):
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var sidebar_w: float = clamp(vp.x * 0.24, SIDEBAR_MIN, SIDEBAR_MAX)
	var center_w: float = vp.x - sidebar_w - 2 * MARGIN
	var action_w: float = clamp(center_w * 0.6, 320.0, 560.0)

	# Đo chiều cao tối thiểu thực tế của nội dung (các nút đang hiện)
	action_popup.reset_size()
	var content_h: float = action_popup.get_combined_minimum_size().y
	var max_h: float = vp.y - TOPBAR_H - 2 * MARGIN
	var desired_h: float = clamp(content_h, 120.0, max_h)

	var left: float = MARGIN + (center_w - action_w) * 0.5
	var bottom: float = vp.y - MARGIN
	var top: float = max(TOPBAR_H + MARGIN, bottom - desired_h)
	action_popup.offset_left = left
	action_popup.offset_top = top
	action_popup.offset_right = left + action_w
	action_popup.offset_bottom = bottom


func _apply_existing_panel_styles() -> void:
	# ActionPopup & PropertyPopup: nền kem, viền vàng theo phong cách D
	if action_popup:
		action_popup.add_theme_stylebox_override("panel",
			CoTyPhuPalette.panel_style(CoTyPhuPalette.CREAM, CoTyPhuPalette.GOLD, 16, 3))
	if prop_popup:
		prop_popup.add_theme_stylebox_override("panel",
			CoTyPhuPalette.panel_style(CoTyPhuPalette.CREAM, CoTyPhuPalette.BLUE, 16, 3))

	# Nút trong ActionPopup
	for b in [btn_buy, btn_build, btn_mortgage, btn_redeem, btn_sell_house, btn_sell]:
		if b:
			CoTyPhuPalette.style_button(b, CoTyPhuPalette.PANEL_BLUE, 12)
	# Nút mua nổi bật (xanh lá), nút kết thúc lượt ít nổi bật hơn (nhỏ + xám-đỏ nhạt)
	if btn_buy:
		CoTyPhuPalette.style_button(btn_buy, CoTyPhuPalette.GREEN, 14)
	if btn_close_action:
		CoTyPhuPalette.style_button(btn_close_action, Color("#9A6B66"), 11)
	if btn_pp_confirm:
		CoTyPhuPalette.style_button(btn_pp_confirm, CoTyPhuPalette.GREEN, 12)
	if btn_pp_cancel:
		CoTyPhuPalette.style_button(btn_pp_cancel, CoTyPhuPalette.RED, 12)
	if btn_open_manage:
		CoTyPhuPalette.style_button(btn_open_manage, CoTyPhuPalette.PANEL_BLUE_DK, 12)

	# Tiêu đề trong popup
	if popup_title:
		popup_title.add_theme_color_override("font_color", CoTyPhuPalette.TEXT_DARK)
		popup_title.add_theme_font_size_override("font_size", 20)

	# Tiêu đề ActionPopup → màu tối để đọc trên nền kem
	var act_title := action_popup.get_node_or_null("VBox/Title") if action_popup else null
	if act_title and act_title is Label:
		act_title.add_theme_color_override("font_color", CoTyPhuPalette.TEXT_DARK)
		act_title.add_theme_font_size_override("font_size", 18)

	# Thanh trạng thái: nền tối mờ + chữ trắng, dễ đọc trên mọi nền
	if label:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_font_size_override("font_size", 16)
		label.clip_text = true
		var lbl_bg := StyleBoxFlat.new()
		lbl_bg.bg_color = Color(0, 0, 0, 0.55)
		lbl_bg.set_corner_radius_all(8)
		lbl_bg.set_content_margin_all(6)
		label.add_theme_stylebox_override("normal", lbl_bg)


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


func prompt_auction(bidder: Player, prop_data: PropertyData, current_bid: int, min_bid: int, participants: Array, callback: Callable) -> void:
	# Đấu giá: mở phiên mới, tăng session id để timer cũ không còn hiệu lực
	_auction_session_id += 1
	var session_id := _auction_session_id

	_auc_callback = callback
	_auc_bidder_id = bidder.player_id

	call_deferred("_show_auction_panel")

	_auc_title.text = "Đấu giá: %s" % prop_data.cell_name
	_auc_desc.text = "%s - đến lượt: %s" % [prop_data.cell_name, bidder.name]
	_auc_current.text = "Giá hiện tại: $%d (tối thiểu $%d)" % [current_bid, min_bid]

	_auc_bid_input.text = str(max(min_bid, current_bid + 1))

	print("[GameUI] prompt_auction for %s, bidder=%s, current_bid=%d, min_bid=%d" % [prop_data.cell_name, bidder.name, current_bid, min_bid])

	for child in _auc_participants.get_children():
		child.queue_free()
	for p in participants:
		var lbl = Label.new()
		lbl.text = "%s — $%d" % [p.name, p.balance]
		_auc_participants.add_child(lbl)

	if _auc_btn_pass.pressed.is_connected(_on_auc_pass_pressed):
		_auc_btn_pass.pressed.disconnect(_on_auc_pass_pressed)
	_auc_btn_pass.pressed.connect(_on_auc_pass_pressed)

	if _auc_btn_bid.pressed.is_connected(_on_auc_bid_pressed):
		_auc_btn_bid.pressed.disconnect(_on_auc_bid_pressed)
	_auc_btn_bid.pressed.connect(_on_auc_bid_pressed)

	var timeout_seconds := 20.0
	call_deferred("_start_auc_timeout", timeout_seconds, session_id)


func _show_auction_panel() -> void:
	if _auction_panel == null:
		return
	print("[GameUI] _show_auction_panel called for bidder_id=%d" % _auc_bidder_id)
	_ev_overlay.visible = true
	_auction_panel.visible = true
	_auction_panel.move_to_front()


func _close_auction():
	# Hủy mọi timer đang chạy
	_auction_session_id += 1

	_ev_overlay.visible = false
	_auction_panel.visible = false

	_auc_bid_input.text = ""

	for child in _auc_participants.get_children():
		child.queue_free()

	_auc_callback = null
	_auc_bidder_id = -1


func _on_auc_pass_pressed() -> void:
	var cb = _auc_callback
	var bidder = _auc_bidder_id
	_close_auction()
	if cb and cb.is_valid():
		cb.call(bidder, 0, -1)


func _on_auc_bid_pressed() -> void:
	var bid_amount = int(_auc_bid_input.text)
	var cb = _auc_callback
	var bidder = _auc_bidder_id
	_close_auction()
	if cb and cb.is_valid():
		cb.call(bidder, 1, bid_amount)

func _start_auc_timeout(seconds: float, session_id: int) -> void:
	print("[AUC TIMER] started session=", session_id)

	await get_tree().create_timer(seconds).timeout

	print("[AUC TIMER] timeout session=", session_id)

	if session_id != _auction_session_id:
		print("[AUC TIMER] cancelled")
		return

	if not _auction_panel.visible:
		print("[AUC TIMER] panel hidden")
		return

	print("[AUC TIMER] auto pass")
	_on_auc_pass_pressed()


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
		card.custom_minimum_size = Vector2(192, 80)
		card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var pid: int = p["id"]
		var pc: Color = player_colors[pid % player_colors.size()]
		var cs = StyleBoxFlat.new()
		cs.bg_color = Color(pc.r * 0.32, pc.g * 0.32, pc.b * 0.32, 0.97)
		cs.border_width_left = 5
		cs.border_color = pc.lightened(0.15)
		cs.set_corner_radius_all(6)
		cs.content_margin_left   = 8
		cs.content_margin_right  = 6
		cs.content_margin_top    = 7
		cs.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", cs)

		var vb = VBoxContainer.new()
		vb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		vb.add_theme_constant_override("separation", 4)
		card.add_child(vb)

		var name_lbl = Label.new()
		var jail_tag = " 🔒" if p["in_jail"] else ""
		name_lbl.text = player_emojis[pid % player_emojis.size()] + " " + p["name"] + jail_tag
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", pc.lightened(0.45))
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
				pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				vb.add_child(pl)
		else:
			var no_p = Label.new()
			no_p.text = "  (chưa có đất)"
			no_p.add_theme_font_size_override("font_size", 12)
			no_p.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			vb.add_child(no_p)

		_pp_content.add_child(card)

# ════════════════════════════════════════════════════════════════════
# UC-6 Finance Panel – tạo và tích hợp FinancePanel vào sidebar
# ════════════════════════════════════════════════════════════════════
func _create_finance_panel() -> void:
	var ui_layer = get_node("UI")

	# Tạo FinancePanel
	_finance_panel = FinancePanelScript.new()
	var players: Array = []
	if game_controller:
		players = game_controller.get_players()
	_finance_panel.setup(ui_layer, players)

	# Nút mở Finance Panel trong sidebar (bên dưới nội dung player sidebar)
	_btn_finance = Button.new()
	_btn_finance.text = "💰 Tài chính"
	_btn_finance.custom_minimum_size = Vector2(0, 36)
	CoTyPhuPalette.style_button(_btn_finance, CoTyPhuPalette.GOLD, 13)
	_btn_finance.add_theme_color_override("font_color", Color("#1E1B18"))
	_btn_finance.pressed.connect(_on_btn_finance_pressed)

	# Thêm nút vào cuối sidebar (nếu _sidebar_vbox tồn tại)
	if _sidebar_vbox:
		_sidebar_vbox.add_child(HSeparator.new())
		_sidebar_vbox.add_child(_btn_finance)
	else:
		# Fallback: thêm trực tiếp vào UI layer ở góc trên trái sidebar
		ui_layer.add_child(_btn_finance)


func _on_btn_finance_pressed() -> void:
	if _finance_panel == null:
		return
	# Đồng bộ danh sách người chơi mới nhất từ GameController
	var players: Array = []
	if game_controller:
		players = game_controller.get_players()
	_finance_panel.open(players)


# Gọi từ GameController/FinanceManager để log giao dịch vào panel
func log_finance(action: String, player_name: String,
		amount: int, success: bool, note: String = "") -> void:
	if _finance_panel:
		_finance_panel.log_transaction(action, player_name, amount, success, note)
