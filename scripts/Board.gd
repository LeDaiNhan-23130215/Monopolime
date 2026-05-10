@tool
extends Node2D
class_name Board

var cell_positions: Array[Vector2] = []
var cells = []

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


func _ready() -> void:
	generate_board()


func generate_board():
	print("GENERATE BOARD")

	var cells_node = $Cells

	# Clear cũ
	for c in cells_node.get_children():
		c.queue_free()

	cells.clear()
	cell_positions.clear()

	$Cells.z_index = 0
	$Tokens.z_index = 1

	# =========================
	# Tạo vị trí board
	# =========================

	# TOP
	for i in range(6):
		cell_positions.append(start + Vector2(i * size, 0))

	# RIGHT
	for i in range(1, 5):
		cell_positions.append(start + Vector2(5 * size, i * size))

	# BOTTOM
	for i in range(5, -1, -1):
		cell_positions.append(start + Vector2(i * size, 5 * size))

	# LEFT
	for i in range(4, 0, -1):
		cell_positions.append(start + Vector2(0, i * size))

	# =========================
	# Spawn cell
	# =========================

	for i in range(cell_positions.size()):
		var cell = cell_scene.instantiate()

		cell.position = cell_positions[i]

		if cell.get_script() != null:
			cell.set("index", i)
			if i < default_cell_names.size():
				cell.set("cell_name", default_cell_names[i])
				
				# Ô sự kiện hoặc đặc biệt không thể mua được (giá = 0)
				if default_cell_names[i] in ["Bắt Đầu", "Khí Vận", "Thuế", "Nhà Tù", "Cơ Hội", "Bãi Đỗ Xe", "Vào Tù"]:
					cell.set("price", 0)

		cells_node.add_child(cell)
		cells.append(cell)
		
		# _ready() đã được gọi khi add_child → refresh Labels ngay
		if cell.has_method("refresh_display"):
			cell.refresh_display()

	center_board()


func center_board():
	if cell_positions.is_empty():
		return

	var board_size = Vector2(
		cell_positions.max().x + size,
		cell_positions.max().y + size
	)

	var viewport_size = get_viewport_rect().size

	position = (viewport_size - board_size) / 2


func clear_board():
	var cells_node = $Cells

	for c in cells_node.get_children():
		c.queue_free()

	cells.clear()
	cell_positions.clear()


func _process(_delta):
	if Engine.is_editor_hint() and auto_center_in_editor:
		center_board()


# Trả về tọa độ thế giới của ô đất để Token di chuyển tới
func get_cell_position(index: int) -> Vector2:
	if cell_positions.is_empty():
		return Vector2.ZERO

	return cell_positions[index % cell_positions.size()] + Vector2(size / 2, size / 2)


# Trả về đối tượng Cell cụ thể
func get_cell(index: int) -> Cell:
	if index >= 0 and index < cells.size():
		return cells[index]

	return null


# Xóa token khi phá sản
func remove_player_token(player: Player):
	if player.token and is_instance_valid(player.token):
		print("Đang xóa Token của ", player.name, " khỏi bàn cờ.")
		player.token.queue_free()


# Reset board
func reset_board():
	for cell in cells:
		cell.cell_owner = null
		cell.is_mortgaged = false
		cell.queue_redraw()
