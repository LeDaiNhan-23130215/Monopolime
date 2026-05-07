extends Node2D
class_name Board

@export var cell_positions: Array[Vector2] = []
@export var cell_scene: PackedScene

var cells = []

func _ready():
	# Khởi tạo các ô đất dựa trên danh sách vị trí
	for i in range(cell_positions.size()):
		var cell = cell_scene.instantiate()
		cell.position = cell_positions[i]
		cell.index = i
		
		add_child(cell)
		cells.append(cell)
		
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
