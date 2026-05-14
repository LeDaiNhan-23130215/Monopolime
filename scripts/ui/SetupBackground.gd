extends Control
class_name SetupBackground

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")

func _ready() -> void:
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("#004CA8"), true)
	for i in range(18):
		var t := float(i) / 18.0
		draw_rect(Rect2(0, h * t, w, h / 18.0 + 1.0), Color("#003B8F").lerp(Color("#0878D8"), 1.0 - t), true)
	for i in range(9):
		var x := 80.0 + i * 190.0
		var y := 88.0 + sin(i * 1.7) * 18.0
		_draw_cloud(Vector2(x, y), 0.65 + (i % 3) * 0.12)
	for i in range(14):
		var x := 40.0 + i * 120.0
		var height := 90.0 + (i % 5) * 22.0
		var rect := Rect2(x, h - 180.0 - height, 74.0, height)
		draw_rect(rect, Color(0.0, 0.12, 0.36, 0.35), true)
		for y in range(3):
			draw_rect(Rect2(rect.position + Vector2(14, 18 + y * 26), Vector2(10, 10)), Color(1, 1, 1, 0.16), true)
			draw_rect(Rect2(rect.position + Vector2(42, 18 + y * 26), Vector2(10, 10)), Color(1, 1, 1, 0.12), true)
	for i in range(26):
		var p := Vector2(fmod(i * 137.0, w), 80.0 + fmod(i * 71.0, h - 180.0))
		draw_circle(p, 2.0 + (i % 3), Color(1, 1, 1, 0.18))

func _draw_cloud(pos: Vector2, s: float) -> void:
	var c := Color(1, 1, 1, 0.16)
	draw_circle(pos, 24 * s, c)
	draw_circle(pos + Vector2(28, -8) * s, 34 * s, c)
	draw_circle(pos + Vector2(64, 0) * s, 24 * s, c)
	draw_rect(Rect2(pos + Vector2(-4, 0) * s, Vector2(76, 22) * s), c, true)
