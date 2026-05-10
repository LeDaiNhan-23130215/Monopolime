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
@onready var btn_sell         : Button         = get_node("UI/ActionPopup/VBox/BtnSell")
@onready var btn_trade        : Button         = get_node("UI/ActionPopup/VBox/BtnTrade")
@onready var btn_close_action : Button         = get_node("UI/ActionPopup/VBox/BtnClose")

@onready var prop_popup       : PanelContainer = get_node("UI/PropertyPopup")
@onready var popup_title      : Label          = get_node("UI/PropertyPopup/VBox/Title")
@onready var prop_list        : ItemList       = get_node("UI/PropertyPopup/VBox/PropertyList")
@onready var btn_pp_confirm   : Button         = get_node("UI/PropertyPopup/VBox/HBox/BtnConfirm")
@onready var btn_pp_cancel    : Button         = get_node("UI/PropertyPopup/VBox/HBox/BtnCancel")

@onready var trade_popup       : PanelContainer = get_node("UI/TradePopup")
@onready var trade_title       : Label          = get_node("UI/TradePopup/VBox/Title")
@onready var trade_player_list : OptionButton   = get_node("UI/TradePopup/VBox/PlayerList")
@onready var trade_price_input : SpinBox        = get_node("UI/TradePopup/VBox/PriceInput")
@onready var btn_td_confirm    : Button         = get_node("UI/TradePopup/VBox/HBox/BtnConfirm")
@onready var btn_td_cancel     : Button         = get_node("UI/TradePopup/VBox/HBox/BtnCancel")

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


# ═════════════════════════════════════════════════════════════════════
# _ready
# ═════════════════════════════════════════════════════════════════════
func _ready() -> void:
	var tex_size     : float = dice1_sprite.texture.get_size().x
	var scale_factor : float = 64.0 / tex_size
	base_scale = Vector2.ONE * scale_factor
	dice1_sprite.scale = base_scale
	dice2_sprite.scale = base_scale

	action_popup.visible = false
	prop_popup.visible   = false
	trade_popup.visible  = false

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
	label.text = "Lượt của Player %d" % (player_index + 1)
	# FIX: Luôn hiện nút quản lý tài sản khi đến lượt (bất kỳ ô nào - BR-16)
	if btn_open_manage:
		btn_open_manage.text    = "⚙ Quản lý tài sản (P%d)" % (player_index + 1)
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

func _on_roll_dice_pressed() -> void:
	game_controller.roll_dice()

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
func prompt_buy_or_auction(player: Player, cell: PropertyCell, am: AssetManager) -> void:
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


# Hiển thị thông báo (Đi qua GO, thưởng, phạt...)
func show_message(text: String):
	label.text = text
	print("[UI Message]: ", text)

# Yêu cầu thế chấp khi không đủ tiền
func request_mortgage(player: Player, amount_needed: int):
	show_message(player.name + " thiếu $" + str(amount_needed) + "! Cần thế chấp.")
	
	# === LOGIC GIẢ LẬP ĐỂ TEST GAME KHÔNG BỊ KẸT MÀN HÌNH ===
	auto_mortgage_for_test(player, amount_needed)

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
	trade_popup.visible  = false

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

	for c in _player.properties:
		if c is PropertyCell:
			has_props = true
			if c.is_mortgaged:
				has_mortgage = true
			if not c.is_mortgaged and not c.has_hotel:
				if PropertyController.can_build_on(c, _player, all_cells):
					can_build = true

	btn_buy.visible      = (_buy_cell != null)
	btn_build.visible    = can_build
	btn_mortgage.visible = has_props
	btn_redeem.visible   = has_mortgage
	btn_sell.visible     = has_props
	btn_trade.visible    = true

	# FIX: Text nút phân theo chế độ
	if btn_close_action:
		btn_close_action.text = "Kết thúc lượt" if _mandatory else "Đóng"

	# FIX: Đóng popup con trước khi hiện ActionPopup
	prop_popup.visible   = false
	trade_popup.visible  = false
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
		show_message("Không đủ tiền! Tiến hành đấu giá...")
		_am.auction_property(_buy_cell, game_controller.game_state.players)
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

func _on_btn_sell_pressed() -> void:
	action_popup.visible = false
	_action = "sell"
	var eligible: Array = []
	for c in _player.properties:
		if c is PropertyCell and not c.is_mortgaged:
			eligible.append(c)
	_open_prop_popup("Chọn ô muốn bán", eligible)

func _on_btn_trade_pressed() -> void:
	action_popup.visible = false
	_action = "trade"
	var eligible: Array = []
	for c in _player.properties:
		if c is PropertyCell:
			eligible.append(c)
	_open_prop_popup("Chọn ô bạn muốn đưa ra trao đổi", eligible)


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
		"sell":
			_action = "sell"
			_open_trade_popup()
		"trade":
			_action = "trade"
			_open_trade_popup()


# ═════════════════════════════════════════════════════════════════════
# TRADE POPUP
# ═════════════════════════════════════════════════════════════════════
func _open_trade_popup() -> void:
	trade_title.text = ("Bán \"%s\" cho ai?" if _action == "sell" else "Trao đổi \"%s\" với ai?") % _cell.data.cell_name
	trade_player_list.clear()
	for p in game_controller.game_state.players:
		if p != _player and not p.is_bankrupt():
			trade_player_list.add_item("%s ($%d)" % [p.name, p.state.balance])
			trade_player_list.set_item_metadata(trade_player_list.item_count - 1, p)
	if trade_player_list.item_count == 0:
		show_message("Không có người chơi giao dịch!")
		# FIX: Quay lại ActionPopup thay vì đóng hẳn
		_open_action_menu()
		return
	trade_popup.visible = true

func _on_btn_td_confirm_pressed() -> void:
	trade_popup.visible = false
	var target : Player = trade_player_list.get_item_metadata(trade_player_list.selected)
	var price  : int    = int(trade_price_input.value)

	var msg = ""
	if _action == "sell":
		msg = "[%s] đề xuất bán \"%s\" giá $%d. Đồng ý?" % [_player.name, _cell.data.cell_name, price]
	else:
		msg = "[%s] đề xuất trao đổi \"%s\" + $%d. Đồng ý?" % [_player.name, _cell.data.cell_name, price]

	var ok = await _confirm_from_receiver_v2(target, msg)
	if ok:
		var result = false
		if _action == "sell":
			result = _am.sell_property(_player, target, _cell, price)
		else:
			result = _am.trade_property(_player, target, [_cell], price, [], 0)
		show_message("Giao dịch thành công!" if result else "Giao dịch thất bại!")
	else:
		show_message("Đối phương từ chối.")

	_done_with_action()

# FIX: Hủy trong TradePopup → quay lại ActionPopup (không đóng hẳn)
func _on_btn_td_cancel_pressed() -> void:
	trade_popup.visible = false
	_action = ""
	_cell   = null
	_open_action_menu()


# ═════════════════════════════════════════════════════════════════════
# DIALOG HELPER
# ═════════════════════════════════════════════════════════════════════
func _confirm_from_receiver_v2(receiver: Player, message: String) -> bool:
	var dialog = ConfirmationDialog.new()
	dialog.title       = "Xác nhận – " + receiver.name
	dialog.dialog_text = message
	dialog.get_ok_button().text     = "Đồng ý"
	dialog.get_cancel_button().text = "Từ chối"
	add_child(dialog)

	var accepted := false
	var waiting  := true
	dialog.confirmed.connect(func(): accepted = true;  waiting = false)
	dialog.canceled.connect( func(): accepted = false; waiting = false)
	dialog.popup_centered()

	while waiting:
		await get_tree().process_frame

	dialog.queue_free()
	return accepted


# ═════════════════════════════════════════════════════════════════════
# REQUEST MORTGAGE (khi thiếu tiền trả thuê – AF7.7)
# ═════════════════════════════════════════════════════════════════════
func request_mortgage(player: Player, amount_needed: int) -> void:
	_player    = player
	_am        = game_controller.asset_manager
	_mandatory = true
	show_message("%s thiếu $%d! Hãy thế chấp hoặc bán." % [player.name, amount_needed])
	btn_buy.visible      = false
	btn_build.visible    = false
	btn_redeem.visible   = false
	btn_trade.visible    = false
	btn_mortgage.visible = true
	btn_sell.visible     = true
	action_popup.visible = true
