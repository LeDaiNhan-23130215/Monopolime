extends Node2D
class_name PlayerToken

var player_id: int

@onready var token_sprite = $TokenSprite


var token_texture = [
	preload("res://resources/PlayerToken/PlayerToken_Dog.png"),
	preload("res://resources/PlayerToken/PlayerToken_Hat.png"),
	preload("res://resources/PlayerToken/PlayerToken_Car.png"),
	preload("res://resources/PlayerToken/PlayerToken_Something.png")
]

func move_to(pos: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "position", pos, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
func get_random_token_texture():
	var tex = token_texture[randi_range(0, token_texture.size() - 1)]
	token_sprite.texture = tex
