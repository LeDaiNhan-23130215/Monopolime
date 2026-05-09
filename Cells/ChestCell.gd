extends Cell
class_name ChestCell


func on_land(player: Player):

	var card = data.cards.pick_random()

	print(
		player.name,
		" bốc Chest: ",
		card
	)
