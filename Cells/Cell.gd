extends Node2D
class_name Cell

const CoTyPhuPalette = preload("res://scripts/ui_theme/CoTyPhuPalette.gd")

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

	# Nền ô kiểu "thẻ" Cờ Tỷ Phú: nền kem + viền xanh đậm bo nhẹ
	draw_rect(Rect2(0, 0, 100, 100), CoTyPhuPalette.CREAM, true)
	draw_rect(Rect2(0, 0, 100, 100), CoTyPhuPalette.DEEP_BLUE, false, 2.0)

	# Nếu có data thì vẽ tên ô (đã Việt hóa ở tầng hiển thị) — tự xuống dòng, có padding
	if data != null:
		var disp := CoTyPhuPalette.display_name(data.cell_name)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(8, 24),
			disp,
			HORIZONTAL_ALIGNMENT_LEFT,
			84,
			13,
			CoTyPhuPalette.TEXT_DARK
		)


func on_land(_player):
	pass
