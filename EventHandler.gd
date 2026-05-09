extends Node
class_name EventHandler

signal event_finished

var game_controller: GameController

# =========================
# Danh sách thẻ Cơ Hội
# =========================
var chance_cards = [
	{"text": "Ngân hàng trả cổ tức! Nhận $50", "action": "gain", "amount": 50},
	{"text": "Bạn thắng cuộc thi! Nhận $100", "action": "gain", "amount": 100},
	{"text": "Bảo hiểm đáo hạn! Nhận $150", "action": "gain", "amount": 150},
	{"text": "Bạn bị phạt vượt đèn đỏ! Nộp $50", "action": "lose", "amount": 50},
	{"text": "Sửa chữa nhà cửa! Nộp $100", "action": "lose", "amount": 100},
	{"text": "Tiến đến ô GO! Nhận $200", "action": "move_to", "position": 0},
	{"text": "Đi thẳng vào Tù! Không qua GO!", "action": "go_jail"},
	{"text": "Lùi 3 bước!", "action": "move_back", "steps": 3},
	{"text": "Nhận thẻ Ra Tù Miễn Phí!", "action": "get_card"},
	{"text": "Sinh nhật bạn! Mỗi người chơi trả bạn $25", "action": "birthday", "amount": 25},
]

# =========================
# Danh sách thẻ Khí Vận
# =========================
var community_cards = [
	{"text": "Kế thừa di sản! Nhận $200", "action": "gain", "amount": 200},
	{"text": "Hoàn thuế! Nhận $75", "action": "gain", "amount": 75},
	{"text": "Bán cổ phiếu! Nhận $45", "action": "gain", "amount": 45},
	{"text": "Chi phí bệnh viện! Nộp $100", "action": "lose", "amount": 100},
	{"text": "Phí luật sư! Nộp $50", "action": "lose", "amount": 50},
	{"text": "Đi thẳng vào Tù!", "action": "go_jail"},
	{"text": "Nhận thẻ Ra Tù Miễn Phí!", "action": "get_card"},
	{"text": "Trúng xổ số! Nhận $100", "action": "gain", "amount": 100},
]


func _init(controller: GameController = null):
	game_controller = controller


# Trả về true nếu ô này là ô sự kiện và đã được xử lý
func handle_event(player: Player, cell: Cell) -> bool:
	match cell.cell_type:
		"chance":
			print("--- BẮT ĐẦU XỬ LÝ SỰ KIỆN: Cơ Hội ---")
			_process_card(player, chance_cards.pick_random())
			return true
		"community":
			print("--- BẮT ĐẦU XỬ LÝ SỰ KIỆN: Khí Vận ---")
			_process_card(player, community_cards.pick_random())
			return true
		"go_to_jail":
			print("--- SỰ KIỆN: VÀO TÙ ---")
			handle_go_to_jail(player)
			return true
		"tax":
			print("--- SỰ KIỆN: ĐÓNG THUẾ $", cell.rent_price, " ---")
			handle_tax(player, cell.rent_price)
			return true
		"go":
			print("--- Ô GO: Nhận $200 ---")
			game_controller.process_reward(player, 200)
			game_controller.ui.show_message(player.name + " đến ô GO! Nhận $200")
			call_deferred("emit_signal", "event_finished")
			return true
		"jail":
			# Chỉ đi ngang qua, không bị gì
			print(player.name + " chỉ đi ngang qua Nhà Tù.")
			game_controller.ui.show_message(player.name + " đi ngang qua Nhà Tù")
			call_deferred("emit_signal", "event_finished")
			return true

	return false


func _process_card(player: Player, card: Dictionary):
	var text = card.get("text", "")
	print("🃏 Thẻ: ", text)
	game_controller.ui.show_message("🃏 " + text)

	match card.action:
		"gain":
			game_controller.process_reward(player, card.amount)
			call_deferred("emit_signal", "event_finished")

		"lose":
			game_controller.process_payment(player, null, card.amount, text)
			call_deferred("emit_signal", "event_finished")

		"move_to":
			var target_pos = card.position
			# Kiểm tra nếu đi qua GO thì nhận thưởng
			if target_pos < player.state.position:
				game_controller.process_reward(player, 200)
			game_controller.move_player_to_position(player, target_pos)
			call_deferred("_handle_cell_after_move", player, target_pos)

		"move_back":
			var steps = card.get("steps", 3)
			var new_pos = player.state.position - steps
			if new_pos < 0:
				new_pos += game_controller.game_state.board_size
			game_controller.move_player_to_position(player, new_pos)
			call_deferred("_handle_cell_after_move", player, new_pos)

		"go_jail":
			handle_go_to_jail(player)

		"get_card":
			player.state.special_cards += 1
			print(player.name + " nhận được thẻ Ra Tù Miễn Phí! Tổng: ", player.state.special_cards)
			call_deferred("emit_signal", "event_finished")

		"birthday":
			var total_received = 0
			for p in game_controller.game_state.players:
				if p != player and not p.is_bankrupt():
					var gift = card.amount
					if p.state.balance >= gift:
						p.deduct_money(gift)
						player.add_money(gift)
						total_received += gift
			print(player.name + " nhận được $", total_received, " quà sinh nhật!")
			call_deferred("emit_signal", "event_finished")


func _handle_cell_after_move(player: Player, cell_index: int):
	# Gọi lại hàm xử lý ô đất của GameController sau khi move
	await game_controller.handle_landed_cell(player, cell_index)
	emit_signal("event_finished")


func handle_go_to_jail(player: Player):
	game_controller.go_to_jail(player)
	call_deferred("emit_signal", "event_finished")


func handle_tax(player: Player, amount: int):
	game_controller.process_payment(player, null, amount, "Đóng thuế")
	call_deferred("emit_signal", "event_finished")
