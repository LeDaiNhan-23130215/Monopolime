extends RefCounted
class_name FinanceManager

# =========================
# FinanceManager – UC7
# Xử lý giao dịch tài chính
# =========================

# Kiểm tra người chơi có đủ tiền không
static func can_afford(player: Player, amount: int) -> bool:
	if player == null:
		return false

	return player.balance >= amount


# Trừ tiền
static func deduct(player: Player, amount: int) -> bool:
	if player == null:
		return false

	if amount <= 0:
		return false

	if not can_afford(player, amount):
		return false

	player.deduct_money(amount)
	return true


# Cộng tiền
static func add(player: Player, amount: int) -> void:
	if player == null:
		return

	if amount <= 0:
		return

	player.add_money(amount)


# Chuyển tiền
static func transfer(
		from_player: Player,
		to_player: Player,
		amount: int
	) -> bool:

	if from_player == null:
		return false

	if amount <= 0:
		return false

	if not can_afford(from_player, amount):
		return false

	from_player.deduct_money(amount)

	if to_player != null:
		to_player.add_money(amount)

	return true


# =========================
# CHỨC NĂNG MỚI 1
# Xem số dư
# =========================
static func get_balance(player: Player) -> int:
	if player == null:
		return 0

	return player.balance


# =========================
# CHỨC NĂNG MỚI 2
# Nhận lãi suất
# =========================
static func apply_interest(
		player: Player,
		rate: float
	) -> int:

	if player == null:
		return 0

	if rate <= 0:
		return 0

	var interest := int(player.balance * rate / 100.0)

	player.add_money(interest)

	return interest
