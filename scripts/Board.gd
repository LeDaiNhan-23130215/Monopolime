@tool
extends Node2D
class_name Board

var cell_positions: Array[Vector2] = []
var cells: Array[Cell] = []
var cell_metadata: Array = []  # Store {name, type, price} for each cell


# =========================
# Scenes
# =========================

@export var property_scene: PackedScene
@export var tax_scene: PackedScene
@export var chance_scene: PackedScene
@export var chest_scene: PackedScene
@export var special_scene: PackedScene


# =========================
# Editor
# =========================

var default_cell_names = [
	"Bắt Đầu", "Ô Đất 1", "Khí Vận", "Ô Đất 2", "Thuế", 
	"Nhà Tù", "Ô Đất 3", "Cơ Hội", "Ô Đất 4", "Ô Đất 5", 
	"Bãi Đỗ Xe", "Ô Đất 6", "Khí Vận", "Ô Đất 7", "Ô Đất 8", 
	"Vào Tù", "Ô Đất 9", "Cơ Hội", "Ô Đất 10", "Ô Đất 11"
]

@export var cell_scene: PackedScene
@export var auto_center_in_editor := true
@export var size := 100

var start := Vector2.ZERO

@export_tool_button("Clear Board")
var clear_action = clear_board

@export_tool_button("Generate Board")
var generate_action = generate_board


func _ready():
	generate_board()


# =========================
# Main Generate
# =========================

func generate_board():

	print("===== GENERATE BOARD =====")

	clear_board()

	var cells_node = $Cells

	$Cells.z_index = 0
	$Tokens.z_index = 3

	# =========================
	# Tạo vị trí board (6 cột × 6 hàng viền)
	# =========================

	# TOP (trái → phải)
	for i in range(6):
		cell_positions.append(
			start + Vector2(i * size, 0)
		)

	# RIGHT (trên → dưới)
	for i in range(1, 5):
		cell_positions.append(
			start + Vector2(5 * size, i * size)
		)

	# BOTTOM (phải → trái)
	for i in range(5, -1, -1):
		cell_positions.append(
			start + Vector2(i * size, 5 * size)
		)

	# LEFT (dưới → lên)
	for i in range(4, 0, -1):
		cell_positions.append(
			start + Vector2(0, i * size)
		)


	var configs = BoardData.get_cell_configs()
	for i in range(cell_positions.size()):

		var config = configs[i]

		if config == null:
			push_error(
				"configs[" + str(i) + "] is NULL"
			)
			continue

		# Create appropriate CellData type from config dictionary
		var data: CellData
		
		if config["type"] in ["property", "railroad", "utility"]:
			var prop_data = PropertyData.new()
			prop_data.cell_index = i
			prop_data.cell_name = config["name"]
			prop_data.cell_type = _get_cell_type_from_string(config["type"])
			prop_data.buy_price = config.get("price", 0)
			prop_data.base_rent = config.get("rent", 0)
			prop_data.color_name = config.get("color", "")
			prop_data.color_code = Color.WHITE
			prop_data.build_cost = config.get("house_cost", 0)
			prop_data.house_1_rent = config.get("rent_levels", [0, 0, 0, 0, 0, 0])[1] if config.get("rent_levels") else 0
			prop_data.house_2_rent = config.get("rent_levels", [0, 0, 0, 0, 0, 0])[2] if config.get("rent_levels") else 0
			prop_data.house_3_rent = config.get("rent_levels", [0, 0, 0, 0, 0, 0])[3] if config.get("rent_levels") else 0
			prop_data.house_4_rent = config.get("rent_levels", [0, 0, 0, 0, 0, 0])[4] if config.get("rent_levels") else 0
			prop_data.hotel_rent = config.get("rent_levels", [0, 0, 0, 0, 0, 0])[5] if config.get("rent_levels") else 0
			data = prop_data
		elif config["type"] == "tax":
			var tax_data = TaxData.new()
			tax_data.cell_index = i
			tax_data.cell_name = config["name"]
			tax_data.cell_type = _get_cell_type_from_string(config["type"])
			tax_data.tax_amount = config.get("rent", 0)
			data = tax_data
		else:
			data = CellData.new()
			data.cell_index = i
			data.cell_name = config["name"]
			data.cell_type = _get_cell_type_from_string(config["type"])

		print(
			"Spawn: ",
			i,
			" -> ",
			data.cell_name
		)

		var scene = get_scene_by_type(
			config["type"]
		)

		if scene == null:
			push_error(
				"Scene NULL at index " + str(i)
			)
			continue

		var cell: Cell = scene.instantiate()

		cell.position = cell_positions[i]

		cell.setup(data)

		cells_node.add_child(cell)

		cells.append(cell)
		
		# Store metadata for label creation
		cell_metadata.append({
			"name": data.cell_name,
			"type": config["type"],
			"price": config.get("price", 0)
		})
		
		# _ready() đã được gọi khi add_child → refresh Labels ngay
		if cell.has_method("refresh_display"):
			cell.refresh_display()

	# =========================
	# Tạo các lớp phủ giao diện
	# =========================
	_create_cell_labels()
	_create_center_decoration()

	center_board()


func get_scene_by_type(type):
	match type:
		"property", "railroad", "utility":
			return property_scene
		"tax":
			return tax_scene
		"chance":
			return chance_scene
		"community":
			return chest_scene
		_:
			return special_scene


func _get_cell_type_from_string(type_str: String) -> CellType.Type:
	match type_str:
		"property":
			return CellType.Type.PROPERTY
		"railroad":
			return CellType.Type.PROPERTY
		"utility":
			return CellType.Type.PROPERTY
		"tax":
			return CellType.Type.TAX
		"chance":
			return CellType.Type.CHANCE
		"community":
			return CellType.Type.CHEST
		"go":
			return CellType.Type.GO
		"go_to_jail":
			return CellType.Type.GO_TO_JAIL
		"jail":
			return CellType.Type.VISIT_JAIL
		"parking":
			return CellType.Type.PARKING
		_:
			return CellType.Type.PROPERTY



func _create_cell_labels():
	# Xóa labels cũ
	if has_node("Labels"):
		$Labels.queue_free()
		await get_tree().process_frame

	var labels_node = Node2D.new()
	labels_node.name = "Labels"
	labels_node.z_index = 2
	add_child(labels_node)

	for i in range(cells.size()):
		if i >= cell_metadata.size():
			break
			
		var metadata = cell_metadata[i]
		var cell = cells[i]

		# --- Label tên ô ---
		var name_label = Label.new()
		name_label.text = metadata["name"]
		name_label.position = cell_positions[i] + Vector2(2, 68)
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.size = Vector2(size - 4, 30)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD

		# Màu chữ tùy loại ô
		var font_color = Color(0.85, 0.88, 0.92)
		match metadata["type"]:
			"go": font_color = Color(0.3, 1.0, 0.5)
			"chance": font_color = Color(1.0, 0.7, 0.3)
			"community": font_color = Color(0.5, 0.7, 1.0)
			"tax": font_color = Color(1.0, 0.4, 0.4)
			"jail": font_color = Color(0.7, 0.7, 0.7)
			"go_to_jail": font_color = Color(1.0, 0.3, 0.3)
		name_label.add_theme_color_override("font_color", font_color)

		labels_node.add_child(name_label)

		# --- Label giá tiền ---
		if metadata["price"] > 0:
			var price_label = Label.new()
			price_label.text = "$" + str(metadata["price"])
			price_label.position = cell_positions[i] + Vector2(2, 54)
			price_label.add_theme_font_size_override("font_size", 10)
			price_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
			price_label.size = Vector2(size - 4, 15)
			price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			labels_node.add_child(price_label)


func _create_center_decoration():
	# Xóa cũ
	if has_node("CenterDeco"):
		$CenterDeco.queue_free()
		await get_tree().process_frame

	var center_node = Node2D.new()
	center_node.name = "CenterDeco"
	center_node.z_index = 1
	add_child(center_node)

	# Tính vùng trung tâm bàn cờ
	var center_x = size  # bắt đầu sau cột đầu
	var center_y = size
	var center_w = 4 * size  # 4 ô giữa
	var center_h = 4 * size

	# --- Background cho trung tâm ---
	var bg = ColorRect.new()
	bg.position = Vector2(center_x, center_y)
	bg.size = Vector2(center_w, center_h)
	bg.color = Color(0.12, 0.35, 0.22, 1.0) # Casino green
	center_node.add_child(bg)

	# --- Logo text ---
	var title = Label.new()
	title.text = "MONOPOLIME"
	title.position = Vector2(center_x + 50, center_y + 150)
	title.size = Vector2(center_w - 100, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	
	# Add outline
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("outline_size", 8)
	center_node.add_child(title)

	# --- Subtitle ---
	var subtitle = Label.new()
	subtitle.text = "🎲 Cờ Tỉ Phú Việt Nam 🎲"
	subtitle.position = Vector2(center_x + 50, center_y + 210)
	subtitle.size = Vector2(center_w - 100, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.9, 0.85))
	center_node.add_child(subtitle)

	# --- Đường viền trang trí ---
	var border = ColorRect.new()
	border.position = Vector2(center_x + 8, center_y + 8)
	border.size = Vector2(center_w - 16, center_h - 16)
	border.color = Color(0, 0, 0, 0)  # Trong suốt
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0,0,0,0)
	border_style.border_color = Color(0.8, 0.7, 0.3, 0.5)
	border_style.set_border_width_all(2)
	var panel = Panel.new()
	panel.position = border.position
	panel.size = border.size
	panel.add_theme_stylebox_override("panel", border_style)
	center_node.add_child(panel)

	# --- Hướng dẫn nhanh ---
	var help = Label.new()
	help.text = "Nhấn nút xúc xắc để bắt đầu\n🏠 Mua đất · 💰 Thu thuê · 🏗️ Xây nhà"
	help.position = Vector2(center_x + 30, center_y + 240)
	help.size = Vector2(center_w - 60, 60)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 11)
	help.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	center_node.add_child(help)

func center_board():

	if cell_positions.is_empty():
		return

	var board_size_vec = Vector2(
		cell_positions.max().x + size,
		cell_positions.max().y + size
	)

	var viewport_size = get_viewport_rect().size

	# Center the board, but shift it left by 100 pixels to make room for UI
	position = (viewport_size - board_size_vec) / 2 - Vector2(100, 0)


func clear_board():

	var cells_node = $Cells

	for c in cells_node.get_children():
		c.queue_free()

	cells.clear()
	cell_positions.clear()
	cell_metadata.clear()


func _process(_delta):

	if Engine.is_editor_hint() \
	and auto_center_in_editor:

		center_board()


func get_cell_position(cell_index: int) -> Vector2:
	if cell_positions.is_empty():
		return Vector2.ZERO

	return cell_positions[cell_index % cell_positions.size()] + Vector2(size / 2, size / 2)


func get_cell(cell_index: int) -> Cell:
	if cell_index >= 0 and cell_index < cells.size():
		return cells[cell_index]
	return null


func get_jail_position() -> int:
	for i in range(cells.size()):
		if cells[i].data and cells[i].data.cell_type == CellType.Type.VISIT_JAIL:
			return i
	return 10


# Đếm số nhà ga mà player sở hữu
func count_railroads_owned(player: Player) -> int:
	var count = 0
	for cell in cells:
		if cell is PropertyCell:
			var prop_data = cell.data as PropertyData
			if prop_data and prop_data.color_name == "railroad" and cell.property_owner == player and not cell.is_mortgaged:
				count += 1
	return count


# Đếm số tiện ích mà player sở hữu
func count_utilities_owned(player: Player) -> int:
	var count = 0
	for cell in cells:
		if cell is PropertyCell:
			var prop_data = cell.data as PropertyData
			if prop_data and prop_data.color_name == "utility" and cell.property_owner == player and not cell.is_mortgaged:
				count += 1
	return count


func remove_player_token(player: Player):

	if player.token \
	and is_instance_valid(player.token):

		player.token.queue_free()


func reset_board():

	for cell in cells:
		if cell is PropertyCell:
			cell.property_owner = null
			cell.is_mortgaged = false
			cell.house_count = 0
			cell.has_hotel = false
		cell.queue_redraw()
