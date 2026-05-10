extends Node
class_name FinanceManager

# ==========================================
# UC6: QUẢN LÝ TÀI CHÍNH (FINANCE MANAGER)
# Nhiệm vụ: Xử lý tiền tệ, kiểm tra số dư, phá sản
# ==========================================

# Kiểm tra người chơi có đủ tiền không
static func can_afford(player: Player, amount: int) -> bool:
	return player.state.balance >= amount

# Trừ tiền (deduct) – trả về true nếu thành công
static func deduct(player: Player, amount: int) -> bool:
	if not can_afford(player, amount):
		return false
		
	player.deduct_money(amount)
	
	# --- CẬP NHẬT GIAO DIỆN QUÂN CỜ ---
	if player.token != null:
		player.token.update_balance_display(player.state.balance)
		player.token.show_floating_money(-amount)
		
	return true


# Cộng tiền (add)
static func add(player: Player, amount: int) -> void:
	player.add_money(amount)
	
	# --- CẬP NHẬT GIAO DIỆN QUÂN CỜ ---
	if player.token != null:
		player.token.update_balance_display(player.state.balance)
		player.token.show_floating_money(amount)


# Chuyển tiền từ người này sang người kia
static func transfer(from_player: Player, to_player: Player, amount: int) -> bool:
	if not can_afford(from_player, amount):
		return false
		
	# 1. Trừ tiền người gửi
	from_player.deduct_money(amount)
	if from_player.token != null:
		from_player.token.update_balance_display(from_player.state.balance)
		from_player.token.show_floating_money(-amount)
		
	# 2. Cộng tiền người nhận
	if to_player != null:
		to_player.add_money(amount)
		if to_player.token != null:
			to_player.token.update_balance_display(to_player.state.balance)
			to_player.token.show_floating_money(amount)
			
	return true
