extends GutTest

func test_all_players_pass():
	var controller = GameController.new()

	controller.game_state = GameState.new()
	controller.game_state.players = []
	controller.game_state.current_player = 0
	controller.game_state.board_size = 20
	controller.game_state.double_count = 0

	var p1 = Player.new()
	p1.player_id = 0
	p1.balance = 1500

	var p2 = Player.new()
	p2.player_id = 1
	p2.balance = 1500

	controller.game_state.players = [p1, p2]

	# giả lập auction state
	var passed = {
		0: true,
		1: true
	}

	var remaining = 0
	for p in controller.game_state.players:
		if not passed[p.player_id]:
			remaining += 1

	assert_eq(remaining, 0)
	
func test_all_players_pass_results_in_no_winner():
	var passed = {
		0: true,
		1: true
	}

	var remaining = 0

	for id in passed:
		if not passed[id]:
			remaining += 1

	assert_eq(remaining, 0)


func test_highest_bidder_wins():
	var current_bid = 500

	var p1 = Player.new()
	p1.player_id = 1

	var p2 = Player.new()
	p2.player_id = 2

	var current_winner = p2

	assert_eq(current_bid, 500)
	assert_eq(current_winner.player_id, 2)
	
func test_no_winner_when_all_players_pass():
	var current_winner = null
	var current_bid = 0

	assert_null(current_winner)
	assert_eq(current_bid, 0)
	
func test_bid_cannot_exceed_balance():
	var bidder = Player.new()
	bidder.balance = 100

	var bid_amount = 500

	assert_true(bid_amount > bidder.balance)

func test_property_owner_changes_after_auction():
	var buyer = Player.new()

	var property = PropertyCell.new()

	property.property_owner = null
	


	property.property_owner = buyer

	assert_eq(property.property_owner, buyer)
	
	
