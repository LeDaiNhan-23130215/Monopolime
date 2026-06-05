extends Node2D
class_name Cell

var index: int
var data: CellData


func setup(cell_data):

	data = cell_data
	index = data.cell_index

	queue_redraw()

	update_visual()


func update_visual():
	pass


func _draw():

	# Vẽ ô vuông 100x100
	draw_rect(
		Rect2(0, 0, 100, 100),
		Color.WHITE,
		false,
		2.0
	)

	# Nếu có data thì vẽ tên ô
	if data != null:

		draw_string(
			ThemeDB.fallback_font,
			Vector2(10, 55),
			data.cell_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			80,
			16
		)


func on_land(_player):
	pass
