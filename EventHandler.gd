extends Node
class_name EventHandler

signal event_finished

var game_controller: GameController

# =========================
# THẺ CƠ HỘI (Chance) - 16 thẻ
# =========================
var chance_cards = [
	{"text": "🏦 Ngân hàng trả cổ tức! Nhận $50", "action": "gain", "amount": 50},
	{"text": "🏆 Bạn thắng cuộc thi sắc đẹp! Nhận $100", "action": "gain", "amount": 100},
	{"text": "📈 Cổ phiếu tăng giá! Nhận $150", "action": "gain", "amount": 150},
	{"text": "🎁 Bảo hiểm đáo hạn! Nhận $100", "action": "gain", "amount": 100},
	{"text": "🚗 Bị phạt vượt đèn đỏ! Nộp $50", "action": "lose", "amount": 50},
	{"text": "🔧 Sửa chữa nhà cửa! Nộp $100", "action": "lose", "amount": 100},
	{"text": "🏥 Viện phí khám bệnh! Nộp $75", "action": "lose", "amount": 75},
	{"text": "🏁 Tiến đến ô GO! Nhận $200", "action": "move_to_go"},
	{"text": "👮 Đi thẳng vào Tù! Không qua GO!", "action": "go_jail"},
	{"text": "⬅️ Lùi 3 bước!", "action": "move_back", "steps": 3},
	{"text": "🚂 Đi đến Ga gần nhất!", "action": "move_nearest_railroad"},
	{"text": "🃏 Nhận thẻ Ra Tù Miễn Phí!", "action": "get_card"},
	{"text": "🎂 Sinh nhật! Mỗi người chơi trả bạn $25", "action": "birthday", "amount": 25},
	{"text": "💰 Tiền cho thuê! Nhận $25", "action": "gain", "amount": 25},
	{"text": "🏫 Học phí! Nộp $150", "action": "lose", "amount": 150},
	{"text": "🎰 Trúng xổ số! Nhận $200", "action": "gain", "amount": 200},
]

# =========================
# THẺ KHÍ VẬN (Community Chest) - 16 thẻ
# =========================
var community_cards = [
	{"text": "💎 Kế thừa di sản! Nhận $200", "action": "gain", "amount": 200},
	{"text": "📋 Hoàn thuế! Nhận $75", "action": "gain", "amount": 75},
	{"text": "📊 Bán cổ phiếu! Nhận $45", "action": "gain", "amount": 45},
	{"text": "🏥 Chi phí bệnh viện! Nộp $100", "action": "lose", "amount": 100},
	{"text": "⚖️ Phí luật sư! Nộp $50", "action": "lose", "amount": 50},
	{"text": "🏫 Quỹ học bổng! Nhận $50", "action": "gain", "amount": 50},
	{"text": "🏦 Sai sót ngân hàng! Nhận $75", "action": "gain", "amount": 75},
	{"text": "👮 Đi thẳng vào Tù!", "action": "go_jail"},
	{"text": "🃏 Nhận thẻ Ra Tù Miễn Phí!", "action": "get_card"},
	{"text": "🎰 Trúng giải! Nhận $100", "action": "gain", "amount": 100},
	{"text": "💊 Thuốc men! Nộp $50", "action": "lose", "amount": 50},
	{"text": "🎁 Quà Giáng sinh! Nhận $100", "action": "gain", "amount": 100},
	{"text": "🔧 Sửa chữa đường phố! Nộp $40", "action": "lose", "amount": 40},
	{"text": "📦 Nhận hàng bán! Nhận $50", "action": "gain", "amount": 50},
	{"text": "🏁 Tiến đến ô GO!", "action": "move_to_go"},
	{"text": "🎂 Sinh nhật bạn! Mỗi người trả $10", "action": "birthday", "amount": 10},
]

# Xáo bài
var _chance_deck: Array = []
var _community_deck: Array = []


func _init(controller: GameController = null):
	game_controller = controller
	_shuffle_decks()


func _shuffle_decks():
	_chance_deck = chance_cards.duplicate()
	_chance_deck.shuffle()
	_community_deck = community_cards.duplicate()
	_community_deck.shuffle()


func _draw_chance() -> Dictionary:
	if _chance_deck.is_empty():
		_chance_deck = chance_cards.duplicate()
		_chance_deck.shuffle()
	return _chance_deck.pop_front()


func _draw_community() -> Dictionary:
	if _community_deck.is_empty():
		_community_deck = community_cards.duplicate()
		_community_deck.shuffle()
	return _community_deck.pop_front()


# =========================
# XỬ LÝ SỰ KIỆN
# =========================

func handle_event(player: Player, cell: Cell) -> bool:
	if not cell or not cell.data:
		return false
	
	match cell.data.cell_type:
		CellType.Type.CHANCE:
			var card = _draw_chance()
			print("--- CƠ HỘI: ", card.text, " ---")
			game_controller.ui.show_card_popup("CƠ HỘI", card.text, Color(1.0, 0.6, 0.2))
			await get_tree().create_timer(2.0).timeout
			game_controller.ui.hide_card_popup()
			await _process_card(player, card)
			return true

		CellType.Type.CHEST:
			var card = _draw_community()
			print("--- KHÍ VẬN: ", card.text, " ---")
			game_controller.ui.show_card_popup("KHÍ VẬN", card.text, Color(0.4, 0.6, 1.0))
			await get_tree().create_timer(2.0).timeout
			game_controller.ui.hide_card_popup()
			await _process_card(player, card)
			return true

		CellType.Type.GO_TO_JAIL:
			print("--- VÀO TÙ! ---")
			game_controller.ui.show_message("👮 " + player.name + " bị bắt! Vào Tù!")
			await game_controller.go_to_jail(player)
			call_deferred("emit_signal", "event_finished")
			return true

		CellType.Type.TAX:
			if cell is TaxCell:
				var tax_data = cell.data as TaxData
				if tax_data:
					var tax_amount = tax_data.tax_amount
					print("--- THUẾ: $", tax_amount, " ---")
					game_controller.ui.show_message("💸 " + player.name + " nộp thuế $" + str(tax_amount))
					game_controller.process_payment(player, null, tax_amount, cell.data.cell_name)
					call_deferred("emit_signal", "event_finished")
					return true

		CellType.Type.GO:
			game_controller.ui.show_message("🏁 " + player.name + " đến ô GO!")
			call_deferred("emit_signal", "event_finished")
			return true

		CellType.Type.VISIT_JAIL:
			game_controller.ui.show_message(player.name + " đi ngang qua Nhà Tù 🔒")
			call_deferred("emit_signal", "event_finished")
			return true

		CellType.Type.PARKING:
			game_controller.ui.show_message(player.name + " nghỉ chân tại Bãi Đỗ Xe")
			call_deferred("emit_signal", "event_finished")
			return true

	return false


func _process_card(player: Player, card: Dictionary):
	match card.action:
		"gain":
			game_controller.process_reward(player, card.amount)
			call_deferred("emit_signal", "event_finished")

		"lose":
			game_controller.process_payment(player, null, card.amount, card.text)
			call_deferred("emit_signal", "event_finished")

		"move_to_go":
			# Di chuyển đến GO và nhận $200
			game_controller.process_reward(player, 200)
			await game_controller.move_player_to_position(player, 0)
			call_deferred("emit_signal", "event_finished")

		"move_back":
			var steps = card.get("steps", 3)
			var new_pos = player.state.position - steps
			if new_pos < 0:
				new_pos += game_controller.game_state.board_size
			await game_controller.move_player_to_position(player, new_pos)
			# Xử lý ô mới sau khi di chuyển
			call_deferred("_handle_cell_after_move", player, new_pos)

		"move_nearest_railroad":
			var nearest = _find_nearest_railroad(player.state.position)
			if player.state.position > nearest:
				# Đi qua GO
				game_controller.process_reward(player, 200)
			await game_controller.move_player_to_position(player, nearest)
			call_deferred("_handle_cell_after_move", player, nearest)

		"go_jail":
			await game_controller.go_to_jail(player)
			call_deferred("emit_signal", "event_finished")

		"get_card":
			player.state.special_cards += 1
			game_controller.ui.show_message(player.name + " nhận thẻ Ra Tù! (Tổng: " + str(player.state.special_cards) + ")")
			print(player.name + " nhận thẻ Ra Tù Miễn Phí!")
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
			game_controller.ui.show_message("🎂 " + player.name + " nhận $" + str(total_received) + " quà sinh nhật!")
			call_deferred("emit_signal", "event_finished")


func _handle_cell_after_move(player: Player, cell_index: int):
	await game_controller.handle_landed_cell(player, cell_index)
	emit_signal("event_finished")


func _find_nearest_railroad(current_pos: int) -> int:
	# Tìm nhà ga gần nhất phía trước
	var board_size = game_controller.game_state.board_size
	for i in range(1, board_size + 1):
		var check_pos = (current_pos + i) % board_size
		var cell = game_controller.board.get_cell(check_pos)
		if cell and cell.data and cell.data.cell_type == CellType.Type.PROPERTY:
			if cell is PropertyCell:
				var prop_data = cell.data as PropertyData
				if prop_data and prop_data.color_name == "railroad":
					return check_pos
	return current_pos
