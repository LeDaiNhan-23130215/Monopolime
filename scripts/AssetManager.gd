extends Node
class_name AssetManager

# =========================
# AssetManager – UC7: Quản lý tài sản
# Triết lý: Mua → Sở hữu | Bán / Phá sản → Giải phóng về Ngân hàng
# Không có trao đổi hoặc chuyển nhượng giữa người chơi.
# =========================

signal asset_action_completed(action: String, success: bool, message: String)

var board: Board


func _get_all_cells() -> Array:
	if board == null:
		return []
	return board.cells


# =========================
# AF7.2 – Mua tài sản (BR-07)
# =========================
func buy_property(player: Player, cell: PropertyCell) -> bool:
	if cell.property_owner != null:
		_emit("buy", false, "Ô đất đã có chủ: " + cell.data.cell_name)
		return false

	var prop_data = cell.data as PropertyData
	if prop_data == null:
		_emit("buy", false, "Dữ liệu tài sản không hợp lệ")
		return false

	var price = prop_data.buy_price

	if not FinanceManager.can_afford(player, price):
		_emit("buy", false, player.name + " không đủ tiền mua " + cell.data.cell_name)
		return false

	FinanceManager.deduct(player, price)
	cell.property_owner = player
	player.add_property(cell)
	cell.queue_redraw()

	_emit("buy", true, player.name + " mua " + cell.data.cell_name + " với giá $" + str(price))
	return true


# =========================
# Chuyển nhượng tài sản (dùng cho đấu giá)
# price: số tiền người mua phải trả (không nhất thiết bằng buy_price)
# =========================
func transfer_property(player: Player, cell: PropertyCell, price: int) -> bool:
	if cell.property_owner != null:
		_emit("auction", false, "Ô đất đã có chủ: " + cell.data.cell_name)
		return false

	var prop_data = cell.data as PropertyData
	if prop_data == null:
		_emit("auction", false, "Dữ liệu tài sản không hợp lệ")
		return false

	if not FinanceManager.can_afford(player, price):
		_emit("auction", false, player.name + " không đủ tiền mua " + cell.data.cell_name + " với giá $" + str(price))
		return false

	FinanceManager.deduct(player, price)
	cell.property_owner = player
	player.add_property(cell)
	cell.queue_redraw()

	_emit("auction", true, player.name + " thắng đấu giá " + cell.data.cell_name + " với giá $" + str(price))
	return true


# =========================
# AF7.3 – Xây nhà / Khách sạn (BR-11–BR-14)
# =========================
func build_house(player: Player, cell: PropertyCell) -> bool:
	var all_cells = _get_all_cells()

	if cell.property_owner != player:
		_emit("build", false, "Không phải tài sản của bạn")
		return false

	if cell.is_mortgaged:
		_emit("build", false, "Tài sản đang thế chấp: " + cell.data.cell_name)
		return false

	if not PropertyController.can_build_on(cell, player, all_cells):
		_emit("build", false, "Không đủ điều kiện xây tại " + cell.data.cell_name)
		return false

	var cost = cell.get_build_cost()

	if not FinanceManager.can_afford(player, cost):
		_emit("build", false, player.name + " không đủ tiền xây nhà (cần $" + str(cost) + ")")
		return false

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

	if cell.is_mortgaged:
		_emit("mortgage", false, cell.data.cell_name + " đã thế chấp rồi")
		return false

	if cell.house_count > 0 or cell.has_hotel:
		_emit("mortgage", false, "Phải bán nhà trước khi thế chấp " + cell.data.cell_name)
		return false

	var amount = cell.mortgage_property()
	FinanceManager.add(player, amount)

	_emit("mortgage", true, player.name + " thế chấp " + cell.data.cell_name + " nhận $" + str(amount))
	return true


# =========================
# Chuộc lại tài sản (BR-20)
# =========================
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
# AF7.5 – Bán nhà / Khách sạn về Ngân hàng (nhận 50% chi phí xây)
# =========================
func sell_house_to_bank(player: Player, cell: PropertyCell) -> bool:
	if cell.property_owner != player:
		_emit("sell_house", false, "Không phải tài sản của bạn")
		return false

	if cell.house_count == 0 and not cell.has_hotel:
		_emit("sell_house", false, cell.data.cell_name + " không có nhà hoặc khách sạn để bán")
		return false

	var had_hotel = cell.has_hotel
	var refund = cell.sell_house()
	if refund <= 0:
		_emit("sell_house", false, "Bán nhà thất bại tại " + cell.data.cell_name)
		return false

	FinanceManager.add(player, refund)
	cell.queue_redraw()

	var label = "khách sạn" if had_hotel else "nhà"
	_emit("sell_house", true,
		player.name + " bán " + label + " tại " + cell.data.cell_name + " nhận $" + str(refund))
	return true


# =========================
# AF7.6 – Bán đất về Ngân hàng (nhận 50% giá mua ban đầu)
# Điều kiện bắt buộc: Không còn nhà/KS + Không đang thế chấp
# =========================
func sell_property_to_bank(player: Player, cell: PropertyCell) -> bool:
	if cell.property_owner != player:
		_emit("sell", false, "Không phải tài sản của bạn")
		return false

	if cell.house_count > 0 or cell.has_hotel:
		_emit("sell", false, "Phải bán hết nhà và khách sạn trước khi bán đất: " + cell.data.cell_name)
		return false

	if cell.is_mortgaged:
		_emit("sell", false, cell.data.cell_name + " đang thế chấp! Hãy chuộc lại trước khi bán.")
		return false

	var prop_data = cell.data as PropertyData
	if prop_data == null:
		_emit("sell", false, "Dữ liệu tài sản không hợp lệ")
		return false

	var refund = prop_data.buy_price / 2

	# Giải phóng ô đất về Ngân hàng
	player.properties.erase(cell)
	cell.reset_property()

	FinanceManager.add(player, refund)

	_emit("sell", true,
		player.name + " bán " + cell.data.cell_name + " về Ngân hàng, nhận $" + str(refund))
	return true


# =========================
# Helpers
# =========================
func _emit(action: String, success: bool, message: String):
	print("[AssetManager][", action.to_upper(), "] ", message)
	emit_signal("asset_action_completed", action, success, message)
