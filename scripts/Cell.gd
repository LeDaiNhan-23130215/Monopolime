extends Node2D
class_name Cella

@export var index: int

func highlight():
	modulate = Color.YELLOW

func reset():
	modulate = Color.WHITE
