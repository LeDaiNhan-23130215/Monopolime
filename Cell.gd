extends Node2D
class_name Cell

var index: int

@export var cell_name: String = "Ô Đất"
@export var cell_type: String = "property"   # go, property, chance, community, tax, jail, go_to_jail, parking, railroad, utility
@export var price: int = 200         # Giá mua ô đất lúc ban đầu
@export var rent_price: int = 20     # Giá thu tiền thuê cơ bản
@export var color_group: String = "" # Nhóm màu

var is_mortgaged: bool = false       # Trạng thái thế chấp
var cell_owner: Player = null        # Đổi từ 'owner' thành 'cell_owner' để tránh trùng lặp
var house_count: int = 0             # Số nhà đã xây (0-4, 5 = khách sạn)

# Các hệ số nhân tiền thuê khi có nhà
const HOUSE_MULTIPLIERS = [1.0, 5.0, 15.0, 45.0, 80.0, 125.0]

func _ready():
	z_index = 0
	queue_redraw()

# Cấu hình ô từ dữ liệu
func setup(data: Dictionary):
	cell_name = data.get("name", "Ô Đất")
	cell_type = data.get("type", "property")
	price = data.get("price", 0)
	rent_price = data.get("rent", 0)
	color_group = data.get("color", "")
	queue_redraw()

# Kiểm tra có thể mua không
func can_be_purchased() -> bool:
	return cell_owner == null and price > 0 and cell_type in ["property", "railroad", "utility"]

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

	if cell_type == "railroad":
		# Nhà ga: thuê tăng theo số ga sở hữu
		return rent_price

	if cell_type == "utility":
		return rent_price

	# Đất thường: thuê tăng theo số nhà
	if house_count >= 0 and house_count <= 5:
		return int(rent_price * HOUSE_MULTIPLIERS[house_count])

	return rent_price

# Xây nhà
func build_house() -> bool:
	if cell_type != "property":
		return false
	if house_count >= 5:
		return false
	if cell_owner == null:
		return false

	var cost = get_house_cost()
	if cell_owner.state.balance >= cost:
		cell_owner.deduct_money(cost)
		house_count += 1
		queue_redraw()
		return true
	return false

# Giá xây nhà dựa trên giá đất
func get_house_cost() -> int:
	return int(price * 0.6)

func _draw():
	# Vẽ viền màu nhóm
	if color_group != "":
		var group_color = _get_group_color()
		draw_rect(Rect2(-5, -5, 110, 15), group_color)

	# Vẽ lớp phủ khi đã thế chấp
	if is_mortgaged:
		draw_rect(Rect2(-5, -5, 110, 110), Color(0.2, 0.2, 0.2, 0.5))

	# Vẽ viền chủ sở hữu
	if cell_owner != null:
		var owner_color = _get_owner_color()
		draw_rect(Rect2(-5, 90, 110, 8), owner_color)

	# Vẽ số nhà
	if house_count > 0 and house_count < 5:
		for i in range(house_count):
			draw_rect(Rect2(5 + i * 22, -15, 18, 10), Color.GREEN)
	elif house_count == 5:
		# Khách sạn
		draw_rect(Rect2(25, -18, 50, 14), Color.RED)


func _get_group_color() -> Color:
	match color_group:
		"brown": return Color(0.55, 0.27, 0.07)
		"light_blue": return Color(0.53, 0.81, 0.92)
		"pink": return Color(0.85, 0.44, 0.84)
		"orange": return Color(1.0, 0.55, 0.0)
		"red": return Color(0.9, 0.1, 0.1)
		"yellow": return Color(1.0, 0.85, 0.0)
		"green": return Color(0.0, 0.6, 0.0)
		"blue": return Color(0.0, 0.0, 0.7)
	return Color.GRAY


func _get_owner_color() -> Color:
	if cell_owner == null:
		return Color.TRANSPARENT
	match cell_owner.player_id:
		0: return Color.RED
		1: return Color.BLUE
		2: return Color.GREEN
		3: return Color.YELLOW
	return Color.WHITE
