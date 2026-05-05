
class_name DiceResult

var dice1: int
var dice2: int
var is_double: bool

func _init(d1 := 1, d2 := 1) -> void:
	dice1 = d1
	dice2 = d2
	is_double = (d1 == d2)

func total() -> int:
	return dice1 + dice2
