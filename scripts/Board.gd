@tool
extends Node2D
class_name Board

var cell_positions: Array[Vector2] = []
var cells = []

@export var cell_scene: PackedScene
@export var auto_center_in_editor := true
@export var size := 58

var cell_w := 176.0
var cell_step_y := 112.0
var cell_h := 210.0

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
	for i in range(40):
		cell_positions.append(_calc_pos(i))


func _calc_pos(i: int) -> Vector2:
	if i == 0: return Vector2(0, 0)
	elif i > 0 and i < 10: return Vector2(cell_h + (i-1)*cell_w, 0)
	elif i == 10: return Vector2(cell_h + 9*cell_w, 0)
	elif i > 10 and i < 20: return Vector2(cell_h + 9*cell_w, cell_h + (i-11)*cell_step_y)
	elif i == 20: return Vector2(cell_h + 9*cell_w, cell_h + 9*cell_step_y)
	elif i > 20 and i < 30: return Vector2(cell_h + (29-i)*cell_w, cell_h + 9*cell_step_y)
	elif i == 30: return Vector2(0, cell_h + 9*cell_step_y)
	elif i > 30 and i < 40: return Vector2(0, cell_h + (39-i)*cell_step_y)
	return Vector2.ZERO


func _get_cell_size(i: int) -> Vector2:
	if i % 10 == 0: return Vector2(cell_h, cell_h)
	if i > 0 and i < 10: return Vector2(cell_w, cell_h)
	if i > 10 and i < 20: return Vector2(cell_h, cell_step_y)
	if i > 20 and i < 30: return Vector2(cell_w, cell_h)
	if i > 30 and i < 40: return Vector2(cell_h, cell_step_y)
	return Vector2(cell_h, cell_h)


func _get_cell_side(i: int) -> String:
	if i % 10 == 0: return "corner"
	if i > 0 and i < 10: return "top"
	if i > 10 and i < 20: return "right"
	if i > 20 and i < 30: return "bottom"
	if i > 30 and i < 40: return "left"
	return "corner"


func _spawn_cells(cells_node: Node):
	var configs = BoardData.get_cell_configs()

	for i in range(40):
		var cell = cell_scene.instantiate()
		cell.position = cell_positions[i]
		
		# Set physical properties
		cell.set("cell_rect_size", _get_cell_size(i))
		cell.set("cell_side", _get_cell_side(i))
		
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
		var c_size = _get_cell_size(i)
		var side = _get_cell_side(i)

		# Name label
		var name_label = Label.new()
		name_label.text = cell.cell_name
		name_label.add_theme_font_size_override("font_size", 21)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_color_override("font_color", _font_color_for_cell(cell))
		name_label.add_theme_color_override("font_outline_color", Color("#FFFDF4"))
		name_label.add_theme_constant_override("outline_size", 5)
		
		# Price label
		var price_label = null
		if cell.price > 0:
			price_label = Label.new()
			price_label.text = "$" + str(cell.price)
			price_label.add_theme_font_size_override("font_size", 18)
			price_label.add_theme_color_override("font_color", Color("#005E22"))
			price_label.add_theme_color_override("font_outline_color", Color("#FFFDF4"))
			price_label.add_theme_constant_override("outline_size", 4)
			price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		# Positioning logic based on side
		match side:
			"top":
				name_label.position = cell_positions[i] + Vector2(2, 5)
				name_label.size = Vector2(c_size.x - 4, 74)
				name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
				if price_label:
					price_label.position = cell_positions[i] + Vector2(2, c_size.y - 34)
					price_label.size = Vector2(c_size.x - 4, 25)
			"bottom":
				name_label.position = cell_positions[i] + Vector2(2, c_size.y - 92)
				name_label.size = Vector2(c_size.x - 4, 66)
				name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
				if price_label:
					price_label.position = cell_positions[i] + Vector2(2, c_size.y - 26)
					price_label.size = Vector2(c_size.x - 4, 25)
			"left":
				name_label.position = cell_positions[i] + Vector2(5, 5)
				name_label.size = Vector2(82, c_size.y - 10)
				if price_label:
					price_label.position = cell_positions[i] + Vector2(c_size.x - 45, 5)
					price_label.size = Vector2(40, c_size.y - 10)
			"right":
				name_label.position = cell_positions[i] + Vector2(c_size.x - 87, 5)
				name_label.size = Vector2(82, c_size.y - 10)
				if price_label:
					price_label.position = cell_positions[i] + Vector2(25, 5)
					price_label.size = Vector2(40, c_size.y - 10)
			"corner":
				name_label.position = cell_positions[i] + Vector2(10, 8)
				name_label.size = Vector2(c_size.x - 20, 72)

		labels_node.add_child(name_label)
		if price_label:
			labels_node.add_child(price_label)


func _font_color_for_cell(cell: Cell) -> Color:
	match cell.cell_type:
		"go":
			return Color("#1B5E20") # Dark green
		"chance":
			return Color("#E65100") # Dark orange
		"community":
			return Color("#0D47A1") # Dark blue
		"tax":
			return Color("#B71C1C") # Dark red
		"jail":
			return Color("#3E2723") # Dark brown
		"go_to_jail":
			return Color("#B71C1C") # Dark red
		"parking":
			return Color("#1B5E20")
		"railroad":
			return Color("#212121") # Dark gray
		"utility":
			return Color("#424242")
		"teleport":
			return Color("#311B92") # Deep purple
	return Color("#212121") # Dark gray default


func _create_center_decoration():
	if has_node("CenterDeco"):
		$CenterDeco.queue_free()
		await get_tree().process_frame

	var center_node = Node2D.new()
	center_node.name = "CenterDeco"
	center_node.z_index = 1
	add_child(center_node)

	var center_x = cell_h
	var center_y = cell_h
	var center_w = 9 * cell_w
	var center_h_inner = 9 * cell_step_y

	var bg := TextureRect.new()
	bg.position = Vector2(center_x, center_y)
	bg.size = Vector2(center_w, center_h_inner)
	
	var tex = load("res://resources/center_bg.png")
	if tex:
		bg.texture = tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		var grad := Gradient.new()
		grad.add_point(0.0, Color("#3FA9F5"))
		grad.add_point(1.0, Color("#0D47A1"))
		var grad_tex := GradientTexture2D.new()
		grad_tex.gradient = grad
		grad_tex.fill_to = Vector2(0, 1)
		grad_tex.width = int(center_w)
		grad_tex.height = int(center_h_inner)
		bg.texture = grad_tex
		
	center_node.add_child(bg)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0)
	panel_style.border_color = Color("#28A8FF")
	panel_style.set_border_width_all(3)

	var panel = Panel.new()
	panel.position = Vector2(center_x, center_y)
	panel.size = Vector2(center_w, center_h_inner)
	panel.add_theme_stylebox_override("panel", panel_style)
	center_node.add_child(panel)


func center_board():
	if cell_positions.is_empty():
		return

	var board_size_vec = Vector2(
		2 * cell_h + 9 * cell_w,
		2 * cell_h + 9 * cell_step_y
	)
	var viewport_size = get_viewport_rect().size
	
	# Calculate UI scale based on 1280x720 design size used by ResponsiveCanvas
	var ui_scale = min(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	
	# Safe area margins mirror the HUD columns while giving the board more room.
	var top_margin = 88 * ui_scale
	var bottom_margin = 72 * ui_scale
	var left_margin = 156 * ui_scale
	var right_margin = 190 * ui_scale
	
	var safe_w = viewport_size.x - left_margin - right_margin
	var safe_h = viewport_size.y - top_margin - bottom_margin
	
	# Scale board to fit the safe area tightly without going under the HUD.
	var scale_x = safe_w / board_size_vec.x
	var scale_y = safe_h / board_size_vec.y
	var board_scale = min(scale_x, scale_y) * 1.0
	
	scale = Vector2(board_scale, board_scale)
	
	# Center the scaled board within the safe area
	var scaled_board_size = board_size_vec * board_scale
	var safe_center_x = left_margin + safe_w / 2.0
	var safe_center_y = top_margin + safe_h / 2.0
	
	position = Vector2(
		safe_center_x - scaled_board_size.x / 2.0,
		safe_center_y - scaled_board_size.y / 2.0
	)


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
	var safe_i = cell_index % cell_positions.size()
	return cell_positions[safe_i] + _get_cell_size(safe_i) / 2.0


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
