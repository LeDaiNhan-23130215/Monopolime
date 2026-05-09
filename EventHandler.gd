extends Node
class_name EventHandler

signal event_finished

var game_controller: GameController

func _init(controller: GameController):
	game_controller = controller

# Trả về true nếu ô này là ô sự kiện và đã được xử lý
func handle_event(player: Player, cell: Cell) -> bool:
	if cell.cell_name in ["Cơ Hội", "Khí Vận", "Thẻ Cơ Hội", "Thẻ Khí Vận", "Sự Kiện", "Khí vận", "Cơ hội"]:
		print("--- BẮT ĐẦU XỬ LÝ SỰ KIỆN: ", cell.cell_name, " ---")
		trigger_random_event(player)
		return true
	elif cell.cell_name in ["Vào Tù", "Vào tù"]:
		print("--- SỰ KIỆN: VÀO TÙ ---")
		handle_go_to_jail(player)
		return true
	elif cell.cell_name in ["Thuế", "Đóng Thuế", "Thuế thu nhập"]:
		print("--- SỰ KIỆN: ĐÓNG THUẾ ---")
		handle_tax(player, 200) # Giả sử thuế là 200
		return true
		
	return false

func trigger_random_event(player: Player):
	var random_event = randi() % 5
	match random_event:
		0:
			# Sự kiện nhận tiền
			var amount = 100
			print("Sự kiện Nhận tiền: Bạn được thưởng $", amount)
			game_controller.process_reward(player, amount)
			call_deferred("emit_signal", "event_finished")
		1:
			# Sự kiện mất tiền
			var amount = 50
			print("Sự kiện Mất tiền: Bạn bị phạt $", amount)
			# Truyền beneficiary là null (trả cho ngân hàng)
			game_controller.process_payment(player, null, amount, "Phạt sự kiện")
			# process_payment sẽ tự gọi turn_action_completed nếu đủ tiền, hoặc mở UI nếu thiếu tiền
			call_deferred("emit_signal", "event_finished")
		2:
			# Sự kiện di chuyển
			print("Sự kiện Di chuyển: Tiến đến ô 5")
			game_controller.move_player_to_position(player, 5)
			# Sau khi di chuyển, cần xử lý ô mới
			# Sử dụng call_deferred để tránh lỗi kẹt luồng
			call_deferred("handle_cell_after_move", player, 5)
		3:
			# Sự kiện nhận thẻ đặc biệt
			print("Sự kiện Thẻ đặc biệt: Nhận thẻ Ra Tù Miễn Phí")
			player.state.special_cards += 1
			call_deferred("emit_signal", "event_finished")
		4:
			# Sự kiện vào tù
			print("Sự kiện Vào Tù: Bạn bị bắt!")
			handle_go_to_jail(player)

func handle_cell_after_move(player: Player, cell_index: int):
	# Gọi lại hàm xử lý ô đất của GameController sau khi move
	game_controller.handle_landed_cell(player, cell_index)
	emit_signal("event_finished")

func handle_go_to_jail(player: Player):
	game_controller.go_to_jail(player)
	call_deferred("emit_signal", "event_finished")

func handle_tax(player: Player, amount: int):
	game_controller.process_payment(player, null, amount, "Đóng thuế")
	call_deferred("emit_signal", "event_finished")
