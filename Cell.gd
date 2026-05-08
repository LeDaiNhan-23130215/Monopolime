extends Node2D
class_name Cell

var index: int

func _ready():
	z_index = 0
	queue_redraw()
