extends Node2D
class_name Cell

var index: int

func _draw():
	# Vẽ ô vuông
	draw_rect(Rect2(Vector2.ZERO, Vector2(50, 50)), Color(0, 1, 0), false, 2)


func _ready():
	queue_redraw()
