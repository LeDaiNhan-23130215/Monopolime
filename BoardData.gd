extends RefCounted
class_name BoardData

# Dữ liệu cấu hình cho 20 ô trên bàn cờ Monopolime
# Mỗi ô có: tên, loại, giá mua, giá thuê
# Loại ô: "go", "property", "chance", "community", "tax", "jail", "go_to_jail", "parking", "railroad", "utility"

static func get_cell_configs() -> Array:
	return [
		# ===== TOP ROW (0-5) =====
		{"name": "GO", "type": "go", "price": 0, "rent": 0},
		{"name": "Phú Mỹ Hưng", "type": "property", "price": 120, "rent": 12, "color": "brown"},
		{"name": "Cơ Hội", "type": "chance", "price": 0, "rent": 0},
		{"name": "Thủ Đức", "type": "property", "price": 140, "rent": 14, "color": "brown"},
		{"name": "Thuế thu nhập", "type": "tax", "price": 0, "rent": 200},
		{"name": "Ga Sài Gòn", "type": "railroad", "price": 200, "rent": 25},

		# ===== RIGHT COLUMN (6-9) =====
		{"name": "Quận 1", "type": "property", "price": 220, "rent": 22, "color": "green"},
		{"name": "Khí Vận", "type": "community", "price": 0, "rent": 0},
		{"name": "Quận 3", "type": "property", "price": 240, "rent": 24, "color": "green"},
		{"name": "Quận 7", "type": "property", "price": 260, "rent": 26, "color": "green"},

		# ===== BOTTOM ROW (10-15) =====
		{"name": "Nhà Tù", "type": "jail", "price": 0, "rent": 0},
		{"name": "Bình Thạnh", "type": "property", "price": 300, "rent": 30, "color": "yellow"},
		{"name": "Điện Lực", "type": "utility", "price": 150, "rent": 20},
		{"name": "Tân Bình", "type": "property", "price": 320, "rent": 32, "color": "yellow"},
		{"name": "Ga Hà Nội", "type": "railroad", "price": 200, "rent": 25},
		{"name": "Phú Nhuận", "type": "property", "price": 350, "rent": 35, "color": "red"},

		# ===== LEFT COLUMN (16-19) =====
		{"name": "Cơ Hội", "type": "chance", "price": 0, "rent": 0},
		{"name": "Đà Nẵng", "type": "property", "price": 400, "rent": 50, "color": "blue"},
		{"name": "Thuế xa xỉ", "type": "tax", "price": 0, "rent": 100},
		{"name": "Vào Tù", "type": "go_to_jail", "price": 0, "rent": 0},
	]
