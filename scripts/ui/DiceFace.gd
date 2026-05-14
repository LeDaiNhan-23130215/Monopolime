extends PanelContainer

var value: int = 1

func _ready():
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(68, 68)

func set_value(v: int) -> void:
	value = clampi(v, 1, 6)
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var center = Vector2(w / 2, h / 2)
	var offset = 16 # Distance from center for corner pips
	var pip_radius = 5.5
	var color = Color.BLACK
	
	if value in [1, 3, 5]:
		draw_circle(center, pip_radius, color)
		
	if value in [2, 3, 4, 5, 6]:
		draw_circle(center + Vector2(-offset, -offset), pip_radius, color) # Top-left
		draw_circle(center + Vector2(offset, offset), pip_radius, color) # Bottom-right
		
	if value in [4, 5, 6]:
		draw_circle(center + Vector2(offset, -offset), pip_radius, color) # Top-right
		draw_circle(center + Vector2(-offset, offset), pip_radius, color) # Bottom-left
		
	if value == 6:
		draw_circle(center + Vector2(-offset, 0), pip_radius, color) # Middle-left
		draw_circle(center + Vector2(offset, 0), pip_radius, color) # Middle-right
