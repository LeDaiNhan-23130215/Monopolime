extends Node

class_name Dice

func roll():
	var d1 = (randi() % 6) + 1
	var d2 = (randi() % 6) + 1
	
	return DiceResult.new(d1, d2)
