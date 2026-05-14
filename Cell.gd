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
var has_protection_tower: bool = false
var protection_cost: int = 150
var price_modifier: int = 0
var rent_modifier: int = 0

# Giá xây nhà
var house_cost: int = 50

# Các bậc thuê nhà: [đất trống, 1 nhà, 2 nhà, 3 nhà, 4 nhà, khách sạn]
var rent_levels: Array = []

# Hiệu ứng
var effect_alpha: float = 0.0
var effect_color: Color = Color.WHITE
var upgrade_flash: float = 0.0
var upgrade_scale: float = 1.0

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


func get_modified_price() -> int:
	if price <= 0:
		return 0
	return max(1, price + price_modifier)


func get_modified_rent(base_rent: int) -> int:
	return max(0, base_rent + rent_modifier)


# =========================
# TIỀN THUÊ (Rent)
# =========================

func get_current_rent(dice_total: int = 0) -> int:
	if cell_owner == null or is_mortgaged:
		return 0

	match cell_type:
		"railroad":
			return get_modified_rent(_get_railroad_rent())
		"utility":
			return get_modified_rent(_get_utility_rent(dice_total))
		"property":
			return get_modified_rent(_get_property_rent())

	return get_modified_rent(rent_price)


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


func get_rent_preview_for_level(level: int, dice_total: int = 7) -> int:
	if cell_type == "railroad":
		return get_modified_rent(_get_railroad_rent())
	if cell_type == "utility":
		return get_modified_rent(_get_utility_rent(dice_total))
	if rent_levels.size() > 0:
		var safe_level = clamp(level, 0, rent_levels.size() - 1)
		return get_modified_rent(rent_levels[safe_level])
	return get_modified_rent(rent_price)


func get_build_level_name(level: int = -1) -> String:
	var target_level = house_count if level < 0 else level
	if target_level <= 0:
		return "Dat trong"
	if target_level < 4:
		return "Nha cap " + str(target_level)
	return "Cong trinh lon"


# =========================
# XÂY NHÀ
# =========================

# Kiểm tra có thể xây nhà không (luật xây đồng đều)
func can_build_house() -> bool:
	if cell_type != "property":
		return false
	if house_count >= 4:
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


func get_build_block_reason() -> String:
	if cell_type != "property":
		return "Chi dat moi xay duoc."
	if house_count >= 4:
		return "Da dat cap cong trinh lon nhat."
	if cell_owner == null:
		return "O chua co chu."
	if is_mortgaged:
		return "O dang the chap."
	if not _owner_has_full_color_set():
		return "Chua so huu du bo mau."
	if not _check_even_building():
		return "Can xay deu cac o cung mau."
	if cell_owner.state.balance < house_cost:
		return "Khong du tien."
	return ""


func build_house() -> bool:
	if not can_build_house():
		return false

	cell_owner.deduct_money(house_cost)
	house_count += 1
	queue_redraw()

	var type_name = "Công trình lớn" if house_count == 4 else "Nhà"
	print(cell_owner.name, " xây ", type_name, " trên ", cell_name, " (", house_count, "/4)")
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


func can_build_protection_tower(player: Player) -> bool:
	return (
		cell_owner == player
		and cell_type == "property"
		and not has_protection_tower
		and not is_mortgaged
		and player.state.balance >= protection_cost
	)


func build_protection_tower(player: Player) -> bool:
	if not can_build_protection_tower(player):
		return false
	player.deduct_money(protection_cost)
	has_protection_tower = true
	queue_redraw()
	play_upgrade_effect()
	return true


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

	if not is_inside_tree():
		_update_effect_alpha(0.0)
		return

	var tween = get_tree().create_tween()
	# Nhấp nháy 3 lần màu của người chơi
	tween.tween_method(_update_effect_alpha, 0.8, 0.0, 0.3)
	tween.tween_method(_update_effect_alpha, 0.8, 0.0, 0.3)
	tween.tween_method(_update_effect_alpha, 0.8, 0.0, 0.6)


func play_land_effect():
	effect_color = Color(1.0, 1.0, 0.4)
	if not is_inside_tree():
		_update_effect_alpha(0.0)
		return
	var tween = get_tree().create_tween()
	tween.tween_method(_update_effect_alpha, 0.55, 0.0, 0.5)


func play_upgrade_effect():
	effect_color = Color(1.0, 0.85, 0.2)
	upgrade_flash = 1.0
	upgrade_scale = 1.45
	queue_redraw()

	if not is_inside_tree():
		_set_upgrade_flash(0.0)
		return

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_method(_update_effect_alpha, 0.7, 0.0, 0.55)
	tween.tween_method(_set_upgrade_flash, 1.0, 0.0, 0.75)
	tween.tween_property(self, "upgrade_scale", 1.0, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_upgrade_flash(value: float):
	upgrade_flash = value
	queue_redraw()

func _update_effect_alpha(alpha: float):
	effect_alpha = alpha
	queue_redraw()

# =========================
# VẼ GIAO DIỆN Ô ĐẤT
# =========================

var cell_rect_size := Vector2(100, 100)
var cell_side := "corner"

func _draw():
	# --- Nền ô ---
	var bg_color = _get_cell_bg_color()
	draw_rect(Rect2(0, 0, cell_rect_size.x, cell_rect_size.y), bg_color)

	# --- Viền ô ---
	var border_color = Color("#D4BCA0") # Lighter brown/gray border instead of dark
	draw_rect(Rect2(0, 0, cell_rect_size.x, cell_rect_size.y), border_color, false, 3.0)

	# --- Thanh màu nhóm (hướng vào tâm bàn cờ) ---
	if color_group != "":
		var group_color = _get_group_color()
		var bar_rect := Rect2()
		var bar_w = 20
		match cell_side:
			"top":
				bar_rect = Rect2(0, cell_rect_size.y - bar_w, cell_rect_size.x, bar_w)
			"bottom":
				bar_rect = Rect2(0, 0, cell_rect_size.x, bar_w)
			"left":
				bar_rect = Rect2(cell_rect_size.x - bar_w, 0, bar_w, cell_rect_size.y)
			"right":
				bar_rect = Rect2(0, 0, bar_w, cell_rect_size.y)
			_:
				bar_rect = Rect2(0, 0, cell_rect_size.x, bar_w)
				
		draw_rect(bar_rect, group_color)
		# Viền thanh màu
		draw_rect(bar_rect, Color(0, 0, 0, 0.5), false, 1.5)

	# --- Chỉ báo thế chấp ---
	if is_mortgaged:
		# Lớp phủ mờ
		draw_rect(Rect2(0, 0, cell_rect_size.x, cell_rect_size.y), Color(0.1, 0.1, 0.1, 0.85))
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
		draw_rect(Rect2(0, 0, cell_rect_size.x, cell_rect_size.y), Color(owner_color.r, owner_color.g, owner_color.b, 0.08))
		
		# Viền dày màu chủ sở hữu (bên trong border thường)
		draw_rect(Rect2(2, 2, cell_rect_size.x - 4, cell_rect_size.y - 4), owner_color, false, 3.0)
		
		# Thanh màu dưới cùng (thể hiện người sở hữu)
		draw_rect(Rect2(0, cell_rect_size.y - 14, cell_rect_size.x, 14), owner_color)
		
		# Hiển thị tên chủ sở hữu trong thanh dưới
		var short_name = cell_owner.name.left(6)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(cell_rect_size.x / 2 - 25, cell_rect_size.y - 3),
			short_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			50,
			10,
			Color(0.05, 0.05, 0.05, 1.0)
		)

	# --- Vẽ nhà ---
	var house_base_y = 26
	if cell_side == "bottom": house_base_y = 12
	elif cell_side == "top": house_base_y = cell_rect_size.y - 20
	
	if house_count > 0 and house_count < 4:
		var spacing = cell_rect_size.x / 4.0
		var h_w = spacing * 0.72
		for i in range(house_count):
			var house_x = (i + 0.5) * spacing
			var h_h = 8 + i * 2
			draw_rect(Rect2(house_x + 1, house_base_y + 1, h_w, h_h), Color(0, 0, 0, 0.45))
			draw_rect(Rect2(house_x, house_base_y, h_w, h_h), Color(0.2, 0.8, 0.3).lightened(i * 0.08))
			var roof = PackedVector2Array([
				Vector2(house_x, house_base_y),
				Vector2(house_x + h_w / 2, house_base_y - 5 - i),
				Vector2(house_x + h_w, house_base_y)
			])
			draw_colored_polygon(roof, Color(0.1, 0.55, 0.2))

	elif house_count >= 4:
		var big_w = cell_rect_size.x * 0.64
		var big_x = (cell_rect_size.x - big_w) / 2
		var big_h = 18
		draw_rect(Rect2(big_x + 2, house_base_y + 1, big_w, big_h), Color(0, 0, 0, 0.42))
		draw_rect(Rect2(big_x, house_base_y - 4, big_w, big_h + 4), Color(0.9, 0.16, 0.12))
		draw_rect(Rect2(big_x, house_base_y - 4, big_w, big_h + 4), Color(0.45, 0.02, 0.0), false, 2.0)
		for i in range(3):
			draw_rect(Rect2(big_x + 8 + i * (big_w / 3.4), house_base_y + 1, 5, 5), Color(1.0, 0.9, 0.45))
		var flag_x = big_x + big_w * 0.5
		draw_line(Vector2(flag_x, house_base_y - 17), Vector2(flag_x, house_base_y - 4), Color.YELLOW, 2.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(flag_x, house_base_y - 17),
			Vector2(flag_x + 9, house_base_y - 13),
			Vector2(flag_x, house_base_y - 9)
		]), Color(1.0, 0.82, 0.0))

	if upgrade_flash > 0.0:
		draw_circle(Vector2(cell_rect_size.x / 2.0, 24), 24 * upgrade_scale, Color(1.0, 0.9, 0.25, upgrade_flash * 0.4))

	if has_protection_tower:
		draw_rect(Rect2(cell_rect_size.x - 32, 18, 16, 28), Color(0.25, 0.45, 1.0))
		draw_circle(Vector2(cell_rect_size.x - 24, 16), 8, Color(0.6, 0.85, 1.0))
		draw_string(ThemeDB.fallback_font, Vector2(cell_rect_size.x - 38, 58), "SHIELD", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)

	if price_modifier != 0 or rent_modifier != 0:
		var modifier_text = ""
		if price_modifier != 0:
			modifier_text += ("P+" if price_modifier > 0 else "P") + str(price_modifier)
		if rent_modifier != 0:
			if modifier_text != "":
				modifier_text += " "
			modifier_text += ("R+" if rent_modifier > 0 else "R") + str(rent_modifier)
		draw_string(ThemeDB.fallback_font, Vector2(6, 50), modifier_text, HORIZONTAL_ALIGNMENT_LEFT, 90, 8, Color(1.0, 0.9, 0.25))

	# --- Vẽ icon đặc biệt ---
	if cell_type != "property" and icon != "":
		draw_string(
			ThemeDB.fallback_font,
			Vector2(cell_rect_size.x / 2 - 40, cell_rect_size.y / 2 + 25),
			icon,
			HORIZONTAL_ALIGNMENT_CENTER,
			80,
			70
		)

	# --- Hiệu ứng nhấp nháy khi có sự kiện (như mua đất) ---
	if effect_alpha > 0.0:
		draw_rect(Rect2(0, 0, cell_rect_size.x, cell_rect_size.y), Color(effect_color.r, effect_color.g, effect_color.b, effect_alpha))


func _get_cell_bg_color() -> Color:
	match cell_type:
		"go":
			return Color("#E2F0D9") # Light green
		"chance":
			return Color("#FFF2CC") # Light yellow/orange
		"community":
			return Color("#DDEBF7") # Light blue
		"tax":
			return Color("#FCE4D6") # Light red/peach
		"jail":
			return Color("#F8CBAD") # Light orange/red
		"go_to_jail":
			return Color("#F4B084")
		"parking":
			return Color("#E2EFDA")
		"railroad":
			return Color("#EDEDED")
		"utility":
			return Color("#F2F2F2")
		"teleport":
			return Color("#D9E1F2")
		"property":
			return Color("#FFF9EB") # Cream/light yellow for default property
	return Color("#FFF9EB")


func _get_group_color() -> Color:
	match color_group:
		"brown": return Color("#8B4513")
		"light_blue": return Color("#87CEEB")
		"pink": return Color("#FF69B4")
		"orange": return Color("#FFA500")
		"red": return Color("#FF0000")
		"yellow": return Color("#FFD700")
		"green": return Color("#008000")
		"blue": return Color("#0000FF")
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
