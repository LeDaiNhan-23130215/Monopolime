extends GutTest

# ==========================================
# TEST: can_afford
# ==========================================
func test_can_afford():
	var player = Player.new()
	player.balance = 100

	# Đủ tiền
	assert_true(FinanceManager.can_afford(player, 50))
	assert_true(FinanceManager.can_afford(player, 100))
	
	# Không đủ tiền
	assert_false(FinanceManager.can_afford(player, 101))
	
	# Player null
	assert_false(FinanceManager.can_afford(null, 50))


# ==========================================
# TEST: deduct
# ==========================================
func test_deduct():
	var player = Player.new()
	player.balance = 100

	# Trừ hợp lệ
	var result = FinanceManager.deduct(player, 40)
	assert_true(result)
	assert_eq(player.balance, 60)

	# Không đủ tiền
	var fail_result = FinanceManager.deduct(player, 100)
	assert_false(fail_result)
	assert_eq(player.balance, 60)

	# Số tiền không hợp lệ
	assert_false(FinanceManager.deduct(player, 0))
	assert_false(FinanceManager.deduct(player, -10))


# ==========================================
# TEST: add
# ==========================================
func test_add():
	var player = Player.new()
	player.balance = 100

	# Cộng hợp lệ
	FinanceManager.add(player, 50)
	assert_eq(player.balance, 150)

	# Số tiền <= 0 (không đổi số dư)
	FinanceManager.add(player, 0)
	FinanceManager.add(player, -20)
	assert_eq(player.balance, 150)


# ==========================================
# TEST: transfer
# ==========================================
func test_transfer():
	var player1 = Player.new()
	player1.balance = 100

	var player2 = Player.new()
	player2.balance = 50

	# Chuyển hợp lệ
	var result = FinanceManager.transfer(player1, player2, 30)
	assert_true(result)
	assert_eq(player1.balance, 70)
	assert_eq(player2.balance, 80)

	# Không đủ tiền chuyển
	var fail_result = FinanceManager.transfer(player1, player2, 100)
	assert_false(fail_result)
	assert_eq(player1.balance, 70) # Tiền không bị trừ
	assert_eq(player2.balance, 80) # Tiền không được cộng

	# Chuyển số tiền <= 0
	assert_false(FinanceManager.transfer(player1, player2, -10))


# ==========================================
# TEST: get_balance
# ==========================================
func test_get_balance():
	var player = Player.new()
	player.balance = 250

	assert_eq(FinanceManager.get_balance(player), 250)
	assert_eq(FinanceManager.get_balance(null), 0)


# ==========================================
# TEST: apply_interest
# ==========================================
func test_apply_interest():
	var player = Player.new()
	player.balance = 100

	# Lãi suất 5% của 100 là 5
	var interest = FinanceManager.apply_interest(player, 5.0)
	assert_eq(interest, 5)
	assert_eq(player.balance, 105)

	# Tỷ lệ <= 0
	assert_eq(FinanceManager.apply_interest(player, 0.0), 0)
	assert_eq(FinanceManager.apply_interest(player, -5.0), 0)
