extends Cell
class_name PropertyCell

var property_owner: Player = null
var is_mortgaged: bool = false


func on_land(player: Player):

	if property_owner == null:
		print("Có thể mua ", data.cell_name)

	elif property_owner != player:
		print("Trả tiền thuê")
