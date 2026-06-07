# =============================================================================
# UC-10 – Trao đổi đất: Unit Tests (Development Testing)
# Framework: GUT (Godot Unit Test)
# File: test/test_uc10_trade.gd
# Commit: phải được commit cùng với scripts/AssetManager.gd
#
# Các test bao phủ AssetManager (business logic lõi):
#   TC-UC10-UT-01 → get_tradeable_properties()
#   TC-UC10-UT-02 → validate_trade() – ô có nhà
#   TC-UC10-UT-03 → execute_trade() – trao đổi ngang
#   TC-UC10-UT-04 → execute_trade() – có khoản bù Initiator trả
#   TC-UC10-UT-05 → validate_trade() – không đủ tiền bù
#   TC-UC10-UT-06 → execute_trade() – không có trạng thái nửa chừng
#   TC-UC10-UT-07 → execute_trade() – cập nhật bộ màu (BR-35T)
# =============================================================================
extends GutTest

var asset_manager: AssetManager
var player1: Player
var player2: Player
var offer_cell: PropertyCell
var request_cell: PropertyCell

# ─────────────────────────────────────────────────────────────────────
# Setup: khởi tạo dữ liệu dùng chung cho tất cả test
# P1 sở hữu offer_cell (Do_1, đỏ, $200)
# P2 sở hữu request_cell (Xanh_1, xanh, $150)
# Cả hai ô đều không thế chấp, không có nhà/KS
# ─────────────────────────────────────────────────────────────────────
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


# ─────────────────────────────────────────────────────────────────────
# TC-UC10-UT-01
# Mục tiêu: get_tradeable_properties() phải loại bỏ ô đang thế chấp
# Kịch bản: P1 có 2 ô: offer_cell (bình thường) + mortgaged_cell (thế chấp)
# Kết quả mong đợi: chỉ trả về [offer_cell]
# ─────────────────────────────────────────────────────────────────────
func test_get_tradeable_properties_excludes_mortgaged():
	var mortgaged_cell = PropertyCell.new()
	var pd = PropertyData.new()
	pd.cell_name = "Do_2"; pd.color_name = "red"
	mortgaged_cell.data = pd
	mortgaged_cell.property_owner = player1
	mortgaged_cell.is_mortgaged = true   # ← đang thế chấp
	mortgaged_cell.house_count = 0
	mortgaged_cell.has_hotel = false
	player1.add_property(mortgaged_cell)

	var result = asset_manager.get_tradeable_properties(player1)
	assert_eq(result.size(), 1, "Chỉ 1 ô hợp lệ")
	assert_true(result.has(offer_cell), "offer_cell phải có trong danh sách")
	assert_false(result.has(mortgaged_cell), "ô thế chấp phải bị loại")


# ─────────────────────────────────────────────────────────────────────
# TC-UC10-UT-02
# Mục tiêu: validate_trade() phải từ chối ô đang có nhà (BR-31T)
# Kịch bản: offer_cell có house_count = 2
# Kết quả mong đợi: valid=false, reason chứa "nhà"
# ─────────────────────────────────────────────────────────────────────
func test_validate_trade_rejects_cell_with_houses():
	offer_cell.house_count = 2   # ← có 2 nhà
	var result = asset_manager.validate_trade(
		player1, player2, offer_cell, request_cell, 0, null)
	assert_false(result["valid"], "Phải invalid khi có nhà")
	assert_string_contains(result["reason"].to_lower(), "nhà")


# ─────────────────────────────────────────────────────────────────────
# TC-UC10-UT-03
# Mục tiêu: execute_trade() trao đổi ngang (compensation=0) phải thành công
# Kịch bản: P1 có $500, P2 có $300. compensation=0
# Kết quả mong đợi:
#   - execute_trade() = true
#   - offer_cell.property_owner == player2
#   - request_cell.property_owner == player1
#   - Tiền hai bên không thay đổi
# ─────────────────────────────────────────────────────────────────────
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


# ─────────────────────────────────────────────────────────────────────
# TC-UC10-UT-04
# Mục tiêu: execute_trade() với khoản bù Initiator trả (BR-32T)
# Kịch bản: P1 có $500, compensation=$100, P1 trả cho P2
# Kết quả mong đợi:
#   - execute_trade() = true
#   - P1 còn $400, P2 có $400 thêm
#   - Quyền sở hữu hoán đổi đúng
# ─────────────────────────────────────────────────────────────────────
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


# ─────────────────────────────────────────────────────────────────────
# TC-UC10-UT-05
# Mục tiêu: validate_trade() phải từ chối khi không đủ tiền bù (BR-32T, E10.3)
# Kịch bản: P1 có $50, cần trả compensation=$200
# Kết quả mong đợi: valid=false, reason chứa "tiền"
# ─────────────────────────────────────────────────────────────────────
func test_validate_trade_fails_insufficient_compensation():
	player1.state.balance = 50   # ← không đủ

	var result = asset_manager.validate_trade(
		player1, player2, offer_cell, request_cell, 200, player1)

	assert_false(result["valid"], "Phải invalid khi không đủ tiền")
	assert_string_contains(result["reason"].to_lower(), "tiền")


# ─────────────────────────────────────────────────────────────────────
# TC-UC10-UT-06
# Mục tiêu: execute_trade() không để trạng thái nửa chừng (BR-34T)
# Kịch bản: validate_trade() thất bại (P1 không đủ tiền bù $200)
#           → execute_trade() phải trả false và không thay đổi gì
# Kết quả mong đợi:
#   - execute_trade() = false
#   - offer_cell vẫn thuộc P1, request_cell vẫn thuộc P2
#   - Tiền P1 không thay đổi
# ─────────────────────────────────────────────────────────────────────
func test_execute_trade_atomic_rollback():
	player1.state.balance = 50   # không đủ trả compensation 200

	var ok = asset_manager.execute_trade(
		player1, player2, offer_cell, request_cell, 200, player1)

	assert_false(ok, "Trade phải thất bại")
	assert_eq(offer_cell.property_owner, player1, "offer_cell vẫn thuộc P1")
	assert_eq(request_cell.property_owner, player2, "request_cell vẫn thuộc P2")
	assert_eq(player1.state.balance, 50, "Tiền P1 không đổi")


# ─────────────────────────────────────────────────────────────────────
# TC-UC10-UT-07
# Mục tiêu: sau trao đổi, tiền thuê cập nhật đúng theo bộ màu (BR-35T)
# Kịch bản:
#   P1 có Do_1 (đỏ, offer_cell)
#   P2 có Do_3 (đỏ) + Xanh_1 (xanh, request_cell)
#   Sau swap: P2 có Do_1 + Do_3 → full set đỏ (giả sử bộ đỏ 2 ô)
# Kết quả mong đợi:
#   - offer_cell.property_owner == player2
#   - offer_cell.get_current_rent() == base_rent * 2
# ─────────────────────────────────────────────────────────────────────
func test_trade_updates_color_set_bonus():
	# P2 thêm ô Do_3 (đỏ) để cùng bộ với Do_1
	var red3 = PropertyCell.new()
	var pd_r3 = PropertyData.new()
	pd_r3.cell_name = "Do_3"; pd_r3.color_name = "red"; pd_r3.base_rent = 50
	red3.data = pd_r3; red3.property_owner = player2
	red3.is_mortgaged = false; red3.house_count = 0; red3.has_hotel = false
	player2.add_property(red3)

	player1.state.balance = 500
	player2.state.balance = 500

	# offer_cell = Do_1 (đỏ) đi từ P1 → P2
	# request_cell = Xanh_1 (xanh) đi từ P2 → P1
	# Sau swap: P2 có Do_1 + Do_3 → full set đỏ
	asset_manager.execute_trade(
		player1, player2, offer_cell, request_cell, 0, null)

	assert_eq(offer_cell.property_owner, player2, "Do_1 phải thuộc P2")
	var rent = offer_cell.get_current_rent()
	# get_current_rent() tự gọi _owner_has_full_color_set() → trả về base_rent * 2
	assert_eq(rent, offer_cell.data.base_rent * 2,
		"Tiền thuê phải nhân đôi vì P2 hoàn thành bộ đỏ")
