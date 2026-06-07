extends Cell
class_name PropertyCell

# =========================
# Ownership & Status
# =========================
var property_owner: Player = null
var is_mortgaged: bool = false
var house_count: int = 0      # 0–4 nhà
var has_hotel: bool = false   # true = có khách sạn (thay thế 4 nhà)


# =========================
# On Land
# =========================
func on_land(player: Player):
	if property_owner == null:
		print("Có thể mua: ", data.cell_name)
	elif property_owner != player:
		if is_mortgaged:
			print("Tài sản đang thế chấp – miễn tiền thuê")
		else:
			print("Trả tiền thuê: $", get_current_rent())


# =========================
# Rent Logic (BR-09, BR-10)
# =========================
func get_current_rent() -> int:
	if is_mortgaged:
		return 0

	var prop_data = data as PropertyData
	if prop_data == null:
		return 0

	# Có khách sạn
	if has_hotel:
		return prop_data.hotel_rent

	# Có nhà
	match house_count:
		1: return prop_data.house_1_rent
		2: return prop_data.house_2_rent
		3: return prop_data.house_3_rent
		4: return prop_data.house_4_rent

	# Không có nhà – kiểm tra full color set (BR-10: rent x2)
	if property_owner != null and _owner_has_full_color_set():
		return prop_data.base_rent * 2

	return prop_data.base_rent


func _owner_has_full_color_set() -> bool:
	if property_owner == null:
		return false
	var color = (data as PropertyData).color_name
	for prop in property_owner.properties:
		if prop is PropertyCell:
			var pd = prop.data as PropertyData
			if pd != null and pd.color_name == color and prop.is_mortgaged:
				return false
	return true


# =========================
# Mortgage Value (BR-19, BR-20)
# =========================
func get_mortgage_value() -> int:
	var prop_data = data as PropertyData
	if prop_data == null:
		return 0
	return prop_data.buy_price / 2


func get_redeem_cost() -> int:
	return int(get_mortgage_value() * 1.1)


# =========================
# Mortgage / Redeem
# =========================
func mortgage_property() -> int:
	if is_mortgaged:
		return 0
	if house_count > 0 or has_hotel:
		return 0  # Phải bán nhà trước
	is_mortgaged = true
	var amount = get_mortgage_value()
	queue_redraw()
	print("Thế chấp: ", data.cell_name, " → $", amount)
	return amount


func redeem_property() -> int:
	if not is_mortgaged:
		return 0
	is_mortgaged = false
	var cost = get_redeem_cost()
	queue_redraw()
	print("Chuộc lại: ", data.cell_name, " → -$", cost)
	return cost


# =========================
# Building (BR-11 – BR-14)
# =========================
func build_house() -> bool:
	if has_hotel:
		return false
	if house_count >= 4:
		house_count = 0
		has_hotel = true
		queue_redraw()
		print("Nâng cấp khách sạn tại: ", data.cell_name)
		return true
	house_count += 1
	queue_redraw()
	print("Xây nhà #", house_count, " tại: ", data.cell_name)
	return true


func upgrade_to_hotel() -> bool:
	if house_count < 4 or has_hotel:
		return false
	house_count = 0
	has_hotel = true
	queue_redraw()
	print("Nâng cấp khách sạn tại: ", data.cell_name)
	return true


func get_build_cost() -> int:
	var prop_data = data as PropertyData
	if prop_data == null:
		return 0
	return prop_data.build_cost


func sell_house() -> int:
	if has_hotel:
		has_hotel = false
		house_count = 4
		queue_redraw()
		var prop_data = data as PropertyData
		return prop_data.build_cost / 2 if prop_data else 0
	if house_count > 0:
		house_count -= 1
		queue_redraw()
		var prop_data = data as PropertyData
		return prop_data.build_cost / 2 if prop_data else 0
	return 0


# =========================
# Transfer Ownership (BR-21, BR-22)
# =========================
func transfer_to(new_owner: Player):
	if property_owner != null:
		property_owner.properties.erase(self)
	property_owner = new_owner
	if new_owner != null:
		new_owner.add_property(self)
	print("Chuyển nhượng: ", data.cell_name, " → ", new_owner.name if new_owner else "None")


func reset_property():
	property_owner = null
	is_mortgaged = false
	house_count = 0
	has_hotel = false
	queue_redraw()


# =========================
# Visual Đánh dấu Chủ sở hữu
# =========================
func _draw() -> void:
	# Nền ô kiểu thẻ: kem + viền xanh đậm
	draw_rect(Rect2(0, 0, 100, 100), CoTyPhuPalette.CREAM, true)
	draw_rect(Rect2(0, 0, 100, 100), CoTyPhuPalette.DEEP_BLUE, false, 2.0)

	# Thanh màu nhóm đất ở mép trên (theo color_name của dữ liệu)
	var pd0 = data as PropertyData
	if pd0 != null:
		var gc = CoTyPhuPalette.group_color(pd0.color_name)
		draw_rect(Rect2(0, 0, 100, 14), gc)
		draw_rect(Rect2(0, 0, 100, 14), gc.darkened(0.25), false, 1.0)

	if data != null:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(8, 32),
			CoTyPhuPalette.display_name(data.cell_name),
			HORIZONTAL_ALIGNMENT_LEFT,
			84, 13,
			CoTyPhuPalette.TEXT_DARK
		)
		# Hiển thị giá ở vị trí cố định (góc dưới trái) nếu chưa có chủ
		if property_owner == null:
			var pd = data as PropertyData
			if pd != null:
				draw_string(
					ThemeDB.fallback_font,
					Vector2(8, 90),
					"$" + str(pd.buy_price),
					HORIZONTAL_ALIGNMENT_LEFT,
					84, 14,
					Color("#0C7724")
				)

	if property_owner != null:
		var pc = CoTyPhuPalette.player_color(property_owner.player_id)

		# Nền màu đậm hơn để thấy rõ ai là chủ
		draw_rect(Rect2(0, 14, 100, 86), Color(pc.r, pc.g, pc.b, 0.45))
		# Dải màu đậm dưới đáy ô làm dấu chủ sở hữu nổi bật
		draw_rect(Rect2(0, 86, 100, 14), pc)
		# Viền dày, đậm bao quanh ô
		draw_rect(Rect2(0, 0, 100, 100), pc.darkened(0.15), false, 4.0)
		# Chấm tròn góc dưới phải
		draw_circle(Vector2(88, 88), 8, pc.darkened(0.2))
		draw_circle(Vector2(88, 88), 5, Color(1, 1, 1, 0.95))

	if is_mortgaged:
		draw_rect(Rect2(0, 0, 100, 100), Color(0.1, 0.1, 0.1, 0.55))
		draw_line(Vector2(5, 5), Vector2(95, 95), Color(1, 0.2, 0.2, 0.8), 2)
		draw_line(Vector2(95, 5), Vector2(5, 95), Color(1, 0.2, 0.2, 0.8), 2)
