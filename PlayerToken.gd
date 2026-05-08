extends Node2D
class_name PlayerToken

var player_id: int

@onready var token_sprite = $TokenSprite

func _ready():
	token_sprite.centered = true
	token_sprite.scale = Vector2(0.458, 0.458)
	
func move_to(target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.2)
	await tween.finished
	
func get_random_token_texture():
	var tex = TokenManage.get_random_texture()
	token_sprite.texture = tex
	
	center_sprite()

func center_sprite():
	if token_sprite.texture == null:
		return
	
	var size = token_sprite.texture.get_size() * token_sprite.scale
