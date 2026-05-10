extends RefCounted
class_name FinanceManager

# =========================
# FinanceManager – UC7
# Xử lý giao dịch tài chính (UC-6 include)
# =========================

# Kiểm tra người chơi có đủ tiền không
static func can_afford(player: Player, amount: int) -> bool:
	return player.state.balance >= amount


# Trừ tiền (deduct) – trả về true nếu thành công
static func deduct(player: Player, amount: int) -> bool:
	if not can_afford(player, amount):
		return false
	player.deduct_money(amount)
	return true


# Cộng tiền (add)
static func add(player: Player, amount: int) -> void:
	player.add_money(amount)


# Chuyển tiền từ người này sang người kia
static func transfer(from_player: Player, to_player: Player, amount: int) -> bool:
	if not can_afford(from_player, amount):
		return false
	from_player.deduct_money(amount)
	if to_player != null:
		to_player.add_money(amount)
	return true
