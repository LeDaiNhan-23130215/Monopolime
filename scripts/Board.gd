@tool
extends Node2D
class_name Board

var cell_positions: Array[Vector2] = []
@export var cell_scene: PackedScene
@export var auto_center_in_editor := true
@export var size = 100
var start = Vector2(100, 100)

@export_tool_button("Clear Board")
var clear_action = clear_board

@export_tool_button("Generate Board")
var generate_action = generate_board

var cells = []
func get_cell_position(index: int) -> Vector2:
	var pos = cell_positions[index]
	return pos + Vector2(size / 2, size / 2)	

func _ready() -> void:
	generate_board()

func generate_board():
	print("GENERATE BOARD")
	
	var cells_node = $Cells
	
	# 🔥 clear cũ
	for c in cells_node.get_children():
		c.free()

	cells.clear()
	cell_positions.clear()

	$Cells.z_index = 0
	$Tokens.z_index = 1

	start = Vector2.ZERO

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


func _ready():
	# Khởi tạo các ô đất dựa trên danh sách vị trí
	for i in range(cell_positions.size()):
		var cell = cell_scene.instantiate()

		cell.position = cell_positions[i]

		# fix tool mode
		if cell.get_script() != null:
			cell.set("index", i)

		cells_node.add_child(cell)
		cells.append(cell)
	center_board()

func center_board():

	var board_size = Vector2(
		(cell_positions.max().x + size),
		(cell_positions.max().y + size)
	)

	var viewport_size = get_viewport_rect().size

	position = (
		viewport_size - board_size
	) / 2
	
func clear_board():
	var cells_node = $Cells

	for c in cells_node.get_children():
		c.free()

	cells.clear()
	cell_positions.clear()
	
func _process(_delta):
	if Engine.is_editor_hint() and auto_center_in_editor:
		center_board()
	
		
		# Có thể tùy chỉnh tên ô đất tại đây nếu cần
		# cell.cell_name = "Ô số " + str(i)

# Trả về tọa độ thế giới của ô đất để Token di chuyển tới
func get_cell_position(index: int) -> Vector2:
	if cell_positions.is_empty():
		return Vector2.ZERO
	return cell_positions[index % cell_positions.size()]

# Trả về đối tượng Cell cụ thể để GameController kiểm tra chủ sở hữu/giá thuê
func get_cell(index: int) -> Cell:
	if index >= 0 and index < cells.size():
		return cells[index]
	return null

# Hàm xóa Token của người chơi khi họ phá sản (UC-06)
func remove_player_token(player: Player):
	if player.token and is_instance_valid(player.token):
		print("Đang xóa Token của ", player.name, " khỏi bàn cờ.")
		player.token.queue_free()
		# Hoặc chỉ đơn giản là ẩn đi: player.token.visible = false

# (Tùy chọn) Hàm reset toàn bộ bàn cờ khi bắt đầu ván mới
func reset_board():
	for cell in cells:
		cell.cell_owner = null
		cell.is_mortgaged = false
		cell.queue_redraw()
