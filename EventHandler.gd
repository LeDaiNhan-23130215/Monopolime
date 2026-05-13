extends Node
class_name EventHandler

signal event_finished

var game_controller: GameController

var chance_cards = [
	{"text": "Bank dividend! Receive $50", "action": "gain", "amount": 50},
	{"text": "Beauty contest prize! Receive $100", "action": "gain", "amount": 100},
	{"text": "Stocks rise! Receive $150", "action": "gain", "amount": 150},
	{"text": "Insurance payout! Receive $100", "action": "gain", "amount": 100},
	{"text": "Traffic fine! Pay $50", "action": "lose", "amount": 50},
	{"text": "House repairs! Pay $100", "action": "lose", "amount": 100},
	{"text": "Hospital bill! Pay $75", "action": "lose", "amount": 75},
	{"text": "Advance to GO and receive $200", "action": "move_to_go"},
	{"text": "Go directly to Jail. Do not pass GO.", "action": "go_jail"},
	{"text": "Move back 3 spaces", "action": "move_back", "steps": 3},
	{"text": "Go to the nearest station", "action": "move_nearest_railroad"},
	{"text": "Get out of Jail free", "action": "get_card"},
	{"text": "Birthday! Every player pays you $25", "action": "birthday", "amount": 25},
	{"text": "Rental bonus! Receive $25", "action": "gain", "amount": 25},
	{"text": "School fee! Pay $150", "action": "lose", "amount": 150},
	{"text": "Lottery win! Receive $200", "action": "gain", "amount": 200},
	{"text": "Market boom! Current property price increases by $50", "action": "modify_current_price", "amount": 50},
	{"text": "Rent demand rises! Current property rent increases by $20", "action": "modify_current_rent", "amount": 20},
]

var community_cards = [
	{"text": "Inheritance! Receive $200", "action": "gain", "amount": 200},
	{"text": "Tax refund! Receive $75", "action": "gain", "amount": 75},
	{"text": "Sold shares! Receive $45", "action": "gain", "amount": 45},
	{"text": "Hospital expenses! Pay $100", "action": "lose", "amount": 100},
	{"text": "Legal fees! Pay $50", "action": "lose", "amount": 50},
	{"text": "Scholarship fund! Receive $50", "action": "gain", "amount": 50},
	{"text": "Bank error! Receive $75", "action": "gain", "amount": 75},
	{"text": "Go directly to Jail", "action": "go_jail"},
	{"text": "Get out of Jail free", "action": "get_card"},
	{"text": "Prize draw! Receive $100", "action": "gain", "amount": 100},
	{"text": "Medicine bill! Pay $50", "action": "lose", "amount": 50},
	{"text": "Holiday gift! Receive $100", "action": "gain", "amount": 100},
	{"text": "Street repairs! Pay $40", "action": "lose", "amount": 40},
	{"text": "Sales bonus! Receive $50", "action": "gain", "amount": 50},
	{"text": "Advance to GO", "action": "move_to_go"},
	{"text": "Your birthday! Every player pays you $10", "action": "birthday", "amount": 10},
	{"text": "Local prices fall! Current property price decreases by $50", "action": "modify_current_price", "amount": -50},
	{"text": "Quiet season! Current property rent decreases by $20", "action": "modify_current_rent", "amount": -20},
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


func handle_event(player: Player, cell: Cell) -> bool:
	match cell.cell_type:
		"chance":
			var card = _draw_chance()
			game_controller.ui.play_sfx(GameUI.SFX_CARD)
			var amount = card.get("amount", 0)
			var display_amount = amount if card.get("action", "") != "lose" else -amount
			await game_controller.ui.show_card_and_wait("CHANCE", card.text, Color(1.0, 0.6, 0.2), display_amount)
			await _process_card(player, card)
			return true

		"community":
			var card = _draw_community()
			game_controller.ui.play_sfx(GameUI.SFX_CARD)
			var amount = card.get("amount", 0)
			var display_amount = amount if card.get("action", "") != "lose" else -amount
			await game_controller.ui.show_card_and_wait("COMMUNITY", card.text, Color(0.4, 0.7, 1.0), display_amount)
			await _process_card(player, card)
			return true

		"go_to_jail":
			game_controller.ui.show_message(player.name + " bi dua vao Jail!")
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

		"move_back":
			var steps = card.get("steps", 3)
			var new_pos = player.state.position - steps
			if new_pos < 0:
				new_pos += game_controller.game_state.board_size
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
			call_deferred("_handle_cell_after_move", player, nearest)

		"go_jail":
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
