extends Node2D
class_name Cell

var index: int

@export var cell_name: String = "Ô Đất"
@export var price: int = 200         # Giá mua ô đất lúc ban đầu
@export var rent_price: int = 20     # Giá thu tiền thuê cơ bản

var is_mortgaged: bool = false       # Trạng thái thế chấp
var cell_owner: Player = null        # Đổi từ 'owner' thành 'cell_owner' để tránh trùng lặp

func _ready():
	queue_redraw()

# Số tiền thế chấp bằng chính xác 50% giá trị gốc
func get_mortgage_value() -> int:
	return int(price * 0.5)

# Cập nhật trạng thái tài sản thành "Đã thế chấp" và cộng tiền cho chủ
func mortgage_property():
	if not is_mortgaged and cell_owner != null:
		is_mortgaged = true
		var amount = get_mortgage_value()
		
		# Ngân hàng giải ngân tiền thế chấp vào tài khoản người chơi
		cell_owner.add_money(amount) 
		
		# Kích hoạt vẽ lại giao diện của ô đất
		queue_redraw() 
		return amount
	return 0

# Hàm chuộc lại đất đã thế chấp
func unmortgage_property():
	if is_mortgaged and cell_owner != null:
		var cost = get_mortgage_value() + int(get_mortgage_value() * 0.1)
		
		# Kiểm tra tiền qua state.balance của Player
		if cell_owner.state.balance >= cost:
			cell_owner.deduct_money(cost)
			is_mortgaged = false
			queue_redraw()
			return true
	return false

# Tính tiền thuê
func get_current_rent() -> int:
	if cell_owner == null or is_mortgaged:
		return 0
	return rent_price

func _draw():
	if is_mortgaged:
		# Vẽ một lớp phủ mờ màu xám để báo hiệu đất đang thế chấp
		draw_rect(Rect2(-25, -25, 50, 50), Color(0.2, 0.2, 0.2, 0.5))
