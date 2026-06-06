extends Cell
class_name TaxCell


func on_land(player):

	player.deduct_money(data.tax_amount)

	# Hiệu ứng số tiền bay lên trên quân cờ (âm = trừ tiền, hiện màu đỏ)
	if player.token and player.token.has_method("show_floating_money"):
		player.token.show_floating_money(-data.tax_amount)

	print(
		player.name,
		" đóng thuế ",
		data.tax_amount
	)


func _draw():

	# Vẽ nền + tên ô như Cell gốc
	draw_rect(Rect2(0, 0, 100, 100), CoTyPhuPalette.CREAM, true)
	draw_rect(Rect2(0, 0, 100, 100), CoTyPhuPalette.DEEP_BLUE, false, 2.0)

	# Thanh tiêu đề màu đỏ cho ô thuế
	draw_rect(Rect2(0, 0, 100, 18), CoTyPhuPalette.RED)
	draw_rect(Rect2(0, 0, 100, 18), CoTyPhuPalette.RED.darkened(0.25), false, 1.0)

	if data == null:
		return

	# Tên ô (Việt hóa: "Thuế")
	draw_string(
		ThemeDB.fallback_font,
		Vector2(8, 40),
		CoTyPhuPalette.display_name(data.cell_name),
		HORIZONTAL_ALIGNMENT_LEFT,
		84, 14,
		CoTyPhuPalette.TEXT_DARK
	)

	# Số tiền thuế phải trả
	var amount := 0
	if data is TaxData:
		amount = data.tax_amount
	draw_string(
		ThemeDB.fallback_font,
		Vector2(8, 72),
		"-$" + str(amount),
		HORIZONTAL_ALIGNMENT_LEFT,
		84, 20,
		Color("#CC0000")
	)
