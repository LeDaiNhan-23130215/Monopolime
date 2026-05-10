extends Node
class_name GameUI

signal buy_decision_made(want_to_buy: bool)

@onready var label = get_node("UI/Result")
@onready var timer = get_node("UI/DiceTimer")
@onready var double_label = get_node("UI/IsDoubleLabel")

@onready var dice1_sprite = get_node("UI/Dice1")
@onready var dice2_sprite = get_node("UI/Dice2")

@onready var audio_roll = get_node("UI/AudioRoll")

@onready var roll_button = get_node("UI/Roll Dice")

var dice_textures = [
	preload("res://resources/dices/dice1.jpg"),
	preload("res://resources/dices/dice2.jpg"),
	preload("res://resources/dices/dice3.jpg"),
	preload("res://resources/dices/dice4.jpg"),
	preload("res://resources/dices/dice5.jpg"),
	preload("res://resources/dices/dice6.jpg"),
]

var rolling := false
var roll_time := 0.0

var base_scale := Vector2.ONE

var game_controller: GameController

# --- EVENT UI VARS ---
var event_panel: Panel
var event_overlay: ColorRect
var event_icon: Label
var event_title: Label
var event_desc: Label
var event_buttons_container: HBoxContainer
var event_callback_callable: Callable
# ---------------------


func _ready():

	var target_size = 64.0

	var tex_size = dice1_sprite.texture.get_size().x

	var scale_factor = target_size / tex_size

	base_scale = Vector2.ONE * scale_factor

	dice1_sprite.scale = base_scale
	dice2_sprite.scale = base_scale

	_create_event_popup()


func _create_event_popup():
	# Overlay mờ nền khi popup hiện
	event_overlay = ColorRect.new()
	event_overlay.color = Color(0, 0, 0, 0.55)
	event_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	event_overlay.visible = false
	get_node("UI").add_child(event_overlay)
	
	event_panel = Panel.new()
	event_panel.set_size(Vector2(440, 340))
	event_panel.set_position(Vector2(300, 130))
	event_panel.visible = false
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.08, 0.06, 0.18, 0.97)
	stylebox.border_width_left = 3
	stylebox.border_width_top = 3
	stylebox.border_width_right = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = Color(0.6, 0.4, 1.0, 1)
	stylebox.corner_radius_top_left = 16
	stylebox.corner_radius_top_right = 16
	stylebox.corner_radius_bottom_left = 16
	stylebox.corner_radius_bottom_right = 16
	stylebox.shadow_color = Color(0, 0, 0, 0.5)
	stylebox.shadow_size = 12
	event_panel.add_theme_stylebox_override("panel", stylebox)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 24; vbox.offset_top = 18
	vbox.offset_right = -24; vbox.offset_bottom = -18
	vbox.add_theme_constant_override("separation", 10)
	event_panel.add_child(vbox)
	
	# Biểu tượng loại thẻ
	event_icon = Label.new()
	event_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_icon.add_theme_font_size_override("font_size", 40)
	vbox.add_child(event_icon)
	
	# Tiêu đề
	event_title = Label.new()
	event_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_title.add_theme_font_size_override("font_size", 22)
	event_title.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	vbox.add_child(event_title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Nội dung thẻ
	event_desc = Label.new()
	event_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_desc.add_theme_font_size_override("font_size", 16)
	event_desc.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85))
	vbox.add_child(event_desc)
	
	# Nút bấm
	event_buttons_container = HBoxContainer.new()
	event_buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	event_buttons_container.add_theme_constant_override("separation", 12)
	vbox.add_child(event_buttons_container)
	
	# Add trực tiếp, KHÔNG dùng call_deferred
	get_node("UI").add_child(event_panel)

# Hiển thị sự kiện với danh sách các nút lựa chọn
func show_event_popup(title: String, description: String, choices: Array, callback: Callable, card_type: String = ""):
	print("--- SHOW EVENT POPUP: ", title, " ---")
	event_callback_callable = callback
	
	# Cài icon + màu theo loại thẻ
	match card_type:
		"chance":
			event_icon.text = "🎴"
			event_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			var s = event_panel.get_theme_stylebox("panel").duplicate()
			s.border_color = Color(1.0, 0.75, 0.1, 1)
			event_panel.add_theme_stylebox_override("panel", s)
		"community":
			event_icon.text = "🎁"
			event_title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
			var s = event_panel.get_theme_stylebox("panel").duplicate()
			s.border_color = Color(0.2, 0.8, 1.0, 1)
			event_panel.add_theme_stylebox_override("panel", s)
		_:
			event_icon.text = "⚡"
	
	event_title.text = title
	event_desc.text = description
	
	for child in event_buttons_container.get_children():
		child.queue_free()
	
	for i in range(choices.size()):
		var btn = Button.new()
		btn.text = choices[i]
		btn.custom_minimum_size = Vector2(130, 44)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(self._on_event_button_pressed.bind(i))
		event_buttons_container.add_child(btn)
	
	if event_overlay:
		event_overlay.visible = true
	event_panel.visible = true
	event_panel.move_to_front()

func _on_event_button_pressed(choice_index: int):
	print("--- EVENT BUTTON PRESSED: ", choice_index, " ---")
	if event_overlay:
		event_overlay.visible = false
	event_panel.visible = false
	if event_callback_callable.is_valid():
		event_callback_callable.call(choice_index)


# =========================
# Player Status Panel
# =========================

var player_panel: Panel
var player_panel_content: VBoxContainer
var player_panel_rows: Array = []  # Array of VBoxContainer per player

func _create_player_panel():
	player_panel = Panel.new()
	player_panel.set_size(Vector2(195, 560))
	player_panel.set_position(Vector2(880, 20))
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.05, 0.05, 0.12, 0.92)
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.border_color = Color(0.4, 0.4, 0.8, 1)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	player_panel.add_theme_stylebox_override("panel", stylebox)
	
	var title = Label.new()
	title.text = "📊 Bảng Tài Sản"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	title.set_position(Vector2(0, 8))
	title.set_size(Vector2(195, 24))
	player_panel.add_child(title)
	
	player_panel_content = VBoxContainer.new()
	player_panel_content.set_position(Vector2(8, 38))
	player_panel_content.set_size(Vector2(179, 515))
	player_panel_content.add_theme_constant_override("separation", 10)
	player_panel.add_child(player_panel_content)
	
	get_node("UI").add_child(player_panel)

func refresh_player_panel(snapshot: Array):
	if player_panel == null:
		_create_player_panel()
	
	for child in player_panel_content.get_children():
		child.queue_free()
	
	var player_colors = [
		Color(0.3, 0.5, 1.0),
		Color(1.0, 0.35, 0.35),
		Color(0.2, 0.85, 0.4),
		Color(1.0, 0.85, 0.1)
	]
	var player_emojis = ["🔵", "🔴", "🟢", "🟡"]
	
	for p in snapshot:
		var card = Panel.new()
		card.custom_minimum_size = Vector2(179, 0)
		
		var card_style = StyleBoxFlat.new()
		var pc = player_colors[p["id"] % player_colors.size()]
		card_style.bg_color = Color(pc.r * 0.25, pc.g * 0.25, pc.b * 0.25, 0.9)
		card_style.border_width_left = 2
		card_style.border_color = pc
		card_style.corner_radius_top_left = 6
		card_style.corner_radius_top_right = 6
		card_style.corner_radius_bottom_left = 6
		card_style.corner_radius_bottom_right = 6
		card.add_theme_stylebox_override("panel", card_style)
		
		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.offset_left = 8
		vbox.offset_top = 6
		vbox.offset_right = -6
		vbox.offset_bottom = -6
		vbox.add_theme_constant_override("separation", 3)
		card.add_child(vbox)
		
		# Tên người chơi + trạng thái tù
		var name_row = Label.new()
		var jail_tag = " 🔒" if p["in_jail"] else ""
		name_row.text = player_emojis[p["id"] % player_emojis.size()] + " " + p["name"] + jail_tag
		name_row.add_theme_font_size_override("font_size", 13)
		name_row.add_theme_color_override("font_color", pc)
		vbox.add_child(name_row)
		
		# Số tiền
		var balance_row = Label.new()
		balance_row.text = "💰 $" + str(p["balance"])
		balance_row.add_theme_font_size_override("font_size", 12)
		balance_row.add_theme_color_override(
			"font_color",
			Color.LIME_GREEN if p["balance"] >= 200 else Color.TOMATO
		)
		vbox.add_child(balance_row)
		
		# Danh sách đất
		if p["properties"].size() > 0:
			var prop_title = Label.new()
			prop_title.text = "🏠 Bất động sản:"
			prop_title.add_theme_font_size_override("font_size", 10)
			prop_title.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
			vbox.add_child(prop_title)
			
			for prop_name in p["properties"]:
				var prop_label = Label.new()
				prop_label.text = "  • " + prop_name
				prop_label.add_theme_font_size_override("font_size", 10)
				prop_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
				prop_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				vbox.add_child(prop_label)
		else:
			var no_prop = Label.new()
			no_prop.text = "  (chưa có đất)"
			no_prop.add_theme_font_size_override("font_size", 10)
			no_prop.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			vbox.add_child(no_prop)
		
		player_panel_content.add_child(card)


# =========================
# Buy Property Popup
# =========================

var buy_panel: Panel
var buy_callback: Callable

func _ensure_buy_popup():
	if buy_panel != null:
		return
	
	buy_panel = Panel.new()
	buy_panel.set_size(Vector2(380, 240))
	buy_panel.set_position(Vector2(354, 186))
	buy_panel.visible = false
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.08, 0.15, 0.08, 0.96)
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color(0.3, 0.9, 0.3, 1)
	stylebox.corner_radius_top_left = 12
	stylebox.corner_radius_top_right = 12
	stylebox.corner_radius_bottom_left = 12
	stylebox.corner_radius_bottom_right = 12
	buy_panel.add_theme_stylebox_override("panel", stylebox)
	
	get_node("UI").add_child(buy_panel)

func show_buy_popup(cell_name: String, price: int, rent: int, player_balance: int):
	_ensure_buy_popup()
	buy_callback = Callable()
	
	# Xóa nội dung cũ
	for child in buy_panel.get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20; vbox.offset_top = 15
	vbox.offset_right = -20; vbox.offset_bottom = -15
	vbox.add_theme_constant_override("separation", 8)
	buy_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🏠 " + cell_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var info_price = Label.new()
	info_price.text = "💰 Giá mua: $" + str(price)
	info_price.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	vbox.add_child(info_price)
	
	var info_rent = Label.new()
	info_rent.text = "🏷 Tiền thuê: $" + str(rent) + " / lượt"
	info_rent.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(info_rent)
	
	var info_balance = Label.new()
	info_balance.text = "👛 Số dư hiện tại: $" + str(player_balance)
	var can_afford = player_balance >= price
	info_balance.add_theme_color_override("font_color", Color.LIME_GREEN if can_afford else Color.TOMATO)
	vbox.add_child(info_balance)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)
	
	var btn_buy = Button.new()
	btn_buy.text = "✅ Mua ($" + str(price) + ")"
	btn_buy.custom_minimum_size = Vector2(140, 44)
	btn_buy.disabled = not can_afford
	btn_buy.pressed.connect(func(): _on_buy_choice(true))
	hbox.add_child(btn_buy)
	
	var btn_skip = Button.new()
	btn_skip.text = "❌ Bỏ qua"
	btn_skip.custom_minimum_size = Vector2(100, 44)
	btn_skip.pressed.connect(func(): _on_buy_choice(false))
	hbox.add_child(btn_skip)
	
	buy_panel.visible = true
	buy_panel.move_to_front()
	print("--- SHOW BUY POPUP: ", cell_name, " $", price, " ---")

func _on_buy_choice(want_to_buy: bool):
	buy_panel.visible = false
	emit_signal("buy_decision_made", want_to_buy)


func show_turn(player_index):
	label.text = "Player %d's turn" % (player_index + 1)


func start_dice_animation():

	rolling = true
	roll_time = 0.0

	timer.start()

	audio_roll.play()

	shake()


func show_result(result):

	label.text = "Dice: %d + %d = %d" % [
		result.dice1,
		result.dice2,
		result.total()
	]

	audio_roll.stop()


func show_double():

	double_label.visible = true
	double_label.text = "DOUBLE!"

	await get_tree().create_timer(2.0).timeout

	double_label.visible = false


func update_position(player, pos):
	print("Player", player, "->", pos)


func show_jail():
	label.text = "GO TO JAIL!"


func _on_dice_timer_timeout():

	if not rolling:
		return

	roll_time += timer.wait_time

	var fake1 = randi_range(1, 6)
	var fake2 = randi_range(1, 6)

	dice1_sprite.texture = dice_textures[fake1 - 1]
	dice2_sprite.texture = dice_textures[fake2 - 1]

	dice1_sprite.rotation = randf_range(-0.3, 0.3)
	dice2_sprite.rotation = randf_range(-0.3, 0.3)

	bounce(dice1_sprite)
	bounce(dice2_sprite)

	if roll_time >= 0.7:

		timer.stop()

		rolling = false

		var result = game_controller.final_result

		dice1_sprite.texture = dice_textures[result.dice1 - 1]
		dice2_sprite.texture = dice_textures[result.dice2 - 1]

		dice1_sprite.rotation = 0
		dice2_sprite.rotation = 0

		await game_controller.resolve_roll()


func bounce(sprite):

	sprite.scale = base_scale

	var tween = create_tween()

	tween.tween_property(
		sprite,
		"scale",
		base_scale * 1.2,
		0.1
	)

	tween.tween_property(
		sprite,
		"scale",
		base_scale,
		0.1
	)


func shake():

	var cam = get_viewport().get_camera_2d()

	if cam == null:
		return

	for i in range(5):

		cam.offset = Vector2(
			randf_range(-5, 5),
			randf_range(-5, 5)
		)

		await get_tree().create_timer(0.03).timeout

	cam.offset = Vector2.ZERO


func _on_roll_dice_pressed() -> void:
	game_controller.roll_dice()


func set_roll_enabled(enabled: bool):
	roll_button.disabled = not enabled


# =========================
# Message
# =========================

func show_message(text: String):

	label.text = text

	print("[UI Message]: ", text)


# =========================
# Mortgage
# =========================

func request_mortgage(
	player: Player,
	amount_needed: int
):

	show_message(
		player.name
		+ " thiếu $"
		+ str(amount_needed)
		+ "! Cần thế chấp."
	)

	auto_mortgage_for_test(
		player,
		amount_needed
	)


func auto_mortgage_for_test(
	player: Player,
	amount_needed: int
):

	print(
		"--- [Auto Test] Đang tự động bán đất cho ",
		player.name,
		" ---"
	)

	var target_balance = (
		player.state.balance + amount_needed
	)

	for cell in player.properties:

		if (
			not cell.is_mortgaged
			and player.state.balance < target_balance
		):

			var amount = cell.mortgage_property()

			print(
				"> Tự động thế chấp: ",
				cell.cell_name,
				" lấy $",
				amount
			)

	await get_tree().create_timer(1.5).timeout

	print("Đã xoay đủ tiền, tiếp tục game!")

	game_controller.emit_signal(
		"turn_action_completed"
	)
