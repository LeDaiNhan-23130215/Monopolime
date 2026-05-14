extends Node2D
class_name PlayerToken

const TOKEN_SCALE := Vector2(0.68, 0.68)

var player_id: int

@onready var token_sprite = $TokenSprite

func _ready():
	token_sprite.centered = true
	token_sprite.scale = TOKEN_SCALE
	
func move_to(target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.2)
	await tween.finished
	
func get_random_token_texture():
	var token_manager = get_node_or_null("/root/TokenManage")
	if token_manager == null:
		return
	var tex = token_manager.get_random_texture()
	token_sprite.texture = tex
	
	center_sprite()

func center_sprite():
	if token_sprite.texture == null:
		return
	
	var size = token_sprite.texture.get_size() * token_sprite.scale
