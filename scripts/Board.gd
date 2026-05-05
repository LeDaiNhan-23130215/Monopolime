extends Node2D
class_name Board

@export var cell_positions: Array[Vector2] = []
@export var cell_scene: PackedScene

var cells = []
func get_cell_position(index: int) -> Vector2:
	return cell_positions[index % cell_positions.size()]
	
func _ready():
	for i in range(cell_positions.size()):
		var cell = cell_scene.instantiate()
		cell.position = cell_positions[i]
		cell.index = i
		
		add_child(cell)
		cells.append(cell)
