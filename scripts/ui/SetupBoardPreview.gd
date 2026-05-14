extends Control
class_name SetupBoardPreview

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")

func _ready() -> void:
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var board := Rect2(Vector2(18, 18), size - Vector2(36, 36))
	var tile: float = min(board.size.x, board.size.y) / 11.0
	var origin := board.position + (board.size - Vector2(tile * 11.0, tile * 11.0)) * 0.5
	var board_rect := Rect2(origin, Vector2(tile * 11.0, tile * 11.0))
	draw_rect(board_rect, Color("#0A6BC4"), true)
	draw_rect(board_rect, Color("#57C6FF"), false, 5)
	var center := Rect2(origin + Vector2(tile, tile), Vector2(tile * 9.0, tile * 9.0))
	_draw_landscape(center)
	var positions := []
	for i in range(11):
		positions.append(origin + Vector2(i * tile, 0))
	for i in range(1, 10):
		positions.append(origin + Vector2(10 * tile, i * tile))
	for i in range(10, -1, -1):
		positions.append(origin + Vector2(i * tile, 10 * tile))
	for i in range(9, 0, -1):
		positions.append(origin + Vector2(0, i * tile))
	for i in range(positions.size()):
		var r := Rect2(positions[i], Vector2(tile, tile))
		var fill := Color("#FFF1D2")
		if i in [0, 10, 20, 30]:
			fill = Color("#FFE18B")
		elif i % 7 == 0:
			fill = Color("#DDF1FF")
		elif i % 5 == 0:
			fill = Color("#FFD4CF")
		draw_rect(r, fill, true)
		draw_rect(r, Color("#C9B37A"), false, 1)
		if i % 4 == 0:
			draw_rect(Rect2(r.position + Vector2(2, r.size.y - 8), Vector2(r.size.x - 4, 6)), _group_color(i), true)
		if i in [0, 10, 20, 30]:
			var text: String = ["Đi", "Tù", "★", "Quà"][int(i / 10)]
			draw_string(ThemeDB.fallback_font, r.position + Vector2(4, r.size.y * 0.62), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 8, 16, Color("#003B8F"))

func _draw_landscape(rect: Rect2) -> void:
	draw_rect(rect, Color("#74D6F3"), true)
	draw_circle(rect.position + Vector2(rect.size.x * 0.72, rect.size.y * 0.25), rect.size.x * 0.12, Color("#FFF4B8"))
	var river := PackedVector2Array([
		rect.position + Vector2(rect.size.x * 0.12, rect.size.y),
		rect.position + Vector2(rect.size.x * 0.43, rect.size.y * 0.54),
		rect.position + Vector2(rect.size.x * 0.58, rect.size.y),
	])
	draw_colored_polygon(river, Color("#168BE3"))
	for i in range(4):
		var x := rect.position.x + rect.size.x * (0.15 + i * 0.11)
		var h := rect.size.y * (0.25 + i * 0.06)
		draw_rect(Rect2(x, rect.end.y - h - 24, rect.size.x * 0.06, h), [Color("#F4A000"), Color("#3CBF3C"), Color("#0878D8"), Color("#E8483D")][i], true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.5), "CỜ\nTỶ PHÚ", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 42, Color("#FFC533"))

func _group_color(i: int) -> Color:
	var colors := [Color("#E8483D"), Color("#3CBF3C"), Color("#0878D8"), Color("#F6C234"), Color("#F4A000")]
	return colors[i % colors.size()]
