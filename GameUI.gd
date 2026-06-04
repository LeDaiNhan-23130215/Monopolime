extends Node
class_name GameUI

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")

signal setup_finished
signal card_dismissed
signal teleport_cell_selected(cell_index: int)

const SFX_BUY := "sfx_buy"
const SFX_PAY := "sfx_pay"
const SFX_REWARD := "sfx_reward"
const SFX_BUILD := "sfx_build"
const SFX_JAIL := "sfx_jail"
const SFX_CARD := "sfx_card"
const SFX_TELEPORT := "sfx_teleport"
const SFX_GAME_OVER := "sfx_game_over"

@onready var ui_layer: CanvasLayer = get_node("UI")
@onready var timer: Timer = get_node("UI/DiceTimer")
@onready var audio_roll: AudioStreamPlayer2D = get_node("UI/AudioRoll")
@onready var legacy_roll_button: TextureButton = get_node("UI/Roll Dice")
@onready var legacy_dice_1: Sprite2D = get_node("UI/Dice1")
@onready var legacy_dice_2: Sprite2D = get_node("UI/Dice2")
@onready var legacy_result: Label = get_node("UI/Result")
@onready var legacy_double_label: Label = get_node("UI/IsDoubleLabel")

var game_controller: GameController

var hud: Control
var setup_screen: Control
var buy_popup: Control
var rent_popup: Control
var event_popup: Control
var assets_popup: Control
var build_popup: Control
var rules_popup: Control
var game_over_screen: Control

var _rolling := false
var _resolving_roll := false
var _roll_ticks := 0
var _current_build_cell: Cell = null
var _pending_mortgage_player: Player = null
var _pending_mortgage_amount: int = 0

func _ready() -> void:
	_hide_legacy_nodes()
	_load_ui()

func _hide_legacy_nodes() -> void:
	for node in [legacy_roll_button, legacy_dice_1, legacy_dice_2, legacy_result, legacy_double_label]:
		if node:
			node.visible = false

func _load_ui() -> void:
	hud = preload("res://scenes/ui/MainGameHUD.tscn").instantiate()
	ui_layer.add_child(hud)
	hud.roll_pressed.connect(_on_roll_dice_pressed)
	hud.assets_pressed.connect(_on_open_assets_pressed)
	hud.build_pressed.connect(_on_open_build_pressed)
	hud.trade_pressed.connect(func(): show_message("Tính năng trao đổi sẽ dùng ở bản tiếp theo."))
	hud.rules_pressed.connect(_on_open_rules_pressed)
	hud.end_turn_pressed.connect(func():
		if game_controller:
			game_controller.end_turn()
	)

	buy_popup = preload("res://scenes/ui/popups/BuyPropertyPopup.tscn").instantiate()
	rent_popup = preload("res://scenes/ui/popups/RentPopup.tscn").instantiate()
	event_popup = preload("res://scenes/ui/popups/EventPopup.tscn").instantiate()
	assets_popup = preload("res://scenes/ui/popups/AssetsPopup.tscn").instantiate()
	build_popup = preload("res://scenes/ui/popups/BuildPopup.tscn").instantiate()
	rules_popup = preload("res://scenes/ui/popups/RulesPopup.tscn").instantiate()
	game_over_screen = preload("res://scenes/ui/GameOverScreen.tscn").instantiate()
	for popup in [buy_popup, rent_popup, event_popup, assets_popup, build_popup, rules_popup, game_over_screen]:
		ui_layer.add_child(popup)

	buy_popup.buy_selected.connect(func(accepted: bool):
		if game_controller:
			game_controller.emit_signal("buy_decision_made", accepted)
	)
	rent_popup.rent_confirmed.connect(func(): emit_signal("card_dismissed"))
	rent_popup.view_assets_requested.connect(_on_open_assets_pressed)
	event_popup.event_confirmed.connect(func(): emit_signal("card_dismissed"))
	build_popup.upgrade_selected.connect(func(cell: Cell):
		_current_build_cell = cell
		_on_build_yes()
	)
	build_popup.closed.connect(func():
		if game_controller:
			game_controller.emit_signal("build_decision_made")
	)
	game_over_screen.play_again_requested.connect(func():
		if game_controller:
			game_controller.restart_game()
		else:
			get_tree().reload_current_scene()
	)
	game_over_screen.main_menu_requested.connect(func():
		get_tree().reload_current_scene()
	)

# =========================
# Setup
# =========================

func show_setup_menu() -> void:
	if setup_screen and is_instance_valid(setup_screen):
		setup_screen.queue_free()
	setup_screen = preload("res://scenes/ui/SetupScreen.tscn").instantiate()
	ui_layer.add_child(setup_screen)
	setup_screen.start_requested.connect(_on_setup_start_requested)
	hud.visible = false

func _on_setup_start_requested(settings: Dictionary) -> void:
	if game_controller == null:
		return
	game_controller.game_state.players.clear()
	game_controller.game_state.current_player = 0
	game_controller.game_state.turn_number = 1
	game_controller.game_state.double_count = 0
	game_controller.game_state.max_turns = int(settings.get("max_turns", 40))
	game_controller.game_state.victory_mode = str(settings.get("victory_mode", "turn_limit"))

	var players: Array = settings.get("players", [])
	var starting_money := int(settings.get("starting_money", 1500))
	for i in range(players.size()):
		var data: Dictionary = players[i]
		var player: Player = game_controller.game_state.add_player(i, str(data.get("name", "Người chơi " + str(i + 1))), int(data.get("avatar_id", i)))
		player.state.balance = starting_money
		player.set_meta("is_ai", bool(data.get("is_ai", false)))
		player.set_meta("color_index", int(data.get("color_index", i)))

	setup_screen.queue_free()
	setup_screen = null
	hud.visible = true
	update_player_info(game_controller.game_state.players)
	emit_signal("setup_finished")

# =========================
# HUD
# =========================

func show_turn(player_index: int) -> void:
	if game_controller == null:
		return
	var player_name := "Người chơi " + str(player_index + 1)
	if player_index >= 0 and player_index < game_controller.game_state.players.size():
		player_name = game_controller.game_state.players[player_index].name
	hud.set_turn(game_controller.game_state.turn_number, player_name)

func show_message(text: String) -> void:
	var cleaned = _clean_text(text)
	hud.set_message(cleaned)

func add_history(text: String, color: Color = Color("#2E2A22")) -> void:
	if hud and hud.has_method("add_history_entry"):
		hud.add_history_entry(_clean_text(text), color)

func update_player_info(players: Array) -> void:
	var active: int = game_controller.game_state.current_player if game_controller else 0
	hud.update_players(players, active)

func set_roll_enabled(enabled: bool) -> void:
	hud.set_roll_enabled(enabled)

func show_result(result) -> void:
	var a := int(result.dice1)
	var b := int(result.dice2)
	hud.set_dice(a, b)

func show_double() -> void:
	show_message("Double! Bạn được thêm lượt.")

func show_jail() -> void:
	show_card_popup("Vào tù!", "Bạn bị đưa đến ô Nhà tù.", CoTyPhuTheme.RED, 0)

func start_dice_animation() -> void:
	if audio_roll:
		audio_roll.play()
	_rolling = true
	_roll_ticks = 0
	timer.start()

func _on_dice_timer_timeout() -> void:
	if not _rolling:
		return
	_roll_ticks += 1
	hud.set_dice(randi_range(1, 6), randi_range(1, 6))
	if _roll_ticks >= 8:
		_rolling = false
		timer.stop()
		if game_controller:
			_resolving_roll = true
			show_result(game_controller.final_result)
			await game_controller.resolve_roll()
			_resolving_roll = false

func _on_roll_dice_pressed() -> void:
	if game_controller:
		game_controller.roll_dice()

func _on_open_assets_pressed() -> void:
	if game_controller:
		show_property_manager(game_controller.get_current_player())


func request_mortgage(player: Player, amount_needed: int) -> void:
	# Show assets and let player trigger mortgage; when mortgage button pressed, delegate to GameController
	_current_build_cell = null
	show_property_manager(player)
	_pending_mortgage_player = player
	_pending_mortgage_amount = amount_needed
	# Connect once
	if assets_popup:
		assets_popup.mortgage_requested.connect(_on_assets_mortgage_requested)


func _on_assets_mortgage_requested() -> void:
	# Delegate mortgage handling to controller (will emit turn_action_completed when done)
	if game_controller and _pending_mortgage_player != null:
		game_controller.handle_mortgage_from_ui(_pending_mortgage_player, _pending_mortgage_amount)
	# Cleanup and hide popup
	if assets_popup:
		assets_popup.visible = false
		# disconnect if connected
		if assets_popup.mortgage_requested.is_connected(_on_assets_mortgage_requested):
			assets_popup.mortgage_requested.disconnect(_on_assets_mortgage_requested)
	_pending_mortgage_player = null
	_pending_mortgage_amount = 0

func _on_open_build_pressed() -> void:
	if game_controller:
		show_build_options(game_controller.get_current_player(), game_controller.get_current_player().properties)

func _on_open_rules_pressed() -> void:
	if rules_popup:
		rules_popup.show_rules()

# =========================
# Popups
# =========================

func show_buy_prompt(player: Player, cell: Cell) -> void:
	buy_popup.show_property(cell, player)

func show_transaction_popup(from_player: Player, to_player: Player, amount: int, reason: String):
	var cell := _cell_from_reason(reason)
	if cell:
		rent_popup.show_rent(from_player, to_player, cell, amount)
	else:
		show_card_popup("Trả tiền thuê", from_player.name + " trả $" + str(amount) + "\n" + reason, CoTyPhuTheme.ORANGE, -amount)
	await card_dismissed

func show_card_popup(title: String, text: String, color: Color, amount: int = 0) -> void:
	var icon := "gift"
	if color == CoTyPhuTheme.RED:
		icon = "tax"
	event_popup.show_event(_clean_text(title), _clean_text(text), amount, icon)

func show_card_and_wait(title: String, text: String, color: Color, amount: int = 0):
	show_card_popup(title, text, color, amount)
	await card_dismissed

func show_event_card_and_wait(deck_title: String, card: Dictionary, color: Color, amount: int = 0, deck_counts := {}):
	if event_popup.has_method("show_deck_card"):
		event_popup.show_deck_card(_clean_text(deck_title), card, color, amount, deck_counts)
	else:
		show_card_popup(deck_title, str(card.get("text", "")), color, amount)
	await card_dismissed

func show_toast_and_wait(title: String, text: String, color: Color, amount: int = 0, duration: float = 0.9):
	show_card_popup(title, text, color, amount)
	if duration > 0:
		await get_tree().create_timer(duration).timeout
	if event_popup.visible:
		event_popup.visible = false

func show_property_manager(player: Player) -> void:
	assets_popup.show_assets(player)

func show_assets(player: Player) -> void:
	show_property_manager(player)

func show_build_prompt(player: Player, cell: Cell) -> void:
	_current_build_cell = cell
	build_popup.show_build_options(player, [cell])

func show_build_options(player: Player, properties: Array) -> void:
	_current_build_cell = null
	build_popup.show_build_options(player, properties)

func _on_build_yes() -> void:
	if game_controller == null:
		return
	if _current_build_cell and _current_build_cell.can_build_house():
		game_controller.build_on_property(_current_build_cell.cell_owner, _current_build_cell)
	build_popup.visible = false
	game_controller.emit_signal("build_decision_made")

func _on_build_no() -> void:
	build_popup.visible = false
	if game_controller:
		game_controller.emit_signal("build_decision_made")

func show_game_over(winner: Player) -> void:
	var rankings := []
	if game_controller:
		rankings = game_controller.build_rankings()
	else:
		rankings = [{"player": winner, "net_worth": winner.state.balance}]
	show_game_over_with_rankings(winner, rankings)

func show_game_over_with_rankings(winner: Player, rankings: Array) -> void:
	hud.visible = false
	game_over_screen.show_rankings(winner, rankings)

func show_teleport_chooser(player: Player, board: Board) -> void:
	var popup := AcceptDialog.new()
	popup.title = "Du lịch"
	popup.dialog_text = player.name + " sẽ đi đến ô Du lịch kế tiếp."
	ui_layer.add_child(popup)
	popup.popup_centered()
	await popup.confirmed
	popup.queue_free()
	var target := 0
	for i in range(board.cells.size()):
		var cell: Cell = board.cells[i]
		if cell.cell_type == "teleport":
			target = i
			break
	emit_signal("teleport_cell_selected", target)

func play_sfx(_key: String) -> void:
	pass


func request_auction_bid(player: Player, min_bid: int, max_bid: int) -> int:
	# Styled auction popup consistent with other project popups
	var overlay := UIFactory.dim_overlay()
	if ui_layer:
		ui_layer.add_child(overlay)
	else:
		add_child(overlay)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("FFF8EC")
	panel_style.border_color = Color("57C6FF")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(18)
	panel_style.set_content_margin_all(14)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.custom_minimum_size = Vector2(640, 320)
	panel.size = panel.custom_minimum_size
	ui_layer.add_child(panel)
	# ensure overlay is removed when panel is closed
	if overlay and overlay.is_inside_tree():
		panel.connect("tree_exited", Callable(overlay, "queue_free"))

	# center the panel in the ui_layer
	var parent_size: Vector2 = Vector2(1280, 720)
	if get_viewport() != null:
		parent_size = get_viewport().get_visible_rect().size
	panel.position = (parent_size - panel.size) * 0.5

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	# Header
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(header)
	var title := UIFactory.label("Đấu giá: " + player.name, 28, CoTyPhuTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(44, 44)
	header.add_child(close_btn)

	# Info / instruction
	var info := Label.new()
	info.text = "Nhập giá (tối thiểu: $" + str(min_bid) + ", tối đa: $" + str(max_bid) + "). Nhập 0 để bỏ."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(info)

	# Input row
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)

	var le := LineEdit.new()
	le.text = str(min_bid)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.custom_minimum_size = Vector2(220, 48)
	row.add_child(le)

	var min_lbl := UIFactory.label("Min: $" + str(min_bid), 16, CoTyPhuTheme.TEXT_DARK)
	row.add_child(min_lbl)
	var max_lbl := UIFactory.label("Max: $" + str(max_bid), 16, CoTyPhuTheme.TEXT_DARK)
	row.add_child(max_lbl)

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 18)
	root.add_child(btn_row)

	var bid_btn := UIFactory.button("Đặt giá", CoTyPhuTheme.GREEN, Vector2(160, 56))
	var pass_btn := UIFactory.button("Bỏ", CoTyPhuTheme.BLUE, Vector2(120, 56))
	btn_row.add_child(bid_btn)
	btn_row.add_child(pass_btn)

	# Focus
	le.call_deferred("grab_focus")

	var chosen_bid := 0

	# Handlers
	bid_btn.pressed.connect(func():
		var text := le.text.strip_edges()
		if text == "":
			call_deferred("show_toast_and_wait", "Lỗi", "Giá không được để trống.", CoTyPhuTheme.RED, 0.9)
			return
		if not text.is_valid_int():
			call_deferred("show_toast_and_wait", "Lỗi", "Giá phải là số nguyên.", CoTyPhuTheme.RED, 0.9)
			return
		var n := int(text)
		if n == 0:
			chosen_bid = 0
		elif n < min_bid or n > max_bid:
			call_deferred("show_toast_and_wait", "Lỗi", "Giá phải từ $" + str(min_bid) + " đến $" + str(max_bid) + ".", CoTyPhuTheme.RED, 0.9)
			return
		else:
			chosen_bid = n
		panel.queue_free()
	)

	pass_btn.pressed.connect(func():
		chosen_bid = 0
		panel.queue_free()
	)

	close_btn.pressed.connect(func():
		chosen_bid = 0
		panel.queue_free()
	)

	# Wait for panel to be freed
	await panel.tree_exited
	return chosen_bid

func show_money_float(amount: int, from_node: Node = null, to_node: Node = null) -> void:
	var label := Label.new()
	var positive := amount >= 0
	label.text = ("+$" if positive else "-$") + str(abs(amount))
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", CoTyPhuTheme.TEXT_GREEN if positive else CoTyPhuTheme.RED)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(150, 44)
	ui_layer.add_child(label)

	var start := _screen_position_for(from_node, Vector2(640, 360))
	var end := _screen_position_for(to_node, start + Vector2(0, -76))
	if to_node == null:
		end = start + Vector2(0, -86)
	label.position = start - label.size * 0.5
	label.scale = Vector2(0.75, 0.75)
	label.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.12)
	tween.tween_property(label, "scale", Vector2(1.12, 1.12), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position", end - label.size * 0.5, 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(label.queue_free)


func _screen_position_for(node: Node, fallback: Vector2) -> Vector2:
	if node and node is CanvasItem and is_instance_valid(node):
		var item := node as CanvasItem
		return item.get_global_transform_with_canvas().origin
	return fallback

func show_insufficient_funds_options(player: Player, amount_needed: int):
	show_message(player.name + " thiếu $" + str(amount_needed) + ". Hãy quản lý tài sản để có thêm tiền.")
	show_property_manager(player)
	await get_tree().create_timer(0.6).timeout
	if game_controller:
		game_controller.emit_signal("turn_action_completed")

func _cell_from_reason(reason: String) -> Cell:
	if game_controller == null or game_controller.board == null:
		return null
	var marker := ": "
	var idx := reason.find(marker)
	if idx < 0:
		return null
	var name := reason.substr(idx + marker.length()).strip_edges()
	for cell: Cell in game_controller.board.cells:
		if cell.cell_name == name:
			return cell
	return null

func _clean_text(text: String) -> String:
	return text.replace("dang", "đang").replace("Den luot", "Đến lượt").replace("Tien thue", "Tiền thuê").replace("Nang cap", "Nâng cấp")
