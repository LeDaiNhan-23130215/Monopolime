extends GutTest

var asset_manager: AssetManager
var player1: Player
var player2: Player
var offer_cell: PropertyCell
var request_cell: PropertyCell

func before_each():
	asset_manager = AssetManager.new()
	player1 = Player.new(); player1.name = "P1"; player1.player_id = 0
	player2 = Player.new(); player2.name = "P2"; player2.player_id = 1

	offer_cell = PropertyCell.new()
	var pd1 = PropertyData.new()
	pd1.buy_price = 200; pd1.cell_name = "Do_1"; pd1.color_name = "red"
	offer_cell.data = pd1
	offer_cell.property_owner = player1
	offer_cell.is_mortgaged = false
	offer_cell.house_count = 0
	offer_cell.has_hotel = false
	player1.add_property(offer_cell)

	request_cell = PropertyCell.new()
	var pd2 = PropertyData.new()
	pd2.buy_price = 150; pd2.cell_name = "Xanh_1"; pd2.color_name = "blue"
	request_cell.data = pd2
	request_cell.property_owner = player2
	request_cell.is_mortgaged = false
	request_cell.house_count = 0
	request_cell.has_hotel = false
	player2.add_property(request_cell)

# TC-UC10-UT-01
func test_get_tradeable_properties_excludes_mortgaged():
	var mortgaged_cell = PropertyCell.new()
	var pd = PropertyData.new()
	pd.cell_name = "Do_2"; pd.color_name = "red"
	mortgaged_cell.data = pd
	mortgaged_cell.property_owner = player1
	mortgaged_cell.is_mortgaged = true
	mortgaged_cell.house_count = 0
	mortgaged_cell.has_hotel = false
	player1.add_property(mortgaged_cell)

	var result = asset_manager.get_tradeable_properties(player1)
	assert_eq(result.size(), 1, "Chỉ 1 ô hợp lệ")
	assert_true(result.has(offer_cell), "offer_cell phải có trong danh sách")
	assert_false(result.has(mortgaged_cell), "ô thế chấp phải bị loại")

# TC-UC10-UT-02
func test_validate_trade_rejects_cell_with_houses():
	offer_cell.house_count = 2
	var result = asset_manager.validate_trade(
		player1, player2, offer_cell, request_cell, 0, null)
	assert_false(result["valid"], "Phải invalid khi có nhà")
	assert_string_contains(result["reason"].to_lower(), "nhà")

# TC-UC10-UT-03
func test_execute_trade_no_compensation():
	player1.state.balance = 500
	player2.state.balance = 300

	var ok = asset_manager.execute_trade(
		player1, player2, offer_cell, request_cell, 0, null)

	assert_true(ok, "Trade phải thành công")
	assert_eq(offer_cell.property_owner, player2, "offer_cell phải thuộc P2")
	assert_eq(request_cell.property_owner, player1, "request_cell phải thuộc P1")
	assert_eq(player1.state.balance, 500, "Tiền P1 không đổi")
	assert_eq(player2.state.balance, 300, "Tiền P2 không đổi")

# TC-UC10-UT-04
func test_execute_trade_with_compensation_initiator_pays():
	player1.state.balance = 500
	player2.state.balance = 300

	var ok = asset_manager.execute_trade(
		player1, player2, offer_cell, request_cell, 100, player1)

	assert_true(ok, "Trade phải thành công")
	assert_eq(player1.state.balance, 400, "P1 mất $100")
	assert_eq(player2.state.balance, 400, "P2 được $100")
	assert_eq(offer_cell.property_owner, player2)
	assert_eq(request_cell.property_owner, player1)

# TC-UC10-UT-05
func test_validate_trade_fails_insufficient_compensation():
	player1.state.balance = 50

	var result = asset_manager.validate_trade(
		player1, player2, offer_cell, request_cell, 200, player1)

	assert_false(result["valid"], "Phải invalid khi không đủ tiền")
	assert_string_contains(result["reason"].to_lower(), "tiền")

# TC-UC10-UT-06
func test_execute_trade_atomic_rollback():
	# Không thể mock FinanceManager trực tiếp trong GUT cơ bản,
	# nên test gián tiếp: validate fail → execute không thay đổi gì
	player1.state.balance = 50  # không đủ trả compensation 200

	var ok = asset_manager.execute_trade(
		player1, player2, offer_cell, request_cell, 200, player1)

	assert_false(ok, "Trade phải thất bại")
	assert_eq(offer_cell.property_owner, player1, "offer_cell vẫn thuộc P1")
	assert_eq(request_cell.property_owner, player2, "request_cell vẫn thuộc P2")
	assert_eq(player1.state.balance, 50, "Tiền P1 không đổi")

# TC-UC10-UT-07
func test_trade_updates_color_set_bonus():
	# Setup: P1 có Do_1 (offer_cell) + Do_2. P2 có Do_3 + Xanh_1 (request_cell)
	var red2 = PropertyCell.new()
	var pd_r2 = PropertyData.new()
	pd_r2.cell_name = "Do_2"; pd_r2.color_name = "red"; pd_r2.base_rent = 50
	red2.data = pd_r2; red2.property_owner = player1
	red2.is_mortgaged = false; red2.house_count = 0; red2.has_hotel = false
	player1.add_property(red2)

	var red3 = PropertyCell.new()
	var pd_r3 = PropertyData.new()
	pd_r3.cell_name = "Do_3"; pd_r3.color_name = "red"; pd_r3.base_rent = 50
	red3.data = pd_r3; red3.property_owner = player2
	red3.is_mortgaged = false; red3.house_count = 0; red3.has_hotel = false
	player2.add_property(red3)

	# offer_cell.color = "red" (Do_1) thuộc P1
	# request_cell.color = "blue" (Xanh_1) thuộc P2
	# Sau swap: P2 có Do_1 + Do_3 → full set đỏ (giả sử bộ đỏ chỉ có 2 ô)
	# P1 còn Do_2 → không full set nữa
	player1.state.balance = 500
	player2.state.balance = 500

	asset_manager.execute_trade(
		player1, player2, offer_cell, request_cell, 0, null)

	# offer_cell giờ thuộc P2, P2 có Do_1 + Do_3 → full set đỏ
	assert_eq(offer_cell.property_owner, player2, "Do_1 phải thuộc P2")
	var rent = offer_cell.get_current_rent()
	assert_eq(rent, offer_cell.data.base_rent * 2,
		"Tiền thuê Do_1 phải nhân đôi vì P2 hoàn thành bộ đỏ")
