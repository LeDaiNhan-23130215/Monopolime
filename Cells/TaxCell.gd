extends Cell
class_name TaxCell


func on_land(player):

	player.deduct_money(data.tax_amount)

	print(
		player.name,
		" đóng thuế ",
		data.tax_amount
	)
