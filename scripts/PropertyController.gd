extends RefCounted
class_name PropertyController

# =========================
# PropertyController – UC7
# Kiểm tra điều kiện xây dựng (BR-12, BR-13, BR-14)
# và lấy danh sách ô theo màu
# =========================

# Kiểm tra player sở hữu đủ bộ màu (BR-12)
static func has_full_color_set(player: Player, color_name: String, all_cells: Array) -> bool:
	var color_cells = get_cells_by_color(color_name, all_cells)
	if color_cells.is_empty():
		return false
	for cell in color_cells:
		if cell.property_owner != player:
			return false
	return true


# Kiểm tra không có ô nào bị thế chấp trong bộ màu (BR-12)
static func has_no_mortgaged_in_set(player: Player, color_name: String, all_cells: Array) -> bool:
	var color_cells = get_cells_by_color(color_name, all_cells)
	for cell in color_cells:
		if cell.property_owner == player and cell.is_mortgaged:
			return false
	return true


# Kiểm tra có thể xây thêm nhà vào ô này không (BR-13: xây đồng đều)
static func can_build_on(target_cell: PropertyCell, player: Player, all_cells: Array) -> bool:
	var color_name = (target_cell.data as PropertyData).color_name

	# Điều kiện 1: sở hữu đủ bộ màu
	if not has_full_color_set(player, color_name, all_cells):
		return false

	# Điều kiện 2: không có ô bị thế chấp
	if not has_no_mortgaged_in_set(player, color_name, all_cells):
		return false

	# Điều kiện 3: ô target không có khách sạn
	if target_cell.has_hotel:
		return false

	# Điều kiện 4: xây đồng đều (BR-13)
	# Số nhà ở ô target không được cao hơn các ô còn lại cùng bộ màu
	var color_cells = get_cells_by_color(color_name, all_cells)
	var target_count = target_cell.house_count

	for cell in color_cells:
		if cell == target_cell:
			continue
		if not cell.has_hotel and cell.house_count < target_count:
			return false  # Ô khác ít nhà hơn → phải xây ở đó trước

	return true


# Lấy tất cả ô cùng màu từ board
static func get_cells_by_color(color_name: String, all_cells: Array) -> Array:
	var result = []
	for cell in all_cells:
		if cell is PropertyCell:
			var pd = cell.data as PropertyData
			if pd != null and pd.color_name == color_name:
				result.append(cell)
	return result


# Kiểm tra xây đồng đều khi bán nhà (BR-13 ngược lại)
static func can_sell_house_on(target_cell: PropertyCell, player: Player, all_cells: Array) -> bool:
	if target_cell.house_count == 0 and not target_cell.has_hotel:
		return false

	var color_name = (target_cell.data as PropertyData).color_name
	var color_cells = get_cells_by_color(color_name, all_cells)
	var target_count = target_cell.house_count

	for cell in color_cells:
		if cell == target_cell:
			continue
		if cell.house_count > target_count:
			return false  # Ô khác vẫn còn nhiều nhà hơn → không thể bán ở target trước

	return true
