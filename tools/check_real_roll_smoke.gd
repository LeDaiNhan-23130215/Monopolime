extends SceneTree

var trace: FileAccess


class FixedDice extends Dice:
	var rolls := [
		DiceResult.new(1, 2),
		DiceResult.new(2, 3),
		DiceResult.new(3, 4),
		DiceResult.new(1, 5),
		DiceResult.new(2, 4),
		DiceResult.new(1, 3),
		DiceResult.new(2, 5),
		DiceResult.new(3, 5),
		DiceResult.new(1, 4),
		DiceResult.new(2, 2),
	]
	var index := 0

	func roll():
		var result: DiceResult = rolls[index % rolls.size()]
		index += 1
		return result


func _initialize() -> void:
	trace = FileAccess.open("res://tools/roll_smoke_trace.log", FileAccess.WRITE)
	_log("start")
	var packed: PackedScene = load("res://monopolime.tscn")
	_log("loaded scene")
	var main := packed.instantiate()
	_log("instantiated scene")
	get_root().add_child(main)
	_log("added main")
	await process_frame
	await process_frame
	_log("after ready frames")

	var controller: GameController = main.get_node("GameController")
	var ui: GameUI = main.get_node("GameUI")
	var fixed_dice := FixedDice.new()
	main.add_child(fixed_dice)
	controller.dice = fixed_dice
	_log("controller wired")

	ui._on_setup_start_requested({
		"starting_money": 5000,
		"max_turns": 40,
		"victory_mode": "turn_limit",
		"players": [
			{"name": "P1", "avatar_id": 0, "is_ai": false, "color_index": 0},
			{"name": "P2", "avatar_id": 1, "is_ai": false, "color_index": 1},
		],
	})
	_log("setup requested")
	await process_frame
	_log("after setup frame")

	var failures: Array[String] = []
	for roll_index in range(3):
		print("SMOKE roll ", roll_index + 1, " start player=", controller.game_state.current_player, " pos=", controller.get_current_player().state.position)
		_log("roll " + str(roll_index + 1) + " start player=" + str(controller.game_state.current_player) + " pos=" + str(controller.get_current_player().state.position))
		controller.roll_dice()
		var frames := 0
		while (controller.is_rolling or controller.is_turn_resolving) and frames < 900:
			_auto_dismiss(ui, controller)
			await process_frame
			frames += 1
			if frames % 120 == 0:
				print("SMOKE roll ", roll_index + 1, " frame=", frames, " is_rolling=", controller.is_rolling, " resolving=", controller.is_turn_resolving, " ui_rolling=", ui._rolling, " ui_resolving=", ui._resolving_roll, " pos=", controller.get_current_player().state.position)
				_log("roll " + str(roll_index + 1) + " frame=" + str(frames) + " is_rolling=" + str(controller.is_rolling) + " resolving=" + str(controller.is_turn_resolving) + " ui_rolling=" + str(ui._rolling) + " ui_resolving=" + str(ui._resolving_roll) + " pos=" + str(controller.get_current_player().state.position))
		_auto_dismiss(ui, controller)
		if controller.is_rolling or controller.is_turn_resolving:
			failures.append("roll " + str(roll_index + 1) + " did not finish within 900 frames")
			break
		if ui._rolling or ui._resolving_roll:
			failures.append("ui roll state stayed active after roll " + str(roll_index + 1))
			break
		_log("roll " + str(roll_index + 1) + " complete")

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS check_real_roll_smoke")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _auto_dismiss(ui: GameUI, controller: GameController) -> void:
	if ui.buy_popup and ui.buy_popup.visible:
		_log("auto dismiss buy")
		controller.call_deferred("emit_signal", "buy_decision_made", true)
		ui.buy_popup.visible = false
	if ui.event_popup and ui.event_popup.visible:
		_log("auto dismiss event")
		ui.event_popup.visible = false
		ui.emit_signal("card_dismissed")
	if ui.rent_popup and ui.rent_popup.visible:
		_log("auto dismiss rent")
		ui.rent_popup.visible = false
		ui.emit_signal("card_dismissed")
	if ui.build_popup and ui.build_popup.visible:
		_log("auto dismiss build")
		ui.build_popup.visible = false
		controller.emit_signal("build_decision_made")


func _log(message: String) -> void:
	if trace:
		trace.store_line(str(Time.get_ticks_msec()) + " " + message)
		trace.flush()
