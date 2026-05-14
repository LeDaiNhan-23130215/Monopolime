extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Control = load("res://scenes/ui/SetupScreen.tscn").instantiate()
	root.add_child(scene)
	scene.size = Vector2(1600, 900)
	await process_frame
	var canvas: Control = scene.get_node("DesignCanvas")
	print("canvas size=", canvas.size, " min=", canvas.get_minimum_size())
	_print_tree(canvas, 0)
	quit(0)

func _print_tree(node: Node, depth: int) -> void:
	if node is Control:
		var c := node as Control
		if depth <= 8:
			print(" ".repeat(depth * 2), c.name, " size=", c.size, " min=", c.get_minimum_size(), " custom=", c.custom_minimum_size)
	for child in node.get_children():
		_print_tree(child, depth + 1)
