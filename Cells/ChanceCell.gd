extends Cell
class_name ChanceCell


func on_land(player):

	var card = data.cards.pick_random()

	print("Bốc thẻ: ", card)
