extends Resource
class_name Player

var player_id: int
var name: String

var state: PlayerState
var properties: Array = []
var special_card: Array = []

var token: PlayerToken

func _init(id := 0, player_name := "Player"):
	player_id = id
	name = player_name
	state = PlayerState.new()
	
func add_property(property):
	properties.append(property)

func add_special_card(special_card):
	pass
func add_special_card(card):
	special_card.append(card)

func get_random_token():
	if token:
		token.token_texture = token.get_random_token_texture()

# Cộng trừ tiền mặt thông qua state
func add_money(amount: int):
	state.add_balance(amount)
	print(name, " nhận $", amount, ". Số dư mới: $", state.balance)

func deduct_money(amount: int):
	state.deduct_balance(amount)
	print(name, " bị trừ $", amount, ". Số dư mới: $", state.balance)

# Hàm kiểm tra trạng thái phá sản (Lấy từ state)
func is_bankrupt() -> bool:
	return state.bankrupt

# Tính tổng khả năng tài chính (Tiền mặt + Giá trị thế chấp tối đa)
func get_total_capacity() -> int:
	var total_mortgage = 0
	for cell in properties:
		if not cell.is_mortgaged:
			total_mortgage += cell.get_mortgage_value()
	return state.balance + total_mortgage

# Chuyển giao toàn bộ tài sản khi phá sản
func transfer_all_assets_to(creditor: Player):
	if creditor != null:
		# 1. Chuyển tiền mặt
		creditor.add_money(state.balance)
		
		# 2. Chuyển quyền sở hữu đất đai
		for cell in properties:
			cell.owner = creditor
			creditor.add_property(cell) # Dùng hàm add_property để đồng bộ
			
		# 3. Chuyển các thẻ đặc biệt
		for card in special_card:
			creditor.add_special_card(card)
			
	# Xóa sạch tài sản của người phá sản
	state.balance = 0
	properties.clear()
	special_card.clear()
	
	# Cập nhật trạng thái phá sản vào state
	state.set_bankrupt(true) 
	print("--- ", name, " ĐÃ CHÍNH THỨC PHÁ SẢN VÀ CHUYỂN GIAO TÀI SẢN ---")
