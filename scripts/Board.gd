@tool
extends Node2D
class_name Board

var cell_positions: Array[Vector2] = []
var cells = []

@export var cell_scene: PackedScene
@export var auto_center_in_editor := true
@export var size := 58

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

	for c in cells_node.get_children():
		c.queue_free()

	cells.clear()
	cell_positions.clear()

	$Cells.z_index = 0
	$Tokens.z_index = 3

	_create_40_cell_positions()
	_spawn_cells(cells_node)
	_create_cell_labels()
	_create_center_decoration()
	center_board()


func _create_40_cell_positions():
	for i in range(11):
		cell_positions.append(start + Vector2(i * size, 0))

	for i in range(1, 10):
		cell_positions.append(start + Vector2(10 * size, i * size))

	for i in range(10, -1, -1):
		cell_positions.append(start + Vector2(i * size, 10 * size))

	for i in range(9, 0, -1):
		cell_positions.append(start + Vector2(0, i * size))


func _spawn_cells(cells_node: Node):
	var configs = BoardData.get_cell_configs()
	var cell_scale = float(size) / 100.0

	for i in range(cell_positions.size()):
		var cell = cell_scene.instantiate()
		cell.position = cell_positions[i]
		cell.scale = Vector2.ONE * cell_scale

		if cell.get_script() != null:
			cell.set("index", i)

		cells_node.add_child(cell)
		cells.append(cell)

		if i < configs.size():
			cell.setup(configs[i])


func _create_cell_labels():
	if has_node("Labels"):
		$Labels.queue_free()
		await get_tree().process_frame

	var labels_node = Node2D.new()
	labels_node.name = "Labels"
	labels_node.z_index = 2
	add_child(labels_node)

	for i in range(cells.size()):
		var cell = cells[i]

		var name_label = Label.new()
		name_label.text = cell.cell_name
		name_label.position = cell_positions[i] + Vector2(2, size - 22)
		name_label.add_theme_font_size_override("font_size", 7)
		name_label.size = Vector2(size - 4, 22)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		name_label.add_theme_color_override("font_color", _font_color_for_cell(cell))
		labels_node.add_child(name_label)

		if cell.price > 0:
			var price_label = Label.new()
			price_label.text = "$" + str(cell.price)
			price_label.position = cell_positions[i] + Vector2(2, size - 34)
			price_label.add_theme_font_size_override("font_size", 8)
			price_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
			price_label.size = Vector2(size - 4, 14)
			price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			labels_node.add_child(price_label)


func _font_color_for_cell(cell: Cell) -> Color:
	match cell.cell_type:
		"go":
			return Color(0.3, 1.0, 0.5)
		"chance":
			return Color(1.0, 0.7, 0.3)
		"community":
			return Color(0.5, 0.7, 1.0)
		"tax":
			return Color(1.0, 0.4, 0.4)
		"jail":
			return Color(0.7, 0.7, 0.7)
		"go_to_jail":
			return Color(1.0, 0.3, 0.3)
		"teleport":
			return Color(0.4, 0.9, 1.0)
	return Color(0.85, 0.88, 0.92)


func _create_center_decoration():
	if has_node("CenterDeco"):
		$CenterDeco.queue_free()
		await get_tree().process_frame

	var center_node = Node2D.new()
	center_node.name = "CenterDeco"
	center_node.z_index = 1
	add_child(center_node)

	var center_x = size
	var center_y = size
	var center_w = 9 * size
	var center_h = 9 * size

	var bg = ColorRect.new()
	bg.position = Vector2(center_x, center_y)
	bg.size = Vector2(center_w, center_h)
	bg.color = Color(0.12, 0.35, 0.22, 1.0)
	center_node.add_child(bg)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0)
	panel_style.border_color = Color(0.8, 0.7, 0.3, 0.5)
	panel_style.set_border_width_all(2)

	var panel = Panel.new()
	panel.position = Vector2(center_x + 8, center_y + 8)
	panel.size = Vector2(center_w - 16, center_h - 16)
	panel.add_theme_stylebox_override("panel", panel_style)
	center_node.add_child(panel)

	var title = Label.new()
	title.text = "MONOPOLIME"
	title.position = Vector2(center_x + 50, center_y + center_h * 0.34)
	title.size = Vector2(center_w - 100, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("outline_size", 8)
	center_node.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Co Ty Phu Viet Nam"
	subtitle.position = Vector2(center_x + 50, center_y + center_h * 0.48)
	subtitle.size = Vector2(center_w - 100, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.9, 0.85))
	center_node.add_child(subtitle)

	var help = Label.new()
	help.text = "Roll dice to play\nBuy land - collect rent - build houses"
	help.position = Vector2(center_x + 30, center_y + center_h * 0.58)
	help.size = Vector2(center_w - 60, 60)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 11)
	help.add_theme_color_override("font_color", Color(0.65, 0.75, 0.7))
	center_node.add_child(help)


func center_board():
	if cell_positions.is_empty():
		return

	var board_size_vec = Vector2(
		cell_positions.max().x + size,
		cell_positions.max().y + size
	)
	var viewport_size = get_viewport_rect().size
	position = (viewport_size - board_size_vec) / 2 - Vector2(150, 0)


func clear_board():
	var cells_node = $Cells
	for c in cells_node.get_children():
		c.queue_free()
	cells.clear()
	cell_positions.clear()


func _process(_delta):
	if Engine.is_editor_hint() and auto_center_in_editor:
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
		if cells[i].cell_type == "jail":
			return i
	return 10


func count_railroads_owned(player: Player) -> int:
	var count = 0
	for cell in cells:
		if cell.cell_type == "railroad" and cell.cell_owner == player and not cell.is_mortgaged:
			count += 1
	return count


func count_utilities_owned(player: Player) -> int:
	var count = 0
	for cell in cells:
		if cell.cell_type == "utility" and cell.cell_owner == player and not cell.is_mortgaged:
			count += 1
	return count


func remove_player_token(player: Player):
	if player.token and is_instance_valid(player.token):
		print("Removing token for ", player.name)
		player.token.queue_free()


func reset_board():
	for cell in cells:
		cell.cell_owner = null
		cell.is_mortgaged = false
		cell.house_count = 0
		cell.has_protection_tower = false
		cell.price_modifier = 0
		cell.rent_modifier = 0
		cell.queue_redraw()
