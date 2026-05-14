extends Control
class_name GameOverDecorations

# Decorative drawing for the GameOverScreen.
# kind:
#   "ribbon_left", "ribbon_right" - swallow-tail banner ribbons
#   "crown" - king crown drawn on top of the banner

@export var kind := "crown"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	match kind:
		"ribbon_left":
			_draw_ribbon_left()
		"ribbon_right":
			_draw_ribbon_right()
		"crown":
			_draw_crown()

func _draw_ribbon_left() -> void:
	var pts := PackedVector2Array([
		Vector2(60, 0),
		Vector2(60, 60),
		Vector2(0, 30),
	])
	draw_colored_polygon(pts, Color("8E0D0E"))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color("F4A000"), 3)

func _draw_ribbon_right() -> void:
	var pts := PackedVector2Array([
		Vector2(0, 0),
		Vector2(0, 60),
		Vector2(60, 30),
	])
	draw_colored_polygon(pts, Color("8E0D0E"))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color("F4A000"), 3)

func _draw_crown() -> void:
	var c := Color("FFCA28")
	var dark := Color("B07000")
	var pts := PackedVector2Array([
		Vector2(6, 44),
		Vector2(74, 44),
		Vector2(70, 8),
		Vector2(54, 22),
		Vector2(40, 4),
		Vector2(26, 22),
		Vector2(10, 8),
	])
	draw_colored_polygon(pts, c)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4], pts[5], pts[6], pts[0]]), dark, 2)
	# Gem dots
	draw_circle(Vector2(40, 32), 4, Color("E94C3D"))
	draw_circle(Vector2(20, 36), 3, Color("168BE3"))
	draw_circle(Vector2(60, 36), 3, Color("168BE3"))
