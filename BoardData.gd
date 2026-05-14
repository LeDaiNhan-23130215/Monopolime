@tool
extends RefCounted
class_name BoardData

# Board configuration for a 40-cell Monopolime board.
# Cell types:
# go, property, railroad, utility, chance, community, tax, jail,
# go_to_jail, parking, teleport.

static func get_cell_configs() -> Array:
	return [
		_cell("Bắt đầu", "go", 0, 0, "", 0, [], "Nhận $200 khi đi ngang ô Bắt đầu"),
		_cell("Bến Thành", "property", 60, 2, "brown", 50, [2, 10, 30, 90, 160, 250]),
		_cell("Khí vận", "community", 0, 0),
		_cell("Chợ Lớn", "property", 60, 4, "brown", 50, [4, 20, 60, 180, 320, 450]),
		_cell("Thuế thu nhập", "tax", 0, 200, "", 0, [], "Đóng $200"),
		_cell("Ga Sài Gòn", "railroad", 200, 25, "", 0, [], "Tiền thuê tăng theo số ga sở hữu"),
		_cell("Đà Lạt", "property", 100, 6, "light_blue", 50, [6, 30, 90, 270, 400, 550]),
		_cell("Cơ hội", "chance", 0, 0),
		_cell("Nha Trang", "property", 100, 6, "light_blue", 50, [6, 30, 90, 270, 400, 550]),
		_cell("Vũng Tàu", "property", 120, 8, "light_blue", 50, [8, 40, 100, 300, 450, 600]),
		_cell("Thăm tù", "jail", 0, 0, "", 0, [], "Chỉ đi ngang hoặc thăm tù"),
		_cell("Huế", "property", 140, 10, "pink", 100, [10, 50, 150, 450, 625, 750]),
		_cell("Công ty điện", "utility", 150, 0, "", 0, [], "Tiền thuê = xúc xắc x 4 hoặc x 10"),
		_cell("Hội An", "property", 140, 10, "pink", 100, [10, 50, 150, 450, 625, 750]),
		_cell("Đà Nẵng", "property", 160, 12, "pink", 100, [12, 60, 180, 500, 700, 900]),
		_cell("Ga Hà Nội", "railroad", 200, 25, "", 0, [], "Tiền thuê tăng theo số ga sở hữu"),
		_cell("Cần Thơ", "property", 180, 14, "orange", 100, [14, 70, 200, 550, 750, 950]),
		_cell("Khí vận", "community", 0, 0),
		_cell("Mỹ Tho", "property", 180, 14, "orange", 100, [14, 70, 200, 550, 750, 950]),
		_cell("Phú Quốc", "property", 200, 16, "orange", 100, [16, 80, 220, 600, 800, 1000]),
		_cell("Bãi đậu xe", "parking", 0, 0),
		_cell("Thủ Đức", "property", 220, 18, "red", 150, [18, 90, 250, 700, 875, 1050]),
		_cell("Cơ hội", "chance", 0, 0),
		_cell("Bình Thạnh", "property", 220, 18, "red", 150, [18, 90, 250, 700, 875, 1050]),
		_cell("Quận 1", "property", 240, 20, "red", 150, [20, 100, 300, 750, 925, 1100]),
		_cell("Ga Đà Nẵng", "railroad", 200, 25, "", 0, [], "Tiền thuê tăng theo số ga sở hữu"),
		_cell("Quận 3", "property", 260, 22, "yellow", 150, [22, 110, 330, 800, 975, 1150]),
		_cell("Quận 7", "property", 260, 22, "yellow", 150, [22, 110, 330, 800, 975, 1150]),
		_cell("Nhà máy nước", "utility", 150, 0, "", 0, [], "Tiền thuê = xúc xắc x 4 hoặc x 10"),
		_cell("Phú Mỹ Hưng", "property", 280, 24, "yellow", 150, [24, 120, 360, 850, 1025, 1200]),
		_cell("Vào tù", "go_to_jail", 0, 0, "", 0, [], "Đi thẳng đến ô Thăm tù"),
		_cell("Hạ Long", "property", 300, 26, "green", 200, [26, 130, 390, 900, 1100, 1275]),
		_cell("Sapa", "property", 300, 26, "green", 200, [26, 130, 390, 900, 1100, 1275]),
		_cell("Khí vận", "community", 0, 0),
		_cell("Hà Nội", "property", 320, 28, "green", 200, [28, 150, 450, 1000, 1200, 1400]),
		_cell("Ga Cần Thơ", "railroad", 200, 25, "", 0, [], "Tiền thuê tăng theo số ga sở hữu"),
		_cell("Cơ hội", "chance", 0, 0),
		_cell("Sài Gòn", "property", 350, 35, "blue", 200, [35, 175, 500, 1100, 1300, 1500]),
		_cell("Thuế xa xỉ", "tax", 0, 100, "", 0, [], "Đóng $100"),
		_cell("Du lịch", "teleport", 0, 0, "", 0, [], "Chọn một ô để di chuyển"),
	]


static func _cell(
	cell_name: String,
	cell_type: String,
	price: int,
	rent: int,
	color := "",
	house_cost := 0,
	rent_levels := [],
	description := ""
) -> Dictionary:
	return {
		"name": cell_name,
		"type": cell_type,
		"price": price,
		"rent": rent,
		"color": color,
		"house_cost": house_cost,
		"rent_levels": rent_levels,
		"icon": _icon_for_type(cell_type),
		"description": description,
	}


static func _icon_for_type(cell_type: String) -> String:
	match cell_type:
		"go":
			return "GO"
		"chance":
			return "?"
		"community":
			return "BOX"
		"tax":
			return "$"
		"jail":
			return "JAIL"
		"go_to_jail":
			return "POLICE"
		"parking":
			return "P"
		"railroad":
			return "TRAIN"
		"utility":
			return "UTIL"
		"teleport":
			return "FLY"
	return ""


static func get_cells_in_group(color: String) -> Array:
	var result = []
	var configs = get_cell_configs()
	for i in range(configs.size()):
		if configs[i].get("color", "") == color:
			result.append(i)
	return result


static func get_group_size(color: String) -> int:
	return get_cells_in_group(color).size()
