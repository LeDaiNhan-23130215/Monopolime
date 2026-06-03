extends Node
class_name EventHandler

signal event_finished

var game_controller: GameController

var chance_cards = [
	{"title": "Nhận thưởng dự án", "text": "Dự án mới sinh lời. Nhận $200.", "action": "gain", "amount": 200, "icon": "money"},
	{"title": "Trúng vé số", "text": "Bạn trúng giải may mắn. Nhận $300.", "action": "gain", "amount": 300, "icon": "gift"},
	{"title": "Phí bảo trì", "text": "Đóng phí bảo trì bất ngờ $100.", "action": "lose", "amount": 100, "icon": "tax"},
	{"title": "Về Khởi Hành", "text": "Đi đến ô Bắt đầu và nhận $200.", "action": "move_to_go", "icon": "go"},
	{"title": "Tiến 3 bước", "text": "Tiến lên 3 bước theo chiều đi.", "action": "move_forward", "steps": 3, "icon": "arrow"},
	{"title": "Lùi 2 bước", "text": "Lùi lại 2 bước.", "action": "move_back", "steps": 2, "icon": "arrow"},
	{"title": "Thưởng thành phố", "text": "Chiến dịch quảng bá thắng lớn. Nhận $120.", "action": "gain", "amount": 120, "icon": "city"},
	{"title": "Du lịch biển", "text": "Tour nghỉ dưỡng được tài trợ. Nhận $80.", "action": "gain", "amount": 80, "icon": "palm"},
	{"title": "Đi thẳng đến Nhà tù", "text": "Bạn bị yêu cầu vào Nhà tù ngay.", "action": "go_jail", "icon": "jail"},
	{"title": "Thoát tù miễn phí", "text": "Giữ thẻ này để thoát tù một lần.", "action": "get_card", "icon": "shield"},
	{"title": "Thu từ mỗi người chơi", "text": "Mỗi người chơi trả bạn $50.", "action": "birthday", "amount": 50, "icon": "token"},
	{"title": "Trả cho mỗi người chơi", "text": "Bạn trả $50 cho mỗi người chơi.", "action": "lose", "amount": 50, "icon": "money"},
	{"title": "Nâng cấp miễn phí", "text": "Giá khu đất hiện tại tăng $60.", "action": "modify_current_price", "amount": 60, "icon": "home"},
	{"title": "Cải tạo tài sản", "text": "Tiền thuê khu đất hiện tại tăng $40.", "action": "modify_current_rent", "amount": 40, "icon": "home"},
	{"title": "Tư vấn tài chính", "text": "Hợp đồng tư vấn thành công. Nhận $120.", "action": "gain", "amount": 120, "icon": "money"},
	{"title": "Mất ví", "text": "Bạn làm rơi ví trên đường. Trả $80.", "action": "lose", "amount": 80, "icon": "tax"},
	{"title": "Bán cổ phần", "text": "Bán cổ phần sinh lời. Nhận $180.", "action": "gain", "amount": 180, "icon": "money"},
	{"title": "Đóng thuế thu nhập", "text": "Nộp thuế thu nhập $150.", "action": "lose", "amount": 150, "icon": "tax"},
	{"title": "Quà đối tác", "text": "Đối tác gửi quà tri ân. Nhận $100.", "action": "gain", "amount": 100, "icon": "gift"},
	{"title": "Chi phí đi lại", "text": "Thanh toán chi phí đi lại $60.", "action": "lose", "amount": 60, "icon": "car"},
	{"title": "Ô Cơ hội gần nhất", "text": "Một cơ hội mới mở ra. Nhận $90.", "action": "gain", "amount": 90, "icon": "chance"},
	{"title": "Ô Khí vận gần nhất", "text": "Gió đổi chiều, bạn nhận $70.", "action": "gain", "amount": 70, "icon": "wind"},
	{"title": "Đất trống gần nhất", "text": "Tin môi giới tốt. Giá khu đất hiện tại tăng $50.", "action": "modify_current_price", "amount": 50, "icon": "home"},
	{"title": "Khu đất đắt giá", "text": "Tiền thuê khu đất hiện tại tăng $30.", "action": "modify_current_rent", "amount": 30, "icon": "home"},
	{"title": "Thuê gấp đôi", "text": "Nhu cầu tăng mạnh. Tiền thuê khu đất hiện tại tăng $50.", "action": "modify_current_rent", "amount": 50, "icon": "money"},
	{"title": "Miễn trả tiền thuê", "text": "Nhận một thẻ thoát tù miễn phí.", "action": "get_card", "icon": "shield"},
	{"title": "Tung xúc xắc lại", "text": "May mắn mỉm cười. Nhận $60.", "action": "gain", "amount": 60, "icon": "dice"},
	{"title": "Kiểm tra sổ sách", "text": "Bị kiểm tra sổ sách. Trả $110.", "action": "lose", "amount": 110, "icon": "tax"},
	{"title": "Sửa chữa nhà cửa", "text": "Bảo trì tài sản. Trả $90.", "action": "lose", "amount": 90, "icon": "home"},
	{"title": "Hoàn thuế", "text": "Được hoàn thuế $150.", "action": "gain", "amount": 150, "icon": "tax"},
	{"title": "Hợp đồng lớn", "text": "Ký hợp đồng lớn. Nhận $250.", "action": "gain", "amount": 250, "icon": "money"},
	{"title": "Từ thiện cộng đồng", "text": "Ủng hộ cộng đồng $120.", "action": "lose", "amount": 120, "icon": "gift"},
	{"title": "Thưởng sinh nhật", "text": "Bạn nhận quà sinh nhật $80.", "action": "gain", "amount": 80, "icon": "gift"},
	{"title": "Mua sắm xa xỉ", "text": "Mua sắm quá tay. Trả $90.", "action": "lose", "amount": 90, "icon": "tax"},
	{"title": "Cầu vàng", "text": "Chuyến đi truyền cảm hứng. Nhận $140.", "action": "gain", "amount": 140, "icon": "bridge"},
	{"title": "Sapa gọi mời", "text": "Đầu tư du lịch vùng cao. Nhận $130.", "action": "gain", "amount": 130, "icon": "mountain"},
	{"title": "Hoán đổi vận may", "text": "Lùi 3 bước để đổi vận.", "action": "move_back", "steps": 3, "icon": "arrow"},
	{"title": "Lá chắn may mắn", "text": "Nhận thẻ thoát tù miễn phí.", "action": "get_card", "icon": "shield"},
	{"title": "Thuê xe riêng", "text": "Tiến đến ga gần nhất.", "action": "move_nearest_railroad", "icon": "car"},
	{"title": "Cơ hội vàng", "text": "Chọn một người chơi trả bạn $200.", "action": "birthday", "amount": 200, "icon": "trophy"},
]

var community_cards = [
	{"title": "Lộc đầu năm", "text": "May mắn đầu năm. Nhận $100.", "action": "gain", "amount": 100, "icon": "trophy"},
	{"title": "Mùa du lịch", "text": "Kinh doanh mùa du lịch thắng lợi. Nhận $180.", "action": "gain", "amount": 180, "icon": "palm"},
	{"title": "Người thân hỗ trợ", "text": "Gia đình hỗ trợ bạn $120.", "action": "gain", "amount": 120, "icon": "token"},
	{"title": "Gặp quý nhân", "text": "Quý nhân chỉ đường. Nhận $200.", "action": "gain", "amount": 200, "icon": "gift"},
	{"title": "Xui xẻo nhỏ", "text": "Một chuyện không may. Trả $50.", "action": "lose", "amount": 50, "icon": "storm"},
	{"title": "Hao tài", "text": "Chi tiêu phát sinh. Trả $100.", "action": "lose", "amount": 100, "icon": "money"},
	{"title": "Ốm nhẹ", "text": "Nghỉ dưỡng và thanh toán $70.", "action": "lose", "amount": 70, "icon": "heart"},
	{"title": "Sức khỏe dồi dào", "text": "Tinh thần tốt. Nhận $80.", "action": "gain", "amount": 80, "icon": "heart"},
	{"title": "Vía tốt", "text": "Tung lại vận may. Nhận $90.", "action": "gain", "amount": 90, "icon": "dice"},
	{"title": "Bình an", "text": "Nhận thẻ thoát tù miễn phí.", "action": "get_card", "icon": "shield"},
	{"title": "Hồng phát", "text": "Làm ăn hồng phát. Nhận $300.", "action": "gain", "amount": 300, "icon": "gift"},
	{"title": "Mất khách", "text": "Mùa thấp điểm. Tiền thuê khu đất hiện tại giảm $30.", "action": "modify_current_rent", "amount": -30, "icon": "home"},
	{"title": "Khuyến mãi lớn", "text": "Giá khu đất hiện tại tăng $40.", "action": "modify_current_price", "amount": 40, "icon": "money"},
	{"title": "Đón lễ hội", "text": "Mỗi người chơi trả bạn $30.", "action": "birthday", "amount": 30, "icon": "gift"},
	{"title": "Làm từ thiện", "text": "Bạn quyên góp $90.", "action": "lose", "amount": 90, "icon": "heart"},
	{"title": "Cơ hội đầu tư", "text": "Giá khu đất hiện tại giảm $30.", "action": "modify_current_price", "amount": -30, "icon": "money"},
	{"title": "Vận đen", "text": "Lùi 3 bước.", "action": "move_back", "steps": 3, "icon": "storm"},
	{"title": "Vận đỏ", "text": "Tiến 4 bước.", "action": "move_forward", "steps": 4, "icon": "arrow"},
	{"title": "Cầu may thành công", "text": "Nhận thêm $110.", "action": "gain", "amount": 110, "icon": "chance"},
	{"title": "Kẹt xe", "text": "Bỏ lỡ cơ hội, trả $40.", "action": "lose", "amount": 40, "icon": "car"},
	{"title": "Quý nhân dẫn đường", "text": "Đi đến ga gần nhất.", "action": "move_nearest_railroad", "icon": "token"},
	{"title": "Mưa bão", "text": "Sửa chữa sau mưa bão. Trả $80.", "action": "lose", "amount": 80, "icon": "storm"},
	{"title": "Giải ẩm thực", "text": "Thắng giải địa phương. Nhận $140.", "action": "gain", "amount": 140, "icon": "trophy"},
	{"title": "Bảo hiểm", "text": "Đền bù bảo hiểm. Nhận $160.", "action": "gain", "amount": 160, "icon": "shield"},
	{"title": "Mất hành lý", "text": "Mất hành lý khi đi xa. Trả $70.", "action": "lose", "amount": 70, "icon": "gift"},
	{"title": "Quà online", "text": "Trúng quà online. Nhận $90.", "action": "gain", "amount": 90, "icon": "gift"},
	{"title": "Bị phạt", "text": "Bị phạt vi phạm. Trả $110.", "action": "lose", "amount": 110, "icon": "tax"},
	{"title": "Phúc bất tận", "text": "Nhận thẻ thoát tù miễn phí.", "action": "get_card", "icon": "shield"},
	{"title": "Vượng khí", "text": "Tiền thuê khu đất hiện tại tăng $50.", "action": "modify_current_rent", "amount": 50, "icon": "money"},
	{"title": "Bình ổn giá", "text": "Được miễn một khoản phí. Nhận $75.", "action": "gain", "amount": 75, "icon": "tax"},
	{"title": "Đêm không may", "text": "Vào Nhà tù ngay.", "action": "go_jail", "icon": "jail"},
	{"title": "Ánh sao dẫn lối", "text": "Đi đến ô Bắt đầu và nhận $200.", "action": "move_to_go", "icon": "trophy"},
	{"title": "Tài lộc sum vầy", "text": "Nhận $50 cho mỗi khu đất đang sở hữu.", "action": "gain", "amount": 150, "icon": "money"},
	{"title": "Khó khăn tài chính", "text": "Thế chấp tạm thời. Trả $150.", "action": "lose", "amount": 150, "icon": "tax"},
	{"title": "Thu hoạch lớn", "text": "Mùa vụ thắng lợi. Nhận $220.", "action": "gain", "amount": 220, "icon": "gift"},
	{"title": "Bạn bè giúp sức", "text": "Bạn bè hỗ trợ thoát tù miễn phí.", "action": "get_card", "icon": "token"},
	{"title": "May mắn bất ngờ", "text": "Nhận $150.", "action": "gain", "amount": 150, "icon": "chance"},
	{"title": "Sao quả tạ", "text": "Trả $150 hoặc lùi bước, bạn trả $150.", "action": "lose", "amount": 150, "icon": "storm"},
	{"title": "Vận quý nhân", "text": "Giảm rủi ro. Tiền thuê khu đất hiện tại tăng $20.", "action": "modify_current_rent", "amount": 20, "icon": "shield"},
	{"title": "Đại cát đại lợi", "text": "Nhận ngay $500.", "action": "gain", "amount": 500, "icon": "trophy"},
]

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
	_notify_deck_counts()


func get_deck_counts() -> Dictionary:
	return {
		"chance": _chance_deck.size(),
		"chance_total": chance_cards.size(),
		"community": _community_deck.size(),
		"community_total": community_cards.size(),
	}


func refresh_board_deck_counts() -> void:
	_notify_deck_counts()


func _draw_chance() -> Dictionary:
	if _chance_deck.is_empty():
		_chance_deck = chance_cards.duplicate()
		_chance_deck.shuffle()
	var card = _chance_deck.pop_front()
	_notify_deck_counts()
	return card


func _draw_community() -> Dictionary:
	if _community_deck.is_empty():
		_community_deck = community_cards.duplicate()
		_community_deck.shuffle()
	var card = _community_deck.pop_front()
	_notify_deck_counts()
	return card


func _notify_deck_counts() -> void:
	if game_controller and game_controller.board and game_controller.board.has_method("update_event_deck_counts"):
		game_controller.board.update_event_deck_counts(get_deck_counts())


func handle_event(player: Player, cell: Cell) -> bool:
	match cell.cell_type:
		"chance":
			var card = _draw_chance()
			game_controller.ui.play_sfx(GameUI.SFX_CARD)
			game_controller.ui.add_history(player.name + " rút Cơ hội: " + str(card.get("title", "")), Color("#E65100"))
			var amount = card.get("amount", 0)
			var display_amount = amount if card.get("action", "") != "lose" else -amount
			await game_controller.ui.show_event_card_and_wait("CƠ HỘI", card, Color("#F4A000"), display_amount, get_deck_counts())
			await _process_card(player, card)
			return true

		"community":
			var card = _draw_community()
			game_controller.ui.play_sfx(GameUI.SFX_CARD)
			game_controller.ui.add_history(player.name + " rút Khí vận: " + str(card.get("title", "")), Color("#0B6B38"))
			var amount = card.get("amount", 0)
			var display_amount = amount if card.get("action", "") != "lose" else -amount
			await game_controller.ui.show_event_card_and_wait("KHÍ VẬN", card, Color("#159947"), display_amount, get_deck_counts())
			await _process_card(player, card)
			return true

		"go_to_jail":
			game_controller.ui.show_message(player.name + " dừng ô Vào Tù – bị đưa vào Nhà tù ngay! (BR-26)")
			await game_controller.go_to_jail(player)
			call_deferred("emit_signal", "event_finished")
			return true

		"tax":
			var tax_amount = cell.rent_price
			game_controller.ui.show_message(player.name + " nop thue $" + str(tax_amount))
			game_controller.process_payment(player, null, tax_amount, cell.cell_name)
			call_deferred("emit_signal", "event_finished")
			return true

		"go":
			game_controller.ui.show_message(player.name + " den GO!")
			call_deferred("emit_signal", "event_finished")
			return true

		"jail":
			game_controller.ui.show_message(player.name + " di ngang qua Jail")
			call_deferred("emit_signal", "event_finished")
			return true

		"parking":
			game_controller.ui.show_message(player.name + " nghi tai Free Parking")
			call_deferred("emit_signal", "event_finished")
			return true

		"teleport":
			await game_controller.handle_teleport(player)
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
			game_controller.ui.show_message(player.name + " di chuyen do su kien: " + card.text)
			game_controller.process_reward(player, 200)
			await game_controller.move_player_to_position(player, 0)
			await _show_arrival(player, 0)
			call_deferred("emit_signal", "event_finished")

		"move_forward":
			var steps = card.get("steps", 3)
			var new_pos = (player.state.position + steps) % game_controller.game_state.board_size
			if player.state.position + steps >= game_controller.game_state.board_size:
				game_controller.process_reward(player, 200)
			game_controller.ui.show_message(player.name + " di chuyen do su kien: " + card.text)
			await game_controller.move_player_to_position(player, new_pos)
			await _show_arrival(player, new_pos)
			await _handle_cell_after_move(player, new_pos)

		"move_back":
			var steps = card.get("steps", 3)
			var new_pos = player.state.position - steps
			if new_pos < 0:
				new_pos += game_controller.game_state.board_size
			game_controller.ui.show_message(player.name + " di chuyen do su kien: " + card.text)
			await game_controller.move_player_to_position(player, new_pos)
			await _show_arrival(player, new_pos)
			await _handle_cell_after_move(player, new_pos)

		"move_forward":
			var steps = card.get("steps", 3)
			var new_pos = (player.state.position + steps) % game_controller.game_state.board_size
			game_controller.ui.show_message(player.name + " di chuyen do su kien: " + card.text)
			await game_controller.move_player_to_position(player, new_pos)
			await _show_arrival(player, new_pos)
			call_deferred("_handle_cell_after_move", player, new_pos)

		"move_nearest_railroad":
			var nearest = _find_nearest_railroad(player.state.position)
			if player.state.position > nearest:
				game_controller.process_reward(player, 200)
			game_controller.ui.show_message(player.name + " di chuyen do su kien: " + card.text)
			await game_controller.move_player_to_position(player, nearest)
			await _show_arrival(player, nearest)
			await _handle_cell_after_move(player, nearest)

		"go_jail":
			game_controller.ui.show_message(player.name + " rút thẻ Vào Tù – bị đưa vào Nhà tù ngay! (BR-26)")
			await game_controller.go_to_jail(player)
			call_deferred("emit_signal", "event_finished")

		"get_card":
			player.state.special_cards += 1
			game_controller.ui.show_message(player.name + " nhan the Ra Tu! Tong: " + str(player.state.special_cards))
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
			game_controller.ui.show_message(player.name + " nhan $" + str(total_received) + " qua sinh nhat!")
			game_controller.ui.add_history(player.name + " nhận $" + str(total_received) + " từ người chơi khác", Color("#1B5E20"))
			game_controller.ui.show_money_float(total_received, player.token)
			call_deferred("emit_signal", "event_finished")

		"modify_current_price":
			_apply_modifier_card(player, card, "price")
			call_deferred("emit_signal", "event_finished")

		"modify_current_rent":
			_apply_modifier_card(player, card, "rent")
			call_deferred("emit_signal", "event_finished")


func _apply_modifier_card(player: Player, card: Dictionary, target: String):
	var cell = game_controller.board.get_cell(player.state.position)
	if cell == null or cell.price <= 0:
		cell = _find_nearest_priced_cell(player.state.position)
	if cell == null:
		game_controller.ui.show_message("Khong co tai san nao de thay doi.")
		return

	var amount = int(card.get("amount", 0))
	if cell.has_protection_tower and amount < 0:
		game_controller.ui.show_message(cell.cell_name + " duoc thap bao ve chan hieu ung xau!")
		cell.play_upgrade_effect()
		return

	if target == "price":
		cell.price_modifier += amount
		game_controller.ui.show_message(cell.cell_name + " thay doi gia: " + _format_signed(amount))
	else:
		cell.rent_modifier += amount
		game_controller.ui.show_message(cell.cell_name + " thay doi tien thue: " + _format_signed(amount))
	cell.play_land_effect()
	cell.queue_redraw()
	if game_controller and game_controller.board:
		game_controller.board.update_cell_tooltips()


func _format_signed(amount: int) -> String:
	return "+$" + str(amount) if amount >= 0 else "-$" + str(abs(amount))


func _find_nearest_priced_cell(current_pos: int) -> Cell:
	var board_size = game_controller.game_state.board_size
	for i in range(1, board_size + 1):
		var check_pos = (current_pos + i) % board_size
		var cell = game_controller.board.get_cell(check_pos)
		if cell and cell.price > 0:
			return cell
	return null


func _show_arrival(player: Player, cell_index: int):
	var target_cell = game_controller.board.get_cell(cell_index)
	if target_cell:
		target_cell.play_land_effect()
		await game_controller.ui.show_toast_and_wait(
			"Di chuyen",
			player.name + " da den " + target_cell.cell_name,
			Color(0.5, 0.8, 1.0),
			0,
			0.75
		)


func _handle_cell_after_move(player: Player, cell_index: int):
	await game_controller.handle_landed_cell(player, cell_index)
	emit_signal("event_finished")


func _find_nearest_railroad(current_pos: int) -> int:
	var board_size = game_controller.game_state.board_size
	for i in range(1, board_size + 1):
		var check_pos = (current_pos + i) % board_size
		var cell = game_controller.board.get_cell(check_pos)
		if cell and cell.cell_type == "railroad":
			return check_pos
	return current_pos
