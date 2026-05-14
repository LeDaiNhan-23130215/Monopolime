extends Control
class_name IllustratedIcon

@export var icon_type := "dice"
@export var accent := Color("#48B82E")
@export var label_text := ""

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(96, 96)
	queue_redraw()

func configure(kind: String, color: Color, caption := "") -> void:
	icon_type = kind
	accent = color
	label_text = caption
	queue_redraw()

func _draw() -> void:
	var base_size := Vector2(96, 96)
	var scale_factor := size / base_size
	draw_set_transform(Vector2.ZERO, 0.0, scale_factor)
	var rect := Rect2(Vector2.ZERO, base_size)
	var center := rect.size * 0.5
	match icon_type:
		"dice":
			_draw_dice(center)
		"money":
			_draw_money(center)
		"home":
			_draw_home(center)
		"gift":
			_draw_gift(center)
		"trophy":
			_draw_trophy(center)
		"city":
			_draw_city(center)
		"token":
			_draw_token(center)
		"pagoda":
			_draw_pagoda(center)
		"palm":
			_draw_palm(center)
		"bridge":
			_draw_bridge(center)
		"jail":
			_draw_jail(center)
		"hourglass":
			_draw_hourglass(center)
		_:
			_draw_home(center)
	if label_text != "":
		draw_string(ThemeDB.fallback_font, Vector2(4, size.y - 6), label_text, HORIZONTAL_ALIGNMENT_CENTER, size.x - 8, 15, Color.WHITE)

func _draw_dice(center: Vector2) -> void:
	var shadow := Rect2(center - Vector2(32, 28) + Vector2(4, 5), Vector2(58, 58))
	draw_rect(shadow, Color(0, 0, 0, 0.22), true)
	var box := Rect2(center - Vector2(34, 32), Vector2(58, 58))
	draw_rect(box, Color.WHITE, true)
	draw_rect(box, Color("#D8D8D8"), false, 3)
	for p in [Vector2(-16, -14), Vector2(0, 0), Vector2(16, 14), Vector2(16, -14)]:
		draw_circle(center + p, 5, Color("#171717"))

func _draw_money(center: Vector2) -> void:
	for i in range(3):
		var r := Rect2(center - Vector2(34, 20) + Vector2(i * 7, -i * 4), Vector2(68, 38))
		draw_rect(r, Color("#79D85E"), true)
		draw_rect(r, Color("#1E8C30"), false, 3)
	draw_circle(center + Vector2(8, -4), 11, Color("#E9F7A8"))
	draw_string(ThemeDB.fallback_font, center + Vector2(0, 8), "$", HORIZONTAL_ALIGNMENT_CENTER, 20, 24, Color("#1A6F28"))

func _draw_home(center: Vector2) -> void:
	var roof := PackedVector2Array([center + Vector2(-34, -6), center + Vector2(0, -36), center + Vector2(34, -6)])
	draw_colored_polygon(roof, accent)
	draw_polyline(roof, Color("#215C18"), 4)
	var body := Rect2(center + Vector2(-25, -6), Vector2(50, 42))
	draw_rect(body, accent.lightened(0.15), true)
	draw_rect(body, Color("#215C18"), false, 3)
	draw_rect(Rect2(center + Vector2(-7, 10), Vector2(14, 26)), Color("#7E4A21"), true)

func _draw_gift(center: Vector2) -> void:
	var box := Rect2(center - Vector2(34, 12), Vector2(68, 45))
	draw_rect(box, Color("#168BE3"), true)
	draw_rect(box, Color("#064A91"), false, 3)
	draw_rect(Rect2(center - Vector2(6, 12), Vector2(12, 45)), Color("#FFC832"), true)
	draw_rect(Rect2(center - Vector2(34, -2), Vector2(68, 12)), Color("#FFC832"), true)
	draw_arc(center + Vector2(-12, -20), 14, 0.0, TAU, 24, Color("#FFC832"), 5)
	draw_arc(center + Vector2(12, -20), 14, 0.0, TAU, 24, Color("#FFC832"), 5)

func _draw_trophy(center: Vector2) -> void:
	draw_rect(Rect2(center + Vector2(-10, 18), Vector2(20, 18)), Color("#C77A00"), true)
	draw_rect(Rect2(center + Vector2(-28, 34), Vector2(56, 9)), Color("#0C64B5"), true)
	draw_circle(center + Vector2(0, -8), 30, Color("#FFC832"))
	draw_circle(center + Vector2(0, -8), 20, Color("#FFD95A"))
	draw_arc(center + Vector2(-30, -10), 20, -1.6, 1.2, 20, Color("#FFC832"), 7)
	draw_arc(center + Vector2(30, -10), 20, 1.9, 4.8, 20, Color("#FFC832"), 7)
	draw_string(ThemeDB.fallback_font, center + Vector2(-8, 2), "★", HORIZONTAL_ALIGNMENT_CENTER, 18, 18, Color("#A56700"))

func _draw_city(center: Vector2) -> void:
	var colors := [Color("#F6A623"), Color("#39B54A"), Color("#168BE3")]
	for i in range(3):
		var h := 42 + i * 9
		var r := Rect2(center + Vector2(-36 + i * 28, 28 - h), Vector2(24, h))
		draw_rect(r, colors[i], true)
		draw_rect(r, Color("#06336F"), false, 2)
		for y in range(3):
			draw_rect(Rect2(r.position + Vector2(6, 8 + y * 12), Vector2(5, 5)), Color("#FFF1D4"), true)
	draw_circle(center + Vector2(18, 18), 17, Color.WHITE)
	draw_string(ThemeDB.fallback_font, center + Vector2(9, 26), "⚂", HORIZONTAL_ALIGNMENT_CENTER, 22, 24, Color("#171717"))

func _draw_token(center: Vector2) -> void:
	draw_circle(center + Vector2(0, -20), 18, accent.lightened(0.2))
	draw_circle(center + Vector2(0, 18), 24, accent)
	draw_rect(Rect2(center + Vector2(-26, 34), Vector2(52, 11)), accent.darkened(0.25), true)
	draw_arc(center + Vector2(-8, -28), 12, 3.6, 5.9, 12, Color.WHITE, 4)

func _draw_pagoda(center: Vector2) -> void:
	# Base
	draw_rect(Rect2(center.x - 26, center.y + 20, 52, 14), Color("#8A2B1D"), true)
	draw_rect(Rect2(center.x - 26, center.y + 20, 52, 14), Color("#4A1005"), false, 2)
	
	# 3 Tiers
	for i in range(3):
		var y := center.y + 20 - i * 20
		var w := 40 - i * 8
		draw_rect(Rect2(center.x - w/2.0, y - 14, w, 14), Color("#E94C3D"), true)
		draw_rect(Rect2(center.x - w/2.0, y - 14, w, 14), Color("#7B1912"), false, 2)
		
		# Roof
		var rw := w + 16
		var roof := PackedVector2Array([
			Vector2(center.x - rw/2.0, y - 14),
			Vector2(center.x, y - 28),
			Vector2(center.x + rw/2.0, y - 14)
		])
		draw_colored_polygon(roof, Color("#FFC832"))
		draw_polyline(roof + PackedVector2Array([roof[0]]), Color("#B37A00"), 2)

func _draw_palm(center: Vector2) -> void:
	# Water
	draw_circle(center + Vector2(0, 32), 26, Color("#3FA9F5"))
	
	# Sand island
	draw_circle(center + Vector2(0, 24), 22, Color("#F7C353"))
	
	# Trunk
	draw_line(center + Vector2(-2, 28), center + Vector2(4, -10), Color("#8B5A2B"), 12)
	draw_line(center + Vector2(0, 28), center + Vector2(5, -10), Color("#6B3E11"), 4)
	
	# Leaves
	for angle in [-2.6, -2.1, -1.4, -0.7, -0.2]:
		var end := center + Vector2(cos(angle), sin(angle)) * 36 + Vector2(4, -14)
		draw_line(center + Vector2(4, -14), end, Color("#39B54A"), 12)
		draw_circle(end, 6, Color("#39B54A"))
	draw_circle(center + Vector2(4, -14), 12, Color("#39B54A"))
	
	# Coconuts
	draw_circle(center + Vector2(-2, -6), 7, Color("#D4A017"))
	draw_circle(center + Vector2(8, -4), 7, Color("#D4A017"))
	draw_circle(center + Vector2(3, 0), 7, Color("#B8860B"))

func _draw_bridge(center: Vector2) -> void:
	# Water
	draw_rect(Rect2(center - Vector2(44, -16), Vector2(88, 16)), Color("#3FA9F5"), true)
	
	# Bridge deck
	draw_rect(Rect2(center - Vector2(46, -4), Vector2(92, 10)), Color("#F6A623"), true)
	draw_rect(Rect2(center - Vector2(46, -4), Vector2(92, 10)), Color("#B87000"), false, 2)
	
	# Arches / Cables
	draw_arc(center + Vector2(0, 4), 38, PI, TAU, 32, Color("#FFC832"), 6)
	
	# Pillars
	draw_rect(Rect2(center + Vector2(-30, -28), Vector2(10, 52)), Color("#E94C3D"), true)
	draw_rect(Rect2(center + Vector2(20, -28), Vector2(10, 52)), Color("#E94C3D"), true)
	draw_rect(Rect2(center + Vector2(-30, -28), Vector2(10, 52)), Color("#7B1912"), false, 2)
	draw_rect(Rect2(center + Vector2(20, -28), Vector2(10, 52)), Color("#7B1912"), false, 2)

func _draw_jail(center: Vector2) -> void:
	draw_rect(Rect2(center - Vector2(32, 32), Vector2(64, 64)), Color("#E94C3D"), true)
	draw_rect(Rect2(center - Vector2(32, 32), Vector2(64, 64)), Color("#7B1912"), false, 4)
	for x in [-18, 0, 18]:
		draw_line(center + Vector2(x, -26), center + Vector2(x, 26), Color("#252525"), 6)

func _draw_hourglass(center: Vector2) -> void:
	var top := PackedVector2Array([
		center + Vector2(-28, -36),
		center + Vector2(28, -36),
		center + Vector2(8, -4),
		center + Vector2(-8, -4),
	])
	var bottom := PackedVector2Array([
		center + Vector2(-8, 4),
		center + Vector2(8, 4),
		center + Vector2(28, 36),
		center + Vector2(-28, 36),
	])
	draw_colored_polygon(top, Color("#FFF1D2"))
	draw_colored_polygon(bottom, Color("#FFF1D2"))
	draw_polyline(top + PackedVector2Array([top[0]]), Color("#8B4E12"), 4)
	draw_polyline(bottom + PackedVector2Array([bottom[0]]), Color("#8B4E12"), 4)
	draw_line(center + Vector2(-34, -40), center + Vector2(34, -40), Color("#F4A000"), 7)
	draw_line(center + Vector2(-34, 40), center + Vector2(34, 40), Color("#F4A000"), 7)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-15, -24),
		center + Vector2(15, -24),
		center + Vector2(4, -6),
		center + Vector2(-4, -6),
	]), Color("#FFC533"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-4, 10),
		center + Vector2(4, 10),
		center + Vector2(17, 28),
		center + Vector2(-17, 28),
	]), Color("#FFC533"))

