extends PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	print(size)
	print(get_global_rect())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
