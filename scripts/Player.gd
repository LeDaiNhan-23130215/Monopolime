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

func add_special_card(card):
	special_card.append(card)

func get_random_token():
	if token:
		token.token_texture = token.get_random_token_texture()

func add_money(amount: int):
	state.add_balance(amount)
	print(name, " nhận $", amount, ". Số dư mới: $", state.balance)

func deduct_money(amount: int):
	state.deduct_balance(amount)
	print(name, " bị trừ $", amount, ". Số dư mới: $", state.balance)

func is_bankrupt() -> bool:
	return state.bankrupt

# Tính tổng khả năng tài chính (Tiền mặt + Giá trị thế chấp tối đa)
func get_total_capacity() -> int:
	var total_mortgage = 0
	for cell in properties:
		if not cell.is_mortgaged:
			total_mortgage += cell.get_mortgage_value()
	return state.balance + total_mortgage

# Giải phóng toàn bộ tài sản về Ngân hàng khi phá sản.
# Không chuyển cho người chơi khác — đất được reset hoàn toàn.
func release_all_assets():
	for cell in properties:
		cell.reset_property()
	state.balance = 0
	properties.clear()
	special_card.clear()
	state.set_bankrupt(true)
	print("--- ", name, " ĐÃ PHÁ SẢN – Toàn bộ tài sản giải phóng về Ngân hàng ---")
