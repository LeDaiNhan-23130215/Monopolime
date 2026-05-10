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

# ─── Nút quản lý tài sản luôn hiện (chủ động, bất kỳ lúc nào) ───────
# Đây là nút RIÊNG, luôn hiển thị khi đến lượt người chơi
# Khác với asset_panel (chỉ hiện khi đứng trên ô đặc biệt)
@onready var btn_open_manage  : Button         = get_node("UI/BtnOpenManage")

# ─── UC7 panels ──────────────────────────────────────────────────────
@onready var asset_panel      : PanelContainer = get_node("UI/AssetPanel")
@onready var btn_manage       : Button         = get_node("UI/AssetPanel/BtnManage")

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
@onready var btn_pp_confirm   : Button         = get_node("UI/PropertyPopup/VBox/BtnConfirm")
@onready var btn_pp_cancel    : Button         = get_node("UI/PropertyPopup/VBox/BtnCancel")

@onready var trade_popup       : PanelContainer = get_node("UI/TradePopup")
@onready var trade_title       : Label          = get_node("UI/TradePopup/VBox/Title")
@onready var trade_player_list : OptionButton   = get_node("UI/TradePopup/VBox/PlayerList")
@onready var trade_price_input : SpinBox        = get_node("UI/TradePopup/VBox/PriceInput")
@onready var btn_td_confirm    : Button         = get_node("UI/TradePopup/VBox/BtnConfirm")
@onready var btn_td_cancel     : Button         = get_node("UI/TradePopup/VBox/BtnCancel")

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
# _ready – connect signals cần thiết trong code
# ═════════════════════════════════════════════════════════════════════
func _ready() -> void:
	var tex_size     : float = dice1_sprite.texture.get_size().x
	var scale_factor : float = 64.0 / tex_size
	base_scale = Vector2.ONE * scale_factor
	dice1_sprite.scale = base_scale
	dice2_sprite.scale = base_scale

	asset_panel.visible  = false
	action_popup.visible = false
	prop_popup.visible   = false
	trade_popup.visible  = false

	# Connect ItemList signal trong code để chắc chắn (tránh bug scene chưa connect)
	if not prop_list.item_selected.is_connected(_on_property_list_item_selected):
		prop_list.item_selected.connect(_on_property_list_item_selected)

	# Nút quản lý chủ động: ẩn ban đầu, chỉ hiện khi đến lượt
	if btn_open_manage:
		btn_open_manage.visible = false
		if not btn_open_manage.pressed.is_connected(_on_btn_open_manage_pressed):
			btn_open_manage.pressed.connect(_on_btn_open_manage_pressed)


# ═════════════════════════════════════════════════════════════════════
# DICE
# ═════════════════════════════════════════════════════════════════════
func show_turn(player_index: int) -> void:
	label.text = "Lượt của Player %d" % (player_index + 1)
	# Hiện nút quản lý chủ động (BR-16: trong tù vẫn quản lý được)
	if btn_open_manage:
		btn_open_manage.text    = "⚙ Quản lý tài sản (Player %d)" % (player_index + 1)
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
	# Khi lượt kết thúc (enabled=true = lượt tiếp theo bắt đầu),
	# ẩn nút quản lý của lượt cũ
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
	_show_manage_btn()
	_open_action_menu()

# Gọi khi đáp xuống đất của mình (bắt buộc xử lý)
func show_asset_management(player: Player, am: AssetManager) -> void:
	_player    = player
	_am        = am
	_buy_cell  = null
	_mandatory = true
	_show_manage_btn()

# Gọi khi người chơi chủ động bấm nút "Quản lý tài sản" (tự nguyện)
func _on_btn_open_manage_pressed() -> void:
	var player = game_controller.get_current_player()
	if player == null or player.is_bankrupt():
		return
	_player    = player
	_am        = game_controller.asset_manager
	_buy_cell  = null
	_mandatory = false   # KHÔNG emit signal khi đóng
	_show_manage_btn()
	_open_action_menu()

func _show_manage_btn() -> void:
	btn_manage.text     = "%s – Quản lý tài sản" % _player.name
	asset_panel.visible = true

func _on_btn_manage_pressed() -> void:
	_open_action_menu()

func hide_manage_button() -> void:
	asset_panel.visible  = false
	action_popup.visible = false
	prop_popup.visible   = false
	trade_popup.visible  = false

# Gọi khi người chơi hoàn thành (hoặc đóng) tất cả popup UC7
func _done_with_action() -> void:
	_player   = null
	_am       = null
	_buy_cell = null
	_cell     = null
	_action   = ""
	hide_manage_button()
	if _mandatory:
		_mandatory = false
		emit_signal("ui_action_done")   # GameController đang await cái này

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
	action_popup.visible = true

func _on_btn_close_action_pressed() -> void:
	action_popup.visible = false
	if _mandatory:
		# Landing mandatory: đóng = từ chối hành động, vẫn phải end turn
		_done_with_action()
	else:
		# Chủ động: đóng = chỉ tắt popup, giữ nút "Quản lý tài sản" vẫn hiện
		_player   = null
		_am       = null
		_buy_cell = null
		_cell     = null
		_action   = ""
		asset_panel.visible = false
		# KHÔNG gọi _done_with_action() vì không có signal cần emit


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
		_done_with_action()
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
			prop_list.add_item(info)
			prop_list.set_item_metadata(prop_list.item_count - 1, c)
	prop_popup.visible = true

# Signal connect trong _ready() để đảm bảo luôn hoạt động
func _on_property_list_item_selected(index: int) -> void:
	_cell = prop_list.get_item_metadata(index)
	if btn_pp_confirm:
		btn_pp_confirm.disabled = false

func _on_btn_pp_cancel_pressed() -> void:
	prop_popup.visible = false
	_action = ""
	_done_with_action()

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
			_action = "sell"   # khôi phục để _open_trade_popup biết
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
		_done_with_action()
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

func _on_btn_td_cancel_pressed() -> void:
	trade_popup.visible = false
	_done_with_action()


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
	_show_manage_btn()
	btn_buy.visible      = false
	btn_build.visible    = false
	btn_redeem.visible   = false
	btn_trade.visible    = false
	btn_mortgage.visible = true
	btn_sell.visible     = true
	action_popup.visible = true
	
	# =====================================================================
# [MỚI] GIAO DIỆN PHÁ SẢN (Dành cho AF7.8)
# =====================================================================
func show_bankruptcy_alert(debtor: Player, creditor: Player):
	# 1. Tạo lớp nền đen mờ bao phủ toàn màn hình
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85) # Đen mờ 85% để tăng sự u ám
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 5000 # Đảm bảo nằm trên cùng mọi popup khác
	add_child(overlay)
	
	# 2. Tạo cái bảng (Panel) ở giữa
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(500, 300)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	overlay.add_child(panel)
	
	# 3. Tiêu đề "PHÁ SẢN!"
	var title = Label.new()
	title.text = "⚠ PHÁ SẢN! ⚠"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 30
	panel.add_child(title)
	
	# 4. Nội dung chi tiết
	var msg = Label.new()
	if creditor != null:
		msg.text = "%s đã cạn kiệt tài chính!\n\nToàn bộ tài sản và tiền mặt\nđược bàn giao cho %s." % [debtor.name, creditor.name]
	else:
		msg.text = "%s đã phá sản do nợ Ngân hàng!\n\nToàn bộ tài sản đã bị thu hồi." % [debtor.name]
		
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 20)
	msg.set_anchors_preset(Control.PRESET_CENTER)
	panel.add_child(msg)
	
	# 5. Nút Bấm Xác nhận
	var btn = Button.new()
	btn.text = "Chấp nhận thất bại"
	btn.custom_minimum_size = Vector2(200, 50)
	btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	btn.position.y = -40
	panel.add_child(btn)
	
	# Hiệu ứng xuất hiện nhẹ nhàng (Tween)
	panel.scale = Vector2.ZERO
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.5)
	
	# 6. Khi bấm nút: Xóa bảng và báo GameController tiếp tục
	btn.pressed.connect(func():
		overlay.queue_free()
		emit_signal("ui_action_done") 
	)
