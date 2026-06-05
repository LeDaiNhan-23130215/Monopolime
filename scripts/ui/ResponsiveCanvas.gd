extends Control
class_name ResponsiveCanvas

const DEFAULT_BASE_SIZE := Vector2(1280, 720)

var base_size := DEFAULT_BASE_SIZE

func _ready() -> void:
	size = base_size
	_rescale()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_PARENTED:
		_rescale()

func _rescale() -> void:
	var parent_control := get_parent() as Control
	if parent_control == null:
		return
	var available := parent_control.size
	if available.x <= 0 or available.y <= 0:
		if not is_inside_tree():
			return
		available = get_viewport_rect().size
	var factor = min(available.x / base_size.x, available.y / base_size.y)
	scale = Vector2(factor, factor)
	position = (available - base_size * factor) * 0.5
	size = base_size
