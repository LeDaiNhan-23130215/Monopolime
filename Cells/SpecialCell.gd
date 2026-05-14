extends Cell
class_name SpecialCell


func on_land(player):

	match data.cell_type:

		CellType.Type.GO:
			print(player.name, " đứng ở GO")

		CellType.Type.VISIT_JAIL:
			print(player.name, " đang thăm tù")

		CellType.Type.PARKING:
			print(player.name, " vào bãi xe")

		CellType.Type.GO_TO_JAIL:
			print(player.name, " bị đưa vào tù")
