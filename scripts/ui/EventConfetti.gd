extends Control
class_name EventConfetti

# Decorative confetti & balloons backdrop drawn around event icons.
# Pre-randomized so the layout remains stable per popup open.

@export var show_balloons := true
@export var confetti_count := 34

var _confetti: Array = []
var _balloons: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_generate()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_generate()
		queue_redraw()

func _generate() -> void:
	_confetti.clear()
	_balloons.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var palette := [
		Color("E94C3D"), Color("3CBF3C"), Color("0878D8"),
		Color("FFC832"), Color("F08020"), Color("8E4FD6"),
		Color("57C6FF"), Color("FF8FB3"),
	]
	for i in range(confetti_count):
		var x := rng.randf()
		var y := rng.randf()
		var col_idx := rng.randi_range(0, palette.size() - 1)
		var rot := rng.randf_range(0.0, TAU)
		var w := rng.randf_range(6.0, 11.0)
		var h := rng.randf_range(2.5, 4.5)
		_confetti.append({"pos": Vector2(x, y), "rot": rot, "w": w, "h": h, "color": palette[col_idx]})

	if show_balloons:
		# Balloons: positioned around the gift box
		var balloon_data := [
			{"pos": Vector2(0.18, 0.55), "color": Color("E94C3D")},
			{"pos": Vector2(0.27, 0.30), "color": Color("3CBF3C")},
			{"pos": Vector2(0.73, 0.30), "color": Color("0878D8")},
			{"pos": Vector2(0.82, 0.55), "color": Color("FFC832")},
		]
		for b in balloon_data:
			_balloons.append(b)

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	# Draw confetti rectangles
	for c in _confetti:
		var pos: Vector2 = c["pos"] * size
		var w: float = c["w"]
		var h: float = c["h"]
		var rot: float = c["rot"]
		var color: Color = c["color"]
		var corners := PackedVector2Array([
			Vector2(-w * 0.5, -h * 0.5),
			Vector2(w * 0.5, -h * 0.5),
			Vector2(w * 0.5, h * 0.5),
			Vector2(-w * 0.5, h * 0.5),
		])
		var rotated := PackedVector2Array()
		var cos_r := cos(rot)
		var sin_r := sin(rot)
		for v in corners:
			rotated.append(pos + Vector2(v.x * cos_r - v.y * sin_r, v.x * sin_r + v.y * cos_r))
		draw_colored_polygon(rotated, color)

	# Draw balloons
	for b in _balloons:
		var bp: Vector2 = b["pos"] * size
		var color: Color = b["color"]
		_draw_balloon(bp, color)

func _draw_balloon(pos: Vector2, color: Color) -> void:
	var radius := 13.0
	# Balloon body (slightly oval)
	draw_circle(pos, radius, color)
	# Highlight
	draw_circle(pos + Vector2(-4, -5), 3.5, color.lightened(0.45))
	# Tie (small triangle below balloon)
	var tie := PackedVector2Array([
		pos + Vector2(-3, radius - 1),
		pos + Vector2(3, radius - 1),
		pos + Vector2(0, radius + 4),
	])
	draw_colored_polygon(tie, color.darkened(0.2))
	# String
	var s_start := pos + Vector2(0, radius + 4)
	var s_end := s_start + Vector2(2, 18)
	var s_mid := s_start + Vector2(-2, 9)
	draw_polyline(PackedVector2Array([s_start, s_mid, s_end]), Color(0, 0, 0, 0.5), 1.2)
