extends Node
class_name EventHandler

signal event_finished

# Không type trực tiếp để tránh circular dependency
var game_controller = null

# ===========================
# Deck CƠ HỘI (Chance)
# ===========================
var chance_cards: Array = [
	{
		"type": "reward",
		"title": "🎴 Cơ Hội",
		"desc": "Trúng giải thưởng khu phố!\nBạn nhận được $150.",
		"amount": 150
	},
	{
		"type": "penalty",
		"title": "🎴 Cơ Hội",
		"desc": "Vi phạm luật giao thông!\nBạn bị phạt $50.",
		"amount": 50
	},
	{
		"type": "move",
		"title": "🎴 Cơ Hội",
		"desc": "Tiến thẳng đến ô Bắt Đầu!\nBạn nhận $200 khi đi qua.",
		"target": 0
	},
	{
		"type": "jail",
		"title": "🎴 Cơ Hội",
		"desc": "Vào tù ngay lập tức!\nKhông được đi qua ô Bắt Đầu."
	},
	{
		"type": "choice",
		"title": "🎴 Cơ Hội",
		"desc": "Bạn có thể:\n• Nộp phạt $50\n• Hoặc rút thẻ Khí Vận thử vận may!",
		"choices": [
			"💸 Nộp phạt $50",
			"🎁 Rút Khí Vận"
		]
	},
	{
		"type": "reward",
		"title": "🎴 Cơ Hội",
		"desc": "Cổ tức ngân hàng trả về!\nBạn nhận $100.",
		"amount": 100
	},
	{
		"type": "card",
		"title": "🎴 Cơ Hội",
		"desc": "Thẻ Ra Tù Miễn Phí!\nGiữ thẻ này, dùng bất cứ lúc nào."
	},
	{
		"type": "penalty",
		"title": "🎴 Cơ Hội",
		"desc": "Sửa chữa nhà cửa bắt buộc!\nBạn bị phạt $75.",
		"amount": 75
	},
	{
		"type": "reward",
		"title": "🎴 Cơ Hội",
		"desc": "Đầu tư chứng khoán có lãi!\nBạn nhận $120.",
		"amount": 120
	},
	{
		"type": "penalty",
		"title": "🎴 Cơ Hội",
		"desc": "Hóa đơn tiền điện tăng cao!\nBạn bị phạt $40.",
		"amount": 40
	},
	{
		"type": "move",
		"title": "🎴 Cơ Hội",
		"desc": "Vé tàu miễn phí!\nDi chuyển đến ô Bãi Đỗ Xe.",
		"target": 10
	},
	{
		"type": "jail",
		"title": "🎴 Cơ Hội",
		"desc": "Trốn vé bị phát hiện!\nVào tù ngay, không qua ô Bắt Đầu."
	},
	{
		"type": "card",
		"title": "🎴 Cơ Hội",
		"desc": "Thẻ Ra Tù Miễn Phí!\nGiữ thẻ này để dùng khi cần."
	},
	{
		"type": "choice",
		"title": "🎴 Cơ Hội",
		"desc": "Bạn có thể:\n• Nộp phạt $50\n• Hoặc rút thẻ Khí Vận thử vận may!",
		"choices": [
			"💸 Nộp phạt $50",
			"🎁 Rút Khí Vận"
		]
	},
	{
		"type": "reward",
		"title": "🎴 Cơ Hội",
		"desc": "Thắng giải xổ số!\nBạn nhận $250.",
		"amount": 250
	},
]

# ===========================
# Deck KHÍ VẬN
# ===========================
var community_chest_cards: Array = [
	{
		"type": "reward",
		"title": "🎁 Khí Vận",
		"desc": "Hoàn thuế thu nhập!\nChính phủ trả lại $200 cho bạn.",
		"amount": 200
	},
	{
		"type": "penalty",
		"title": "🎁 Khí Vận",
		"desc": "Đóng phí bảo hiểm y tế!\nBạn mất $50.",
		"amount": 50
	},
	{
		"type": "card",
		"title": "🎁 Khí Vận",
		"desc": "Thẻ Ra Tù Miễn Phí!\nGiữ thẻ này để thoát tù không tốn tiền."
	},
	{
		"type": "birthday",
		"title": "🎁 Khí Vận",
		"desc": "Sinh nhật của bạn!\nMỗi người chơi khác tặng bạn $50."
	},
	{
		"type": "move",
		"title": "🎁 Khí Vận",
		"desc": "Lệnh di chuyển đặc biệt!\nTiến đến ô Bắt Đầu và nhận $200.",
		"target": 0
	},
	{
		"type": "penalty",
		"title": "🎁 Khí Vận",
		"desc": "Phí đỗ xe quá hạn!\nBạn bị phạt $30.",
		"amount": 30
	},
	{
		"type": "reward",
		"title": "🎁 Khí Vận",
		"desc": "Đoạt giải đẹp trong cuộc thi!\nBạn nhận $100.",
		"amount": 100
	},
	{
		"type": "jail",
		"title": "🎁 Khí Vận",
		"desc": "Cảnh sát bắt bạn!\nVào tù ngay, không qua ô Bắt Đầu."
	},
	{
		"type": "reward",
		"title": "🎁 Khí Vận",
		"desc": "Thừa kế từ người thân!\nBạn nhận $200.",
		"amount": 200
	},
	{
		"type": "penalty",
		"title": "🎁 Khí Vận",
		"desc": "Học phí cho con!\nBạn phải đóng $80.",
		"amount": 80
	},
	{
		"type": "move",
		"title": "🎁 Khí Vận",
		"desc": "Chuyến công tác đột xuất!\nDi chuyển đến ô Thăm Tù.",
		"target": 5
	},
	{
		"type": "birthday",
		"title": "🎁 Khí Vận",
		"desc": "Kỷ niệm ngày cưới!\nMỗi người chơi khác tặng bạn $40."
	},
	{
		"type": "card",
		"title": "🎁 Khí Vận",
		"desc": "Thẻ Ra Tù Miễn Phí!\nGiữ thẻ này để thoát tù không tốn tiền."
	},
	{
		"type": "reward",
		"title": "🎁 Khí Vận",
		"desc": "Bán đồ cũ được giá!\nBạn nhận $75.",
		"amount": 75
	},
	{
		"type": "penalty",
		"title": "🎁 Khí Vận",
		"desc": "Quyên góp từ thiện!\nBạn ủng hộ $60.",
		"amount": 60
	},
]

# ===========================
# Runtime Data
# ===========================
var _current_player = null
var _current_card: Dictionary = {}

# Chống event chain vô hạn
var _event_depth := 0
const MAX_EVENT_CHAIN := 5

# ===========================
# Constructor
# ===========================
func _init(controller = null) -> void:
	game_controller = controller

# ===========================
# Handle Cell Event
# ===========================
func handle_event(player, cell) -> bool:
	if cell is ChanceCell:
		print("--- SỰ KIỆN: CƠ HỘI ---")
		trigger_card_event(player, "chance")
		return true

	elif cell is ChestCell:
		print("--- SỰ KIỆN: KHÍ VẬN ---")
		trigger_card_event(player, "community")
		return true

	return false

# ===========================
# Trigger Event
# ===========================
func trigger_card_event(player, card_type: String) -> void:
	if _event_depth >= MAX_EVENT_CHAIN:
		push_warning("Event chain exceeded limit!")
		call_deferred("emit_signal", "event_finished")
		return

	_event_depth += 1

	_current_player = player

	var card_list = (
		chance_cards
		if card_type == "chance"
		else community_chest_cards
	)

	_current_card = card_list[randi() % card_list.size()]

	var choices: Array = []

	if _current_card["type"] == "choice":
		choices = _current_card["choices"]
	else:
		choices = ["✅ Xác nhận"]

	game_controller.ui.show_event_popup(
		_current_card["title"],
		_current_card["desc"],
		choices,
		self._on_choice_selected,
		card_type
	)

# ===========================
# Handle Choice
# ===========================
func _on_choice_selected(choice_index: int) -> void:
	match _current_card["type"]:

		# ===================
		# Reward
		# ===================
		"reward":
			game_controller.process_reward(
				_current_player,
				_current_card["amount"]
			)

			_finish_event()

		# ===================
		# Penalty
		# ===================
		"penalty":
			game_controller.process_payment(
				_current_player,
				null,
				_current_card["amount"],
				"Phạt sự kiện"
			)

			_finish_event()

		# ===================
		# Move
		# ===================
		"move":
			if _current_card["target"] == 0:
				game_controller.process_reward(_current_player, 200)

			await game_controller.move_player_to_position(
				_current_player,
				_current_card["target"]
			)

			_finish_event()

		# ===================
		# Jail
		# ===================
		"jail":
			await game_controller.go_to_jail(_current_player)

			_finish_event()

		# ===================
		# Get Out Of Jail Card
		# ===================
		"card":
			print("Nhận Thẻ Ra Tù Miễn Phí!")

			if _current_player.state.has_method("add_jail_free_card"):
				_current_player.state.add_jail_free_card()
			else:
				if "get_out_of_jail_cards" in _current_player.state:
					_current_player.state.get_out_of_jail_cards += 1

			_finish_event()

		# ===================
		# Birthday
		# ===================
		"birthday":
			for p in game_controller.get_players():
				if p == _current_player:
					continue

				if p.state.bankrupt:
					continue

				game_controller.process_payment(
					p,
					_current_player,
					50,
					"Quà sinh nhật"
				)

			_finish_event()

		# ===================
		# Choice
		# ===================
		"choice":
			if choice_index == 0:

				game_controller.process_payment(
					_current_player,
					null,
					50,
					"Nộp phạt Cơ Hội"
				)

				_finish_event()

			else:
				call_deferred("_trigger_community_after_choice")

# ===========================
# Deferred Community Trigger
# ===========================
func _trigger_community_after_choice() -> void:
	trigger_card_event(_current_player, "community")

# ===========================
# Finish Event
# ===========================
func _finish_event() -> void:
	_event_depth = max(0, _event_depth - 1)
	call_deferred("emit_signal", "event_finished")
