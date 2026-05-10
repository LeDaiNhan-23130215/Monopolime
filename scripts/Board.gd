@tool
extends Node2D
class_name Board

var cell_positions: Array[Vector2] = []
var cells: Array[Cell] = []
var board_layout = []


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

	create_board_layout()

	$Cells.z_index = 0
	$Tokens.z_index = 1


	# TOP
	for i in range(6):
		cell_positions.append(
			start + Vector2(i * size, 0)
		)

	# RIGHT
	for i in range(1, 5):
		cell_positions.append(
			start + Vector2(5 * size, i * size)
		)

	# BOTTOM
	for i in range(5, -1, -1):
		cell_positions.append(
			start + Vector2(i * size, 5 * size)
		)

	# LEFT
	for i in range(4, 0, -1):
		cell_positions.append(
			start + Vector2(0, i * size)
		)


	# Spawn
	for i in range(cell_positions.size()):

		var data = board_layout[i]

		if data == null:
			push_error(
				"board_layout[" + str(i) + "] is NULL"
			)
			continue

		print(
			"Spawn: ",
			i,
			" -> ",
			data.cell_name
		)

		var scene = get_scene_by_type(
			data.cell_type
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

	center_board()


# =========================
# Layout
# =========================

func create_board_layout():

	board_layout.clear()

	board_layout = [

		create_go(0),

		create_red_property(1),
		create_red_property(2),

		create_chance(3),

		create_red_property(4),

		create_visit_jail(5),

		create_green_property(6),
		create_green_property(7),

		create_tax(8),

		create_green_property(9),

		create_parking(10),

		create_yellow_property(11),
		create_yellow_property(12),

		create_chest(13),

		create_yellow_property(14),

		create_go_to_jail(15),

		create_blue_property(16),
		create_blue_property(17),

		create_tax(18),

		create_blue_property(19)
	]


# =========================
# Scene Factory
# =========================

func get_scene_by_type(type):

	match type:

		CellType.Type.PROPERTY:
			return property_scene

		CellType.Type.TAX:
			return tax_scene

		CellType.Type.CHANCE:
			return chance_scene

		CellType.Type.CHEST:
			return chest_scene

		_:
			return special_scene


# =========================
# Property Factory
# =========================

func create_red_property(index):

	var data = PropertyData.new()

	data.cell_index = index
	data.cell_type = CellType.Type.PROPERTY
	data.cell_name = "Red " + str(index)

	data.color_name = "Red"
	data.color_code = Color.RED

	data.buy_price = 200
	data.build_cost = 100

	return data


func create_green_property(index):

	var data = PropertyData.new()

	data.cell_index = index
	data.cell_type = CellType.Type.PROPERTY
	data.cell_name = "Green " + str(index)

	data.color_name = "Green"
	data.color_code = Color.GREEN

	data.buy_price = 300
	data.build_cost = 150

	return data


func create_yellow_property(index):

	var data = PropertyData.new()

	data.cell_index = index
	data.cell_type = CellType.Type.PROPERTY
	data.cell_name = "Yellow " + str(index)

	data.color_name = "Yellow"
	data.color_code = Color.YELLOW

	data.buy_price = 400
	data.build_cost = 200

	return data


func create_blue_property(index):

	var data = PropertyData.new()

	data.cell_index = index
	data.cell_type = CellType.Type.PROPERTY
	data.cell_name = "Blue " + str(index)

	data.color_name = "Blue"
	data.color_code = Color.BLUE

	data.buy_price = 500
	data.build_cost = 250

	return data


# =========================
# Other Cells
# =========================

func create_tax(index):

	var data = TaxData.new()

	data.cell_index = index
	data.cell_type = CellType.Type.TAX
	data.cell_name = "Tax"

	data.tax_amount = 200

	return data


func create_chance(index):

	var data = ChanceData.new()

	data.cell_index = index
	data.cell_type = CellType.Type.CHANCE
	data.cell_name = "Chance"

	data.cards = [
		"Nhận 200",
		"Mất 100",
		"Đi tù"
	]

	return data


func create_chest(index):

	var data = ChestData.new()

	data.cell_index = index
	data.cell_type = CellType.Type.CHEST
	data.cell_name = "Chest"

	data.cards = [
		"Nhận 300",
		"Mất 150",
		"Tiến tới GO"
	]

	return data


func create_go(index):

	var data = SpecialData.new()

	data.cell_index = index
	data.cell_type = CellType.Type.GO
	data.cell_name = "GO"

	return data


func create_visit_jail(index):

	var data = SpecialData.new()

	data.cell_index = index
	data.cell_type = CellType.Type.VISIT_JAIL
	data.cell_name = "Visit Jail"

	return data


func create_parking(index):

	var data = SpecialData.new()

	data.cell_index = index
	data.cell_type = CellType.Type.PARKING
	data.cell_name = "Parking"

	return data


func create_go_to_jail(index):

	var data = SpecialData.new()

	data.cell_index = index
	data.cell_type = CellType.Type.GO_TO_JAIL
	data.cell_name = "Go To Jail"

	return data


# =========================
# Helpers
# =========================

func center_board():

	if cell_positions.is_empty():
		return

	var board_size = Vector2(
		cell_positions.max().x + size,
		cell_positions.max().y + size
	)

	var viewport_size = get_viewport_rect().size

	position = (
		viewport_size - board_size
	) / 2.0


func clear_board():

	var cells_node = $Cells

	for c in cells_node.get_children():
		c.queue_free()

	cells.clear()
	cell_positions.clear()


func _process(_delta):

	if Engine.is_editor_hint() \
	and auto_center_in_editor:

		center_board()


func get_cell_position(index: int) -> Vector2:

	if cell_positions.is_empty():
		return Vector2.ZERO

	return cell_positions[
		index % cell_positions.size()
	] + Vector2(
		size / 2.0,
		size / 2.0
	)


func get_cell(index: int) -> Cell:

	if index >= 0 and index < cells.size():
		return cells[index]

	return null


func remove_player_token(player: Player):

	if player.token \
	and is_instance_valid(player.token):

		player.token.queue_free()


func reset_board():

	for cell in cells:

		if cell is PropertyCell:

			cell.property_owner = null
			cell.is_mortgaged = false
