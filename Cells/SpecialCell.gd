extends Cell
class_name SpecialCell


func setup(data: Dictionary):
	super.setup(data)
	if cell_type == "property":
		cell_type = "parking"
