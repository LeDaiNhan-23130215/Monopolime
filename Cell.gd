extends Node2D
class_name Cell

var index: int

@export var cell_name: String = "Ô Đất"
@export var price: int = 200         # Giá mua ô đất lúc ban đầu
@export var rent_price: int = 20     # Giá thu tiền thuê cơ bản

var is_mortgaged: bool = false       # Trạng thái thế chấp
var cell_owner: Player = null        # Đổi từ 'owner' thành 'cell_owner' để tránh trùng lặp

var _name_label: Label = null
var _price_label: Label = null
var _owner_label: Label = null

func _ready():
	z_index = 0
	
	# Label hiển thị tên ô đất
	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.text = cell_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05, 1))
	_name_label.set_size(Vector2(95, 55))
	_name_label.set_position(Vector2(3, 2))
	add_child(_name_label)
	
	# Label hiển thị giá tiền (chỉ với ô mua được)
	_price_label = Label.new()
	_price_label.name = "PriceLabel"
	_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_price_label.add_theme_font_size_override("font_size", 10)
	_price_label.add_theme_color_override("font_color", Color(0.0, 0.4, 0.1, 1))
	_price_label.set_size(Vector2(95, 20))
	_price_label.set_position(Vector2(3, 55))
	add_child(_price_label)
	
	# Label hiển thị tên chủ sở hữu (góc dưới)
	_owner_label = Label.new()
	_owner_label.name = "OwnerLabel"
	_owner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_owner_label.add_theme_font_size_override("font_size", 9)
	_owner_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_owner_label.set_size(Vector2(95, 16))
	_owner_label.set_position(Vector2(3, 76))
	_owner_label.visible = false
	add_child(_owner_label)
	
	_refresh_labels()
	queue_redraw()

# Gọi sau khi Board gán cell_name và price để cập nhật hiển thị
func refresh_display():
	_refresh_labels()
	queue_redraw()

func _refresh_labels():
	if _name_label:
		_name_label.text = cell_name
	if _price_label:
		if price > 0 and cell_owner == null:
			_price_label.text = "$" + str(price)
			_price_label.visible = true
		else:
			_price_label.visible = false
	if _owner_label:
		if cell_owner != null:
			var player_emojis = ["🔵", "🔴", "🟢", "🟡"]
			var emoji = player_emojis[cell_owner.player_id % player_emojis.size()]
			_owner_label.text = emoji + " " + cell_owner.name
			_owner_label.visible = true
		else:
			_owner_label.visible = false

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
	var owner_colors = [
		Color(0.25, 0.45, 1.0),   # Xanh dương - Player 0
		Color(1.0, 0.25, 0.25),   # Đỏ - Player 1
		Color(0.1, 0.8, 0.3),     # Xanh lá - Player 2
		Color(1.0, 0.75, 0.05),   # Vàng - Player 3
	]
	
	if cell_owner != null:
		var pc = owner_colors[cell_owner.player_id % owner_colors.size()]
		
		# Nền màu nhạt theo chủ
		var bg = Color(pc.r, pc.g, pc.b, 0.15)
		draw_rect(Rect2(0, 0, 100, 100), bg)
		
		# Viền sáng quanh ô
		draw_rect(Rect2(0, 0, 100, 100), Color(pc.r, pc.g, pc.b, 0.8), false, 2.5)
		
		# Thanh màu đậm 12px phía trên
		draw_rect(Rect2(0, 0, 100, 12), pc)
		
		# Chấm tròn nhỏ ở góc dưới bên phải (dấu hiệu nhận ra nhanh)
		draw_circle(Vector2(88, 88), 7, pc)
		draw_circle(Vector2(88, 88), 5, Color(1, 1, 1, 0.9))
	
	if is_mortgaged:
		# Overlay gạch chéo khi thế chấp
		draw_rect(Rect2(0, 0, 100, 100), Color(0.1, 0.1, 0.1, 0.55))
		draw_line(Vector2(5, 5), Vector2(95, 95), Color(1, 0.2, 0.2, 0.8), 2)
		draw_line(Vector2(95, 5), Vector2(5, 95), Color(1, 0.2, 0.2, 0.8), 2)
