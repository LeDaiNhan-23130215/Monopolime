extends Node2D
class_name PlayerToken

var player_id: int

func move_to(pos: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "position", pos, 0.3)
