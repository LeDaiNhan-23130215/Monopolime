extends Node
class_name AssetManager

# =========================
# AssetManager – UC7: Quản lý tài sản
# Xử lý: Mua / Xây / Thế chấp / Chuộc / Bán / Trao đổi
# =========================

signal asset_action_completed(action: String, success: bool, message: String)

var board: Board  # Cần để lấy danh sách all_cells


func _get_all_cells() -> Array:
	if board == null:
		return []
	return board.cells


# =========================
# AF7.2 – Mua tài sản (BR-07)
# =========================
func buy_property(player: Player, cell: PropertyCell) -> bool:
	# Kiểm tra ô chưa có chủ
	if cell.property_owner != null:
		_emit("buy", false, "Ô đất đã có chủ: " + cell.data.cell_name)
		return false

	var prop_data = cell.data as PropertyData
	if prop_data == null:
		_emit("buy", false, "Dữ liệu tài sản không hợp lệ")
		return false

	var price = prop_data.buy_price

	# Kiểm tra đủ tiền
	if not FinanceManager.can_afford(player, price):
		_emit("buy", false, player.name + " không đủ tiền mua " + cell.data.cell_name)
		return false

	# Trừ tiền và gán quyền sở hữu
	FinanceManager.deduct(player, price)
	cell.property_owner = player
	player.add_property(cell)
	cell.queue_redraw()

	_emit("buy", true, player.name + " mua " + cell.data.cell_name + " với giá $" + str(price))
	return true


# =========================
# AF7.3 – Xây nhà / Khách sạn (BR-11–BR-14)
# =========================
func build_house(player: Player, cell: PropertyCell) -> bool:
	var all_cells = _get_all_cells()

	# Kiểm tra quyền sở hữu
	if cell.property_owner != player:
		_emit("build", false, "Không phải tài sản của bạn")
		return false

	# Kiểm tra tài sản có thế chấp không (E7.2)
	if cell.is_mortgaged:
		_emit("build", false, "Tài sản đang thế chấp: " + cell.data.cell_name)
		return false

	# Kiểm tra điều kiện xây (BR-12, BR-13)
	if not PropertyController.can_build_on(cell, player, all_cells):
		_emit("build", false, "Không đủ điều kiện xây tại " + cell.data.cell_name)
		return false

	var cost = cell.get_build_cost()

	# Kiểm tra đủ tiền (AF7.7)
	if not FinanceManager.can_afford(player, cost):
		_emit("build", false, player.name + " không đủ tiền xây nhà (cần $" + str(cost) + ")")
		return false

	# Nếu đủ 4 nhà → nâng cấp khách sạn (BR-14)
	var action_label = "xây nhà"
	if cell.house_count == 4 and not cell.has_hotel:
		action_label = "nâng cấp khách sạn"

	FinanceManager.deduct(player, cost)
	cell.build_house()

	_emit("build", true, player.name + " " + action_label + " tại " + cell.data.cell_name + " (-$" + str(cost) + ")")
	return true


# =========================
# AF7.4 – Thế chấp tài sản (BR-19)
# =========================
func mortgage_property(player: Player, cell: PropertyCell) -> bool:
	if cell.property_owner != player:
		_emit("mortgage", false, "Không phải tài sản của bạn")
		return false

	# E7.2: Đã thế chấp rồi
	if cell.is_mortgaged:
		_emit("mortgage", false, cell.data.cell_name + " đã thế chấp rồi")
		return false

	# Phải bán nhà trước khi thế chấp
	if cell.house_count > 0 or cell.has_hotel:
		_emit("mortgage", false, "Phải bán nhà trước khi thế chấp " + cell.data.cell_name)
		return false

	var amount = cell.mortgage_property()
	FinanceManager.add(player, amount)

	_emit("mortgage", true, player.name + " thế chấp " + cell.data.cell_name + " nhận $" + str(amount))
	return true


# Chuộc lại tài sản (BR-20)
func redeem_property(player: Player, cell: PropertyCell) -> bool:
	if cell.property_owner != player:
		_emit("redeem", false, "Không phải tài sản của bạn")
		return false

	if not cell.is_mortgaged:
		_emit("redeem", false, cell.data.cell_name + " chưa bị thế chấp")
		return false

	var cost = cell.get_redeem_cost()
	if not FinanceManager.can_afford(player, cost):
		_emit("redeem", false, player.name + " không đủ tiền chuộc (cần $" + str(cost) + ")")
		return false

	FinanceManager.deduct(player, cost)
	cell.redeem_property()

	_emit("redeem", true, player.name + " chuộc lại " + cell.data.cell_name + " (-$" + str(cost) + ")")
	return true


# =========================
# AF7.5 – Bán tài sản cho người chơi khác (BR-22)
# =========================
func sell_property(seller: Player, buyer: Player, cell: PropertyCell, price: int) -> bool:
	# Kiểm tra quyền sở hữu
	if cell.property_owner != seller:
		_emit("sell", false, "Người bán không sở hữu tài sản này")
		return false

	# Tài sản không được thế chấp
	if cell.is_mortgaged:
		_emit("sell", false, "Tài sản đang thế chấp – không thể bán trực tiếp")
		return false

	# Người mua phải đủ tiền
	if not FinanceManager.can_afford(buyer, price):
		_emit("sell", false, buyer.name + " không đủ tiền mua (cần $" + str(price) + ")")
		return false

	# Thực hiện giao dịch
	FinanceManager.transfer(buyer, seller, price)
	cell.transfer_to(buyer)

	_emit("sell", true,
		seller.name + " bán " + cell.data.cell_name +
		" cho " + buyer.name + " với giá $" + str(price))
	return true


# =========================
# AF7.6 – Trao đổi tài sản giữa người chơi (BR-21)
# =========================
# Trao đổi: proposer đưa (offer_cells + offer_money) lấy (request_cells + request_money)
func trade_property(
	proposer: Player,
	receiver: Player,
	offer_cells: Array,        # Ô đất proposer đưa ra
	offer_money: int,          # Tiền proposer đưa ra
	request_cells: Array,      # Ô đất proposer muốn nhận
	request_money: int         # Tiền proposer muốn nhận
) -> bool:

	# Kiểm tra proposer sở hữu các ô offer
	for cell in offer_cells:
		if cell.property_owner != proposer:
			_emit("trade", false, proposer.name + " không sở hữu: " + cell.data.cell_name)
			return false

	# Kiểm tra receiver sở hữu các ô request
	for cell in request_cells:
		if cell.property_owner != receiver:
			_emit("trade", false, receiver.name + " không sở hữu: " + cell.data.cell_name)
			return false

	# Kiểm tra đủ tiền
	if offer_money > 0 and not FinanceManager.can_afford(proposer, offer_money):
		_emit("trade", false, proposer.name + " không đủ tiền trao đổi ($" + str(offer_money) + ")")
		return false

	if request_money > 0 and not FinanceManager.can_afford(receiver, request_money):
		_emit("trade", false, receiver.name + " không đủ tiền trao đổi ($" + str(request_money) + ")")
		return false

	# Thực hiện chuyển ô đất
	for cell in offer_cells:
		cell.transfer_to(receiver)

	for cell in request_cells:
		cell.transfer_to(proposer)

	# Thực hiện chuyển tiền
	if offer_money > 0:
		FinanceManager.transfer(proposer, receiver, offer_money)
	if request_money > 0:
		FinanceManager.transfer(receiver, proposer, request_money)

	_emit("trade", true,
		proposer.name + " và " + receiver.name + " trao đổi tài sản thành công")
	return true


# =========================
# Auction (BR-07: không mua thì đấu giá)
# =========================
func auction_property(cell: PropertyCell, players: Array) -> Player:
	# Đây là placeholder – trong game thực sẽ cần UI để player đấu giá
	# Hiện tại: tự động bán cho người chơi đầu tiên có đủ tiền
	var prop_data = cell.data as PropertyData
	if prop_data == null:
		return null

	var min_bid = prop_data.buy_price / 2
	for player in players:
		if FinanceManager.can_afford(player, min_bid) and not player.is_bankrupt():
			FinanceManager.deduct(player, min_bid)
			cell.property_owner = player
			player.add_property(cell)
			_emit("auction", true,
				player.name + " thắng đấu giá " + cell.data.cell_name + " với giá $" + str(min_bid))
			return player

	_emit("auction", false, "Không ai đấu giá " + cell.data.cell_name)
	return null


# =========================
# Helpers
# =========================
func _emit(action: String, success: bool, message: String):
	print("[AssetManager][", action.to_upper(), "] ", message)
	emit_signal("asset_action_completed", action, success, message)
