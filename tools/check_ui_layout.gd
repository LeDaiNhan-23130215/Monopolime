extends SceneTree

const SCENES := [
	"res://scenes/ui/SetupScreen.tscn",
	"res://scenes/ui/MainGameHUD.tscn",
	"res://scenes/ui/popups/BuyPropertyPopup.tscn",
	"res://scenes/ui/popups/RentPopup.tscn",
	"res://scenes/ui/popups/EventPopup.tscn",
	"res://scenes/ui/popups/BuildPopup.tscn",
	"res://scenes/ui/popups/AssetsPopup.tscn",
	"res://scenes/ui/GameOverScreen.tscn",
]

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
	for scene_path in SCENES:
		var packed: PackedScene = load(scene_path)
		if packed == null:
			failures.append(scene_path + " could not be loaded")
			continue
		for viewport_size in VIEWPORTS:
			var holder := Control.new()
			holder.anchor_left = 0.0
			holder.anchor_top = 0.0
			holder.anchor_right = 0.0
			holder.anchor_bottom = 0.0
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
			_populate_sample_state(scene)
			await process_frame
			var canvas := scene.get_node_or_null("DesignCanvas") as Control
			if canvas == null:
				failures.append(scene_path + " missing DesignCanvas")
				holder.queue_free()
				await process_frame
				continue
			canvas.call("_rescale")
			var max_corner := canvas.position + canvas.size * canvas.scale
			if canvas.position.x < -0.5 or canvas.position.y < -0.5:
				failures.append(scene_path + " at " + str(viewport_size) + " has negative canvas position " + str(canvas.position))
			if max_corner.x > viewport_size.x + 0.5 or max_corner.y > viewport_size.y + 0.5:
				failures.append(scene_path + " at " + str(viewport_size) + " overflows to " + str(max_corner))
			_check_control_bounds(scene_path, viewport_size, canvas, canvas.get_global_rect(), failures)
			holder.queue_free()
			await process_frame

	if failures.is_empty():
		print("UI layout check passed.")
		_free_sample_cells()
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		_free_sample_cells()
		quit(1)

func _populate_sample_state(scene: Control) -> void:
	match scene.get_script().get_global_name():
		"MainGameHUD":
			var players := _sample_players()
			scene.call("set_turn", 12, "Người chơi 1")
			scene.call("set_message", "Người chơi 1 đã mua Nha Trang!")
			scene.call("set_dice", 4, 3)
			scene.call("update_players", players, 0)
		"BuyPropertyPopup":
			scene.call("show_property", _sample_cell("Nha Trang", "green", 300, 50, 150), _sample_players()[0])
		"RentPopup":
			var rent_players := _sample_players()
			scene.call("show_rent", rent_players[0], rent_players[1], _sample_cell("Sapa", "green", 280, 120, 150), 120)
		"EventPopup":
			scene.call("show_event", "Sinh nhật vui vẻ!", "Mỗi người chơi trả bạn $50", 50, "gift")
		"BuildPopup":
			var build_player: Player = _sample_players()[0]
			var build_cells := [
				_sample_cell("Nha Trang", "green", 300, 50, 150),
				_sample_cell("Đà Nẵng", "blue", 260, 45, 130),
				_sample_cell("Hà Nội", "red", 500, 90, 250),
			]
			for cell in build_cells:
				cell.cell_owner = build_player
				build_player.properties.append(cell)
			scene.call("show_build_options", build_player, build_cells)
		"AssetsPopup":
			var asset_player: Player = _sample_players()[0]
			for cell in [
				_sample_cell("Hà Nội", "red", 500, 90, 250),
				_sample_cell("Sapa", "green", 280, 60, 150),
				_sample_cell("Nha Trang", "green", 300, 50, 150),
				_sample_cell("Đà Nẵng", "blue", 260, 45, 130),
			]:
				cell.cell_owner = asset_player
				asset_player.properties.append(cell)
			scene.call("show_assets", asset_player)
		"GameOverScreen":
			var ranking_players := _sample_players()
			var rankings := []
			for i in range(ranking_players.size()):
				rankings.append({"player": ranking_players[i], "net_worth": 9300 - i * 1700})
			scene.call("show_rankings", ranking_players[0], rankings)

func _sample_players() -> Array:
	var names := ["Người chơi 1", "Máy 2", "Máy 3", "Máy 4"]
	var balances := [1500, 1200, 980, 760]
	var players := []
	for i in range(4):
		var player := Player.new(i, names[i])
		player.state.balance = balances[i]
		players.append(player)
	return players

func _sample_cell(cell_name: String, color_group: String, price: int, rent: int, house_cost: int) -> Cell:
	var cell := Cell.new()
	_sample_cells.append(cell)
	cell.setup({
		"name": cell_name,
		"type": "property",
		"price": price,
		"rent": rent,
		"color": color_group,
		"house_cost": house_cost,
		"rent_levels": [rent, rent * 2, rent * 3, rent * 4, rent * 5, rent * 7],
	})
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
			if control.visible and control.size.x > 1.0 and control.size.y > 1.0:
				var rect := control.get_global_rect()
				if rect.position.x < bounds.position.x - 2.0 or rect.position.y < bounds.position.y - 2.0:
					failures.append(scene_path + " at " + str(viewport_size) + " child " + control.name + " escapes top/left: " + str(rect))
				if rect.end.x > bounds.end.x + 2.0 or rect.end.y > bounds.end.y + 2.0:
					failures.append(scene_path + " at " + str(viewport_size) + " child " + control.name + " escapes bottom/right: " + str(rect))
			_check_control_bounds(scene_path, viewport_size, child, bounds, failures)
		else:
			_check_control_bounds(scene_path, viewport_size, child, bounds, failures)
