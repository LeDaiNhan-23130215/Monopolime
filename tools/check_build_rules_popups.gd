extends SceneTree

const VIEWPORTS := [
	Vector2(960, 540),
	Vector2(1280, 720),
	Vector2(1366, 768),
	Vector2(1920, 1080),
]

var _sample_cells := []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures := []
	for scene_path in ["res://scenes/ui/popups/BuildPopup.tscn", "res://scenes/ui/popups/RulesPopup.tscn"]:
		var packed: PackedScene = load(scene_path)
		if packed == null:
			failures.append(scene_path + " could not be loaded")
			continue
		for viewport_size in VIEWPORTS:
			var holder := Control.new()
			holder.size = viewport_size
			root.add_child(holder)
			var scene := packed.instantiate() as Control
			holder.add_child(scene)
			scene.set_anchors_preset(Control.PRESET_FULL_RECT)
			scene.offset_left = 0.0
			scene.offset_top = 0.0
			scene.offset_right = 0.0
			scene.offset_bottom = 0.0
			await process_frame
			if scene_path.ends_with("BuildPopup.tscn"):
				scene.call("show_build_options", _sample_player(), _sample_cells)
			else:
				scene.call("show_rules")
			await process_frame
			var canvas := scene.get_node_or_null("DesignCanvas") as Control
			if canvas == null:
				failures.append(scene_path + " missing DesignCanvas")
			else:
				canvas.call("_rescale")
				_check_control_bounds(scene_path, viewport_size, canvas, canvas.get_global_rect(), failures)
			holder.queue_free()
			await process_frame

	_free_sample_cells()
	if failures.is_empty():
		print("Build and rules popup layout check passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _sample_player() -> Player:
	var player := Player.new(0, "Người chơi 1")
	player.state.balance = 1500
	_sample_cells.clear()
	for data in [
		["Nha Trang", "green", 300, 50, 150, 1],
		["Đà Nẵng", "blue", 260, 45, 130, 2],
		["Hà Nội", "red", 500, 90, 250, 4],
	]:
		var cell := _sample_cell(data[0], data[1], data[2], data[3], data[4], data[5])
		cell.cell_owner = player
		player.properties.append(cell)
	return player

func _sample_cell(cell_name: String, color_group: String, price: int, rent: int, house_cost: int, level: int) -> Cell:
	var cell := Cell.new()
	_sample_cells.append(cell)
	cell.setup({
		"name": cell_name,
		"type": "property",
		"price": price,
		"rent": rent,
		"color": color_group,
		"house_cost": house_cost,
		"rent_levels": [rent, rent * 2, rent * 3, rent * 4, rent * 5],
	})
	cell.house_count = level
	return cell

func _free_sample_cells() -> void:
	for cell in _sample_cells:
		if is_instance_valid(cell):
			cell.free()
	_sample_cells.clear()

func _check_control_bounds(scene_path: String, viewport_size: Vector2, node: Node, bounds: Rect2, failures: Array) -> void:
	if node is ScrollContainer:
		return
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			if control.is_visible_in_tree() and control.size.x > 1.0 and control.size.y > 1.0:
				var rect := control.get_global_rect()
				if rect.position.x < bounds.position.x - 2.0 or rect.position.y < bounds.position.y - 2.0:
					failures.append(scene_path + " at " + str(viewport_size) + " child " + control.name + " escapes top/left: " + str(rect))
				if rect.end.x > bounds.end.x + 2.0 or rect.end.y > bounds.end.y + 2.0:
					failures.append(scene_path + " at " + str(viewport_size) + " child " + control.name + " escapes bottom/right: " + str(rect))
			_check_control_bounds(scene_path, viewport_size, child, bounds, failures)
		else:
			_check_control_bounds(scene_path, viewport_size, child, bounds, failures)
