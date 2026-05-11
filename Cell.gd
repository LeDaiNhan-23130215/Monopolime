@tool
extends Node2D
class_name Cell

var index: int

@export var cell_name: String = "Ô Đất"
@export var cell_type: String = "property"
@export var price: int = 200
@export var rent_price: int = 20
@export var color_group: String = ""
@export var icon: String = ""
@export var description: String = ""

var is_mortgaged: bool = false
var cell_owner: Player = null
var house_count: int = 0

# Giá xây nhà
var house_cost: int = 50

# Các bậc thuê nhà: [đất trống, 1 nhà, 2 nhà, 3 nhà, 4 nhà, khách sạn]
var rent_levels: Array = []

# Hiệu ứng
var effect_alpha: float = 0.0
var effect_color: Color = Color.WHITE

# =========================
# INIT
# =========================

func _ready():
	z_index = 0
	queue_redraw()


func setup(data: Dictionary):
	cell_name = data.get("name", "Ô Đất")
	cell_type = data.get("type", "property")
	price = data.get("price", 0)
	rent_price = data.get("rent", 0)
	color_group = data.get("color", "")
	icon = data.get("icon", "")
	description = data.get("description", "")
	house_cost = data.get("house_cost", 50)
	rent_levels = data.get("rent_levels", [])
	queue_redraw()


# =========================
# MUA BÁN
# =========================

func can_be_purchased() -> bool:
	return cell_owner == null and price > 0 and cell_type in ["property", "railroad", "utility"]


# =========================
# TIỀN THUÊ (Rent)
# =========================

func get_current_rent(dice_total: int = 0) -> int:
	if cell_owner == null or is_mortgaged:
		return 0

	match cell_type:
		"railroad":
			return _get_railroad_rent()
		"utility":
			return _get_utility_rent(dice_total)
		"property":
			return _get_property_rent()

	return rent_price


# Thuê nhà ga: tùy theo số ga sở hữu
# 1 ga = $25, 2 ga = $50, 3 ga = $100, 4 ga = $200
func _get_railroad_rent() -> int:
	if cell_owner == null:
		return 0

	var railroad_count = 0
	for prop in cell_owner.properties:
		if prop.cell_type == "railroad" and not prop.is_mortgaged:
			railroad_count += 1

	match railroad_count:
		1: return 25
		2: return 50
		3: return 100
		4: return 200

	return 25


# Thuê tiện ích: tùy theo số tiện ích sở hữu và xúc xắc
# 1 tiện ích = xúc xắc × 4
# 2 tiện ích = xúc xắc × 10
func _get_utility_rent(dice_total: int) -> int:
	if cell_owner == null:
		return 0

	var utility_count = 0
	for prop in cell_owner.properties:
		if prop.cell_type == "utility" and not prop.is_mortgaged:
			utility_count += 1

	var multiplier = 4 if utility_count == 1 else 10
	return dice_total * multiplier


# Thuê đất thường: tùy theo số nhà và rent_levels
func _get_property_rent() -> int:
	if cell_owner == null:
		return 0

	# Nếu có rent_levels thì dùng
	if rent_levels.size() > 0 and house_count >= 0 and house_count < rent_levels.size():
		var base = rent_levels[house_count]

		# Nếu có đủ bộ màu và chưa xây nhà -> thuê gấp đôi
		if house_count == 0 and _owner_has_full_color_set():
			return base * 2

		return base

	return rent_price


# =========================
# XÂY NHÀ
# =========================

# Kiểm tra có thể xây nhà không (luật xây đồng đều)
func can_build_house() -> bool:
	if cell_type != "property":
		return false
	if house_count >= 5:
		return false
	if cell_owner == null:
		return false
	if is_mortgaged:
		return false

	# Phải có đủ bộ màu
	if not _owner_has_full_color_set():
		return false

	# Kiểm tra luật xây đồng đều
	if not _check_even_building():
		return false

	# Kiểm tra đủ tiền
	if cell_owner.state.balance < house_cost:
		return false

	return true


func build_house() -> bool:
	if not can_build_house():
		return false

	cell_owner.deduct_money(house_cost)
	house_count += 1
	queue_redraw()

	var type_name = "Khách sạn" if house_count == 5 else "Nhà"
	print(cell_owner.name, " xây ", type_name, " trên ", cell_name, " (", house_count, "/5)")
	return true


# Bán nhà lại cho ngân hàng (nửa giá)
func sell_house() -> bool:
	if house_count <= 0:
		return false
	if cell_owner == null:
		return false

	# Kiểm tra luật bán đồng đều
	if not _check_even_selling():
		return false

	var refund = int(house_cost * 0.5)
	cell_owner.add_money(refund)
	house_count -= 1
	queue_redraw()
	print(cell_owner.name, " bán nhà trên ", cell_name, " nhận $", refund)
	return true


# =========================
# THẾ CHẤP (Mortgage)
# =========================

func get_mortgage_value() -> int:
	return int(price * 0.5)


# Phải bán hết nhà trước khi thế chấp
func can_mortgage() -> bool:
	if is_mortgaged or cell_owner == null:
		return false
	if house_count > 0:
		return false

	# Kiểm tra không có nhà trên bất kỳ ô nào cùng màu
	if color_group != "":
		for prop in cell_owner.properties:
			if prop.color_group == color_group and prop.house_count > 0:
				return false

	return true


func mortgage_property() -> int:
	if not can_mortgage():
		return 0

	is_mortgaged = true
	var amount = get_mortgage_value()
	cell_owner.add_money(amount)
	queue_redraw()
	return amount


# Giải chấp: trả giá gốc + 10% lãi
func unmortgage_property() -> bool:
	if not is_mortgaged or cell_owner == null:
		return false

	var cost = get_mortgage_value() + int(get_mortgage_value() * 0.1)

	if cell_owner.state.balance >= cost:
		cell_owner.deduct_money(cost)
		is_mortgaged = false
		queue_redraw()
		return true
	return false


# =========================
# KIỂM TRA BỘ MÀU
# =========================

func _owner_has_full_color_set() -> bool:
	if cell_owner == null or color_group == "":
		return false

	var group_size = BoardData.get_group_size(color_group)
	var owned_count = 0

	for prop in cell_owner.properties:
		if prop.color_group == color_group:
			owned_count += 1

	return owned_count >= group_size


# Luật xây đồng đều: không được xây nhà thứ N+1 nếu ô khác chưa có N nhà
func _check_even_building() -> bool:
	for prop in cell_owner.properties:
		if prop.color_group == color_group and prop != self:
			if prop.house_count < house_count:
				return false
	return true


# Luật bán đồng đều: không được bán nhà nếu ô khác cùng màu có nhiều nhà hơn
func _check_even_selling() -> bool:
	for prop in cell_owner.properties:
		if prop.color_group == color_group and prop != self:
			if prop.house_count > house_count:
				return false
	return true


# =========================
# HIỆU ỨNG (Effects)
# =========================

func play_buy_effect():
	effect_color = _get_owner_color()
	if effect_color == Color.TRANSPARENT:
		effect_color = Color.WHITE
		
	var tween = get_tree().create_tween()
	# Nhấp nháy 3 lần màu của người chơi
	tween.tween_method(_update_effect_alpha, 0.8, 0.0, 0.3)
	tween.tween_method(_update_effect_alpha, 0.8, 0.0, 0.3)
	tween.tween_method(_update_effect_alpha, 0.8, 0.0, 0.6)

func _update_effect_alpha(alpha: float):
	effect_alpha = alpha
	queue_redraw()

# =========================
# VẼ GIAO DIỆN Ô ĐẤT
# =========================

func _draw():
	var cell_size = Vector2(100, 100)

	# --- Nền ô ---
	var bg_color = _get_cell_bg_color()
	draw_rect(Rect2(0, 0, cell_size.x, cell_size.y), bg_color)

	# --- Viền ô ---
	var border_color = Color(0.5, 0.55, 0.6, 0.9)
	draw_rect(Rect2(0, 0, cell_size.x, cell_size.y), border_color, false, 2.0)

	# --- Thanh màu nhóm (trên cùng) ---
	if color_group != "":
		var group_color = _get_group_color()
		draw_rect(Rect2(0, 0, cell_size.x, 22), group_color)
		# Viền thanh màu
		draw_rect(Rect2(0, 0, cell_size.x, 22), Color(0, 0, 0, 0.5), false, 1.5)

	# --- Chỉ báo thế chấp ---
	if is_mortgaged:
		# Lớp phủ mờ
		draw_rect(Rect2(0, 0, cell_size.x, cell_size.y), Color(0.1, 0.1, 0.1, 0.85))
		# Chữ "CẦM CỐ"
		draw_string(
			ThemeDB.fallback_font,
			Vector2(10, 58),
			"CẦM CỐ",
			HORIZONTAL_ALIGNMENT_CENTER,
			80,
			14,
			Color(1.0, 0.2, 0.2)
		)

	# --- Tô sáng ô đã có chủ sở hữu ---
	if cell_owner != null and not is_mortgaged:
		var owner_color = _get_owner_color()
		
		# Overlay màu nhẹ bên trong ô để tô sáng
		draw_rect(Rect2(0, 0, cell_size.x, cell_size.y), Color(owner_color.r, owner_color.g, owner_color.b, 0.08))
		
		# Viền dày màu chủ sở hữu (bên trong border thường)
		draw_rect(Rect2(2, 2, cell_size.x - 4, cell_size.y - 4), owner_color, false, 3.0)
		
		# Thanh màu dưới cùng (thể hiện người sở hữu)
		draw_rect(Rect2(0, cell_size.y - 14, cell_size.x, 14), owner_color)
		
		# Hiển thị tên chủ sở hữu trong thanh dưới
		var short_name = cell_owner.name.left(6)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(50, cell_size.y - 3),
			short_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			cell_size.x,
			10,
			Color(0.05, 0.05, 0.05, 1.0)
		)

	# --- Vẽ nhà ---
	if house_count > 0 and house_count < 5:
		for i in range(house_count):
			var house_x = 8 + i * 22
			# Bóng
			draw_rect(Rect2(house_x + 1, 24, 18, 12), Color(0, 0, 0, 0.5))
			# Nhà
			draw_rect(Rect2(house_x, 23, 18, 12), Color(0.2, 0.8, 0.3))
			# Mái
			var points = PackedVector2Array([
				Vector2(house_x, 23),
				Vector2(house_x + 9, 14),
				Vector2(house_x + 18, 23)
			])
			draw_colored_polygon(points, Color(0.1, 0.6, 0.2))

	elif house_count == 5:
		# Khách sạn
		draw_rect(Rect2(25, 22, 50, 18), Color(0.9, 0.15, 0.15))
		draw_rect(Rect2(25, 22, 50, 18), Color(0.4, 0.0, 0.0), false, 2.0)
		# Cờ
		draw_line(Vector2(50, 10), Vector2(50, 22), Color.YELLOW, 2.0)
		var flag_points = PackedVector2Array([
			Vector2(50, 10),
			Vector2(60, 14),
			Vector2(50, 18)
		])
		draw_colored_polygon(flag_points, Color(1.0, 0.8, 0.0))

	# --- Vẽ icon đặc biệt ---
	if cell_type != "property" and icon != "":
		draw_string(
			ThemeDB.fallback_font,
			Vector2(35, 75),
			icon,
			HORIZONTAL_ALIGNMENT_CENTER,
			40,
			28
		)

	# --- Hiệu ứng nhấp nháy khi có sự kiện (như mua đất) ---
	if effect_alpha > 0.0:
		draw_rect(Rect2(0, 0, cell_size.x, cell_size.y), Color(effect_color.r, effect_color.g, effect_color.b, effect_alpha))


func _get_cell_bg_color() -> Color:
	match cell_type:
		"go":
			return Color(0.15, 0.35, 0.2)
		"chance":
			return Color(0.4, 0.25, 0.1)
		"community":
			return Color(0.1, 0.25, 0.4)
		"tax":
			return Color(0.35, 0.15, 0.15)
		"jail":
			return Color(0.3, 0.2, 0.15)
		"go_to_jail":
			return Color(0.5, 0.15, 0.15)
		"parking":
			return Color(0.15, 0.3, 0.15)
		"railroad":
			return Color(0.2, 0.2, 0.25)
		"utility":
			return Color(0.25, 0.25, 0.3)
		"property":
			return Color(0.15, 0.18, 0.22)
	return Color(0.15, 0.15, 0.15)


func _get_group_color() -> Color:
	match color_group:
		"brown": return Color(0.55, 0.27, 0.07)
		"light_blue": return Color(0.53, 0.81, 0.92)
		"pink": return Color(0.85, 0.44, 0.84)
		"orange": return Color(1.0, 0.55, 0.0)
		"red": return Color(0.9, 0.15, 0.15)
		"yellow": return Color(1.0, 0.85, 0.0)
		"green": return Color(0.0, 0.65, 0.3)
		"blue": return Color(0.15, 0.25, 0.85)
	return Color.GRAY


func _get_owner_color() -> Color:
	if cell_owner == null:
		return Color.TRANSPARENT
	match cell_owner.player_id:
		0: return Color(0.95, 0.3, 0.3)
		1: return Color(0.3, 0.5, 0.95)
		2: return Color(0.3, 0.9, 0.4)
		3: return Color(0.95, 0.9, 0.3)
	return Color.WHITE
