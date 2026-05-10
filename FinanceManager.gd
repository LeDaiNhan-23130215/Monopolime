extends  RefCounted
class_name FinanceManager

# ==========================================
# UC6: QUẢN LÝ TÀI CHÍNH (FINANCE MANAGER)
# ==========================================

static func can_afford(player: Player, amount: int) -> bool:
	return player.state.balance >= amount

# [MỚI] Kiểm tra xem người chơi có THỰC SỰ phá sản không 
# (Tổng tiền mặt + Giá trị thế chấp đất + Bán nhà có đủ trả nợ không)
static func total_liquidity_check(player: Player, debt_amount: int) -> bool:
	return player.get_total_capacity() >= debt_amount

static func deduct(player: Player, amount: int) -> bool:
	if not can_afford(player, amount):
		return false
	
	player.deduct_money(amount)
	
	if player.token != null:
		player.token.update_balance_display(player.state.balance)
		player.token.show_floating_money(-amount)
	return true

static func add(player: Player, amount: int) -> void:
	player.add_money(amount)
	if player.token != null:
		player.token.update_balance_display(player.state.balance)
		player.token.show_floating_money(amount)

static func transfer(from_player: Player, to_player: Player, amount: int) -> bool:
	# Lưu ý: Trong phá sản, transfer có thể chuyển số tiền còn lại cuối cùng của debtor
	# ngay cả khi không đủ amount (chuyển sạch túi trước khi xóa player)
	var actual_amount = amount
	if not can_afford(from_player, amount):
		actual_amount = from_player.state.balance
		
	from_player.deduct_money(actual_amount)
	if from_player.token != null:
		from_player.token.update_balance_display(from_player.state.balance)
		from_player.token.show_floating_money(-actual_amount)
		
	if to_player != null:
		to_player.add_money(actual_amount)
		if to_player.token != null:
			to_player.token.update_balance_display(to_player.state.balance)
			to_player.token.show_floating_money(actual_amount)
			
	return true
