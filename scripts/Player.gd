extends Resource
class_name Player

var player_id: int
var name: String

var state: PlayerState
var properties: Array = []
var special_card: Array = []

var token: PlayerToken

func _init(id := 0, player_name := "Player"):
	player_id = id
	name = player_name
	state = PlayerState.new()
	
func add_property(property):
	properties.append(property)

func add_special_card(special_card):
	special_card.append(special_card)

func get_random_token():
	token.token_texture = token.get_random_token_texture()
