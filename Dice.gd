extends Node

class_name Dice

func roll():
	var d1 = (randi() % 6) + 1
	var d2 = (randi() % 6) + 1
	
	return {
		"dice1": d1,
		"dice2": d2,
		"total" : d1 + d2,
		"is_double": d1 == d2
	}
