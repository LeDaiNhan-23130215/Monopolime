extends Node2D
class_name Cell

@export var index: int

func highlight():
	modulate = Color.YELLOW

func reset():
	modulate = Color.WHITE
