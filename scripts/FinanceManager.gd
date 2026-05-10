extends RefCounted
class_name FinanceManager

# =========================
# FinanceManager – UC7
# Xử lý giao dịch tài chính (UC-6 include)
# =========================

# Bỏ ép kiểu ': Player' để Godot không báo lỗi không nhận diện được class
static func can_afford(player, amount: int) -> bool:
	return player.state.balance >= amount


# Trừ tiền (deduct) – trả về true nếu thành công
static func deduct(player, amount: int) -> bool:
	if not can_afford(player, amount):
		return false
	player.deduct_money(amount)
	return true


# Cộng tiền (add)
static func add(player, amount: int) -> void:
	player.add_money(amount)


# Chuyển tiền từ người này sang người kia
static func transfer(from_player, to_player, amount: int) -> bool:
	if not can_afford(from_player, amount):
		return false
	from_player.deduct_money(amount)
	
	# Nếu to_player là null thì tiền tự bốc hơi (trả cho Ngân hàng)
	if to_player != null:
		to_player.add_money(amount)
	return true
