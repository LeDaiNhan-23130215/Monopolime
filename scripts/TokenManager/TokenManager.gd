extends RefCounted
class_name TokenManager

static var textures = [
	preload("res://resources/PlayerToken/PlayerToken_Dog.png"),
	preload("res://resources/PlayerToken/PlayerToken_Hat.png"),
	preload("res://resources/PlayerToken/PlayerToken_Car.png"),
	preload("res://resources/PlayerToken/PlayerToken_Something.png")
]

static func get_random_texture():
	if textures.is_empty():
		return null

	return textures.pop_at(randi_range(0, textures.size() - 1))
