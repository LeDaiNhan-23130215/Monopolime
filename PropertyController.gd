extends RefCounted
class_name PropertyController

# =========================
# PropertyController – UC7
# Kiểm tra điều kiện xây dựng (BR-12, BR-13, BR-14)
# và lấy danh sách ô theo màu
# =========================

# Helper: mức xây của 1 ô (0–4 = số nhà, 5 = khách sạn)
# Tránh bug: khi has_hotel=true thì house_count reset về 0 → phải dùng hàm này
static func _build_level(cell: PropertyCell) -> int:
	return 5 if cell.has_hotel else cell.house_count


# Kiểm tra player sở hữu đủ bộ màu (BR-12)
static func has_full_color_set(player: Player, color_name: String, all_cells: Array) -> bool:
	var color_cells = get_cells_by_color(color_name, all_cells)
	if color_cells.is_empty():
		return false
	for cell in color_cells:
		if cell.cell_owner != player:
			return false
	return true


# Kiểm tra không có ô nào bị thế chấp trong bộ màu (BR-12)
static func has_no_mortgaged_in_set(player: Player, color_name: String, all_cells: Array) -> bool:
	var color_cells = get_cells_by_color(color_name, all_cells)
	for cell in color_cells:
		if cell.cell_owner == player and cell.is_mortgaged:
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
	
	# Điều kiện 4: player phải có đủ tiền xây nhà
	if not FinanceManager.can_afford(player, target_cell.house_cost):
		return false
		
	# Điều kiện 4: xây đồng đều (BR-13)
	# target phải có mức thấp nhất (hoặc bằng) trong bộ màu trước khi xây thêm
	var color_cells = get_cells_by_color(color_name, all_cells)
	var target_level = _build_level(target_cell)

	for cell in color_cells:
		if cell == target_cell:
			continue
		if _build_level(cell) < target_level:
			return false  # Ô khác thấp hơn → phải xây ở đó trước

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
	var target_level = _build_level(target_cell)

	for cell in color_cells:
		if cell == target_cell:
			continue
		if _build_level(cell) > target_level:
			return false  # Ô khác cao hơn → không thể bán ở target trước

	return true
