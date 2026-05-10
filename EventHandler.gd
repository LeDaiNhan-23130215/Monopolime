extends Node
class_name EventHandler

signal event_finished

var game_controller: GameController

# ===========================
# Bộ thẻ CƠ HỘI (Chance)
# ===========================
var chance_cards: Array = [
	{
		"type": "reward", "title": "🎴 Cơ Hội",
		"desc": "Trúng giải thưởng khu phố!\nBạn nhận được $150.",
		"amount": 150
	},
	{
		"type": "penalty", "title": "🎴 Cơ Hội",
		"desc": "Vi phạm luật giao thông!\nBạn bị phạt $50.",
		"amount": 50
	},
	{
		"type": "move", "title": "🎴 Cơ Hội",
		"desc": "Tiến thẳng đến ô Bắt Đầu!\nBạn nhận $200 khi đi qua.",
		"target": 0
	},
	{
		"type": "jail", "title": "🎴 Cơ Hội",
		"desc": "Vào tù ngay lập tức!\nKhông được đi qua ô Bắt Đầu.",
		"amount": 0
	},
	{
		"type": "choice", "title": "🎴 Cơ Hội",
		"desc": "Bạn có thể:\n• Nộp phạt $50\n• Hoặc rút thẻ Khí Vận thử vận may!",
		"choices": ["💸 Nộp phạt $50", "🎁 Rút Khí Vận"]
	},
	{
		"type": "reward", "title": "🎴 Cơ Hội",
		"desc": "Cổ tức ngân hàng trả về!\nBạn nhận $100.",
		"amount": 100
	},
	{
		"type": "card", "title": "🎴 Cơ Hội",
		"desc": "Thẻ Ra Tù Miễn Phí!\nGiữ thẻ này, dùng bất cứ lúc nào.",
		"amount": 0
	},
	{
		"type": "penalty", "title": "🎴 Cơ Hội",
		"desc": "Sửa chữa nhà cửa bắt buộc!\nMỗi ngôi nhà phải trả $25.",
		"amount": 75
	},
]

# ===========================
# Bộ thẻ KHÍ VẬN (Community Chest)
# ===========================
var community_chest_cards: Array = [
	{
		"type": "reward", "title": "🎁 Khí Vận",
		"desc": "Hoàn thuế thu nhập!\nChính phủ trả lại $200 cho bạn.",
		"amount": 200
	},
	{
		"type": "penalty", "title": "🎁 Khí Vận",
		"desc": "Đóng phí bảo hiểm y tế!\nBạn mất $50.",
		"amount": 50
	},
	{
		"type": "card", "title": "🎁 Khí Vận",
		"desc": "Thẻ Ra Tù Miễn Phí!\nGiữ thẻ này để thoát tù không tốn tiền.",
		"amount": 0
	},
	{
		"type": "reward", "title": "🎁 Khí Vận",
		"desc": "Sinh nhật của bạn!\nMỗi người chơi khác tặng bạn $50.",
		"amount": 100
	},
	{
		"type": "move", "title": "🎁 Khí Vận",
		"desc": "Lệnh di chuyển đặc biệt!\nTiến đến ô Bắt Đầu và nhận $200.",
		"target": 0
	},
	{
		"type": "penalty", "title": "🎁 Khí Vận",
		"desc": "Phí đỗ xe quá hạn!\nBạn bị phạt $30.",
		"amount": 30
	},
	{
		"type": "reward", "title": "🎁 Khí Vận",
		"desc": "Đoạt giải đẹp trong cuộc thi!\nBạn nhận $100.",
		"amount": 100
	},
	{
		"type": "jail", "title": "🎁 Khí Vận",
		"desc": "Cảnh sát bắt bạn!\nVào tù ngay, không qua ô Bắt Đầu.",
		"amount": 0
	},
]

var _current_player: Player
var _current_card: Dictionary

func _init(controller: GameController) -> void:
	game_controller = controller

# Trả về true nếu ô là sự kiện và đã bắt đầu xử lý
func handle_event(player: Player, cell: Cell) -> bool:
	if cell is ChanceCell:
		print("--- SỰ KIỆN: CƠ HỘI ---")
		trigger_card_event(player, "chance")
		return true
	elif cell is ChestCell:
		print("--- SỰ KIỆN: KHÍ VẬN ---")
		trigger_card_event(player, "community")
		return true
	return false

func trigger_card_event(player: Player, card_type: String) -> void:
	_current_player = player

	var card_list = chance_cards if card_type == "chance" else community_chest_cards
	_current_card = card_list[randi() % card_list.size()]

	var choices: Array = []
	if _current_card.type == "choice":
		choices = _current_card.choices
	else:
		choices = ["✅ Xác nhận"]

	game_controller.ui.show_event_popup(
		_current_card.title,
		_current_card.desc,
		choices,
		self._on_choice_selected,
		card_type
	)

func _on_choice_selected(choice_index: int) -> void:
	match _current_card.type:
		"reward":
			game_controller.process_reward(_current_player, _current_card.amount)
			call_deferred("emit_signal", "event_finished")

		"penalty":
			game_controller.process_payment(_current_player, null, _current_card.amount, "Phạt sự kiện")
			call_deferred("emit_signal", "event_finished")

		"move":
			if _current_card.target == 0:
				game_controller.process_reward(_current_player, 200)
			await game_controller.move_player_to_position(_current_player, _current_card.target)
			call_deferred("emit_signal", "event_finished")

		"card":
			print("Nhận Thẻ Ra Tù Miễn Phí!")
			call_deferred("emit_signal", "event_finished")

		"jail":
			await game_controller.go_to_jail(_current_player)
			call_deferred("emit_signal", "event_finished")

		"choice":
			if choice_index == 0:
				game_controller.process_payment(_current_player, null, 50, "Nộp phạt Cơ Hội")
				call_deferred("emit_signal", "event_finished")
			else:
				# Rút thẻ Khí Vận
				trigger_card_event(_current_player, "community")
