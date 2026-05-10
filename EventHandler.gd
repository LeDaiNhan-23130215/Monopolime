extends Node
class_name EventHandler

signal event_finished

var game_controller: GameController

# ===========================
# Bộ thẻ CƠ HỘI (Chance)
# ===========================
var chance_cards = [
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
var community_chest_cards = [
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

var current_event_player: Player
var current_event_card: Dictionary

func _init(controller: GameController):
	game_controller = controller

# Trả về true nếu ô này là ô sự kiện và đã được xử lý
func handle_event(player: Player, cell: Cell) -> bool:
	if cell.cell_name in ["Cơ Hội", "Thẻ Cơ Hội", "Cơ hội"]:
		print("--- SỰ KIỆN: CƠ HỘI ---")
		trigger_card_event(player, "chance")
		return true
	elif cell.cell_name in ["Khí Vận", "Thẻ Khí Vận", "Khí vận", "Sự Kiện"]:
		print("--- SỰ KIỆN: KHÍ VẬN ---")
		trigger_card_event(player, "community")
		return true
	elif cell.cell_name in ["Vào Tù", "Vào tù"]:
		print("--- SỰ KIỆN: VÀO TÙ ---")
		handle_go_to_jail(player)
		return true
	elif cell.cell_name in ["Thuế", "Đóng Thuế", "Thuế thu nhập"]:
		print("--- SỰ KIỆN: ĐÓNG THUẾ ---")
		handle_tax(player, 200)
		return true
	return false

func trigger_card_event(player: Player, type: String):
	current_event_player = player

	var card_list = chance_cards if type == "chance" else community_chest_cards
	current_event_card = card_list[randi() % card_list.size()]

	var choices = []
	if current_event_card.type == "choice":
		choices = current_event_card.choices
	else:
		choices = ["✅ Xác nhận"]

	game_controller.ui.show_event_popup(
		current_event_card.title,
		current_event_card.desc,
		choices,
		self._on_event_choice_selected,
		type
	)

func _on_event_choice_selected(choice_index: int):
	match current_event_card.type:
		"reward":
			print("Sự kiện Nhận tiền: ", current_event_card.desc)
			game_controller.process_reward(current_event_player, current_event_card.amount)
			call_deferred("emit_signal", "event_finished")
		"penalty":
			print("Sự kiện Mất tiền: ", current_event_card.desc)
			game_controller.process_payment(current_event_player, null, current_event_card.amount, "Phạt sự kiện")
			call_deferred("emit_signal", "event_finished")
		"move":
			print("Sự kiện Di chuyển: ô ", current_event_card.target)
			# Tặng $200 nếu là di chuyển về ô 0
			if current_event_card.target == 0:
				game_controller.process_reward(current_event_player, 200)
			game_controller.move_player_to_position(current_event_player, current_event_card.target)
			call_deferred("emit_signal", "event_finished")
		"card":
			print("Sự kiện Thẻ đặc biệt: Ra Tù Miễn Phí")
			current_event_player.state.special_cards += 1
			call_deferred("emit_signal", "event_finished")
		"jail":
			print("Sự kiện Vào tù!")
			handle_go_to_jail(current_event_player)
		"choice":
			print("Sự kiện Lựa chọn: người chơi chọn ", choice_index)
			if choice_index == 0:
				game_controller.process_payment(current_event_player, null, 50, "Nộp phạt Cơ Hội")
				call_deferred("emit_signal", "event_finished")
			else:
				# Rút thẻ Khí Vận
				trigger_card_event(current_event_player, "community")

func handle_cell_after_move(player: Player, cell_index: int):
	game_controller.handle_landed_cell(player, cell_index)
	emit_signal("event_finished")

func handle_go_to_jail(player: Player):
	game_controller.go_to_jail(player)
	call_deferred("emit_signal", "event_finished")

func handle_tax(player: Player, amount: int):
	game_controller.process_payment(player, null, amount, "Đóng thuế")
	call_deferred("emit_signal", "event_finished")
