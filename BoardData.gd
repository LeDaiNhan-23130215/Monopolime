@tool
extends RefCounted
class_name BoardData

# Board configuration for a 40-cell Monopolime board.
# Cell types:
# go, property, railroad, utility, chance, community, tax, jail,
# go_to_jail, parking, teleport.

static func get_cell_configs() -> Array:
	return [
		_cell("GO", "go", 0, 0, "", 0, [], "Receive $200 when passing GO"),
		_cell("Ben Thanh", "property", 60, 2, "brown", 50, [2, 10, 30, 90, 160, 250]),
		_cell("Community", "community", 0, 0),
		_cell("Cho Lon", "property", 60, 4, "brown", 50, [4, 20, 60, 180, 320, 450]),
		_cell("Income Tax", "tax", 0, 200, "", 0, [], "Pay $200"),
		_cell("Ga Sai Gon", "railroad", 200, 25, "", 0, [], "Rent scales by owned stations"),
		_cell("Da Lat", "property", 100, 6, "light_blue", 50, [6, 30, 90, 270, 400, 550]),
		_cell("Chance", "chance", 0, 0),
		_cell("Nha Trang", "property", 100, 6, "light_blue", 50, [6, 30, 90, 270, 400, 550]),
		_cell("Vung Tau", "property", 120, 8, "light_blue", 50, [8, 40, 100, 300, 450, 600]),
		_cell("Jail", "jail", 0, 0, "", 0, [], "Just visiting"),
		_cell("Hue", "property", 140, 10, "pink", 100, [10, 50, 150, 450, 625, 750]),
		_cell("Electric Co", "utility", 150, 0, "", 0, [], "Rent = dice x 4 or x 10"),
		_cell("Hoi An", "property", 140, 10, "pink", 100, [10, 50, 150, 450, 625, 750]),
		_cell("Da Nang", "property", 160, 12, "pink", 100, [12, 60, 180, 500, 700, 900]),
		_cell("Ga Ha Noi", "railroad", 200, 25, "", 0, [], "Rent scales by owned stations"),
		_cell("Can Tho", "property", 180, 14, "orange", 100, [14, 70, 200, 550, 750, 950]),
		_cell("Community", "community", 0, 0),
		_cell("My Tho", "property", 180, 14, "orange", 100, [14, 70, 200, 550, 750, 950]),
		_cell("Phu Quoc", "property", 200, 16, "orange", 100, [16, 80, 220, 600, 800, 1000]),
		_cell("Free Parking", "parking", 0, 0),
		_cell("Thu Duc", "property", 220, 18, "red", 150, [18, 90, 250, 700, 875, 1050]),
		_cell("Chance", "chance", 0, 0),
		_cell("Binh Thanh", "property", 220, 18, "red", 150, [18, 90, 250, 700, 875, 1050]),
		_cell("Quan 1", "property", 240, 20, "red", 150, [20, 100, 300, 750, 925, 1100]),
		_cell("Ga Da Nang", "railroad", 200, 25, "", 0, [], "Rent scales by owned stations"),
		_cell("Quan 3", "property", 260, 22, "yellow", 150, [22, 110, 330, 800, 975, 1150]),
		_cell("Quan 7", "property", 260, 22, "yellow", 150, [22, 110, 330, 800, 975, 1150]),
		_cell("Water Works", "utility", 150, 0, "", 0, [], "Rent = dice x 4 or x 10"),
		_cell("Phu My Hung", "property", 280, 24, "yellow", 150, [24, 120, 360, 850, 1025, 1200]),
		_cell("Go To Jail", "go_to_jail", 0, 0, "", 0, [], "Move directly to Jail"),
		_cell("Ha Long", "property", 300, 26, "green", 200, [26, 130, 390, 900, 1100, 1275]),
		_cell("Sapa", "property", 300, 26, "green", 200, [26, 130, 390, 900, 1100, 1275]),
		_cell("Community", "community", 0, 0),
		_cell("Ha Noi", "property", 320, 28, "green", 200, [28, 150, 450, 1000, 1200, 1400]),
		_cell("Ga Can Tho", "railroad", 200, 25, "", 0, [], "Rent scales by owned stations"),
		_cell("Chance", "chance", 0, 0),
		_cell("Sai Gon", "property", 350, 35, "blue", 200, [35, 175, 500, 1100, 1300, 1500]),
		_cell("Luxury Tax", "tax", 0, 100, "", 0, [], "Pay $100"),
		_cell("Travel", "teleport", 0, 0, "", 0, [], "Choose a destination cell"),
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
