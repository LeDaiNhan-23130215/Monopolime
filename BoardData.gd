extends RefCounted
class_name BoardData

# =====================================================================
# Dữ liệu cấu hình cho 20 ô trên bàn cờ Monopolime
# Dựa trên luật Monopoly chuẩn quốc tế, tùy chỉnh cho phiên bản VN
# =====================================================================
# Loại ô:
#   "go"          - Ô xuất phát, nhận $200 khi đi qua
#   "property"    - Ô đất, có thể mua/xây nhà/thu thuê
#   "railroad"    - Nhà ga, thuê tùy theo số ga sở hữu
#   "utility"     - Tiện ích (Điện/Nước), thuê tùy theo xúc xắc
#   "chance"      - Thẻ Cơ Hội
#   "community"   - Thẻ Khí Vận
#   "tax"         - Thuế, nộp tiền cho ngân hàng
#   "jail"        - Nhà Tù (chỉ đi ngang qua)
#   "go_to_jail"  - Vào Tù ngay lập tức
#   "parking"     - Bãi đỗ xe miễn phí (không xảy ra gì)
# =====================================================================

static func get_cell_configs() -> Array:
	return [
		# ===== TOP ROW (0-5) =====
		{
			"name": "GO",
			"type": "go",
			"price": 0, "rent": 0,
			"icon": "🏁",
			"description": "Nhận $200 khi đi qua"
		},
		{
			"name": "Phú Mỹ Hưng",
			"type": "property",
			"price": 120, "rent": 12,
			"color": "brown",
			"house_cost": 50,
			"rent_levels": [12, 60, 180, 500, 700, 900],
			"icon": "🏘️"
		},
		{
			"name": "Cơ Hội",
			"type": "chance",
			"price": 0, "rent": 0,
			"icon": "❓"
		},
		{
			"name": "Thủ Đức",
			"type": "property",
			"price": 140, "rent": 14,
			"color": "brown",
			"house_cost": 50,
			"rent_levels": [14, 70, 200, 550, 750, 950],
			"icon": "🏘️"
		},
		{
			"name": "Thuế Thu Nhập",
			"type": "tax",
			"price": 0, "rent": 200,
			"icon": "💸",
			"description": "Nộp $200 cho ngân hàng"
		},
		{
			"name": "Ga Sài Gòn",
			"type": "railroad",
			"price": 200, "rent": 25,
			"icon": "🚂",
			"description": "Thuê tùy số ga sở hữu"
		},

		# ===== RIGHT COLUMN (6-9) =====
		{
			"name": "Quận 1",
			"type": "property",
			"price": 220, "rent": 22,
			"color": "green",
			"house_cost": 100,
			"rent_levels": [22, 110, 330, 800, 975, 1150],
			"icon": "🏙️"
		},
		{
			"name": "Khí Vận",
			"type": "community",
			"price": 0, "rent": 0,
			"icon": "📦"
		},
		{
			"name": "Quận 3",
			"type": "property",
			"price": 240, "rent": 24,
			"color": "green",
			"house_cost": 100,
			"rent_levels": [24, 120, 360, 850, 1025, 1200],
			"icon": "🏙️"
		},
		{
			"name": "Quận 7",
			"type": "property",
			"price": 260, "rent": 26,
			"color": "green",
			"house_cost": 100,
			"rent_levels": [26, 130, 390, 900, 1100, 1275],
			"icon": "🏙️"
		},

		# ===== BOTTOM ROW (10-15) =====
		{
			"name": "Nhà Tù",
			"type": "jail",
			"price": 0, "rent": 0,
			"icon": "🔒",
			"description": "Chỉ đi ngang qua"
		},
		{
			"name": "Bình Thạnh",
			"type": "property",
			"price": 300, "rent": 30,
			"color": "yellow",
			"house_cost": 150,
			"rent_levels": [30, 150, 450, 1000, 1200, 1400],
			"icon": "🏢"
		},
		{
			"name": "Điện Lực",
			"type": "utility",
			"price": 150, "rent": 0,
			"icon": "⚡",
			"description": "Thuê = xúc xắc × 4 (hoặc ×10)"
		},
		{
			"name": "Tân Bình",
			"type": "property",
			"price": 320, "rent": 32,
			"color": "yellow",
			"house_cost": 150,
			"rent_levels": [32, 160, 480, 1050, 1250, 1450],
			"icon": "🏢"
		},
		{
			"name": "Ga Hà Nội",
			"type": "railroad",
			"price": 200, "rent": 25,
			"icon": "🚂",
			"description": "Thuê tùy số ga sở hữu"
		},
		{
			"name": "Phú Nhuận",
			"type": "property",
			"price": 350, "rent": 35,
			"color": "red",
			"house_cost": 200,
			"rent_levels": [35, 175, 500, 1100, 1300, 1500],
			"icon": "🏗️"
		},

		# ===== LEFT COLUMN (16-19) =====
		{
			"name": "Cơ Hội",
			"type": "chance",
			"price": 0, "rent": 0,
			"icon": "❓"
		},
		{
			"name": "Đà Nẵng",
			"type": "property",
			"price": 400, "rent": 50,
			"color": "blue",
			"house_cost": 200,
			"rent_levels": [50, 200, 600, 1400, 1700, 2000],
			"icon": "🌆"
		},
		{
			"name": "Thuế Xa Xỉ",
			"type": "tax",
			"price": 0, "rent": 100,
			"icon": "💎",
			"description": "Nộp $100 cho ngân hàng"
		},
		{
			"name": "Vào Tù",
			"type": "go_to_jail",
			"price": 0, "rent": 0,
			"icon": "👮",
			"description": "Đi thẳng vào Nhà Tù!"
		},
	]


# Trả về danh sách các ô cùng nhóm màu
static func get_cells_in_group(color: String) -> Array:
	var result = []
	var configs = get_cell_configs()
	for i in range(configs.size()):
		if configs[i].get("color", "") == color:
			result.append(i)
	return result


# Trả về số ô đất trong mỗi nhóm màu
static func get_group_size(color: String) -> int:
	return get_cells_in_group(color).size()
