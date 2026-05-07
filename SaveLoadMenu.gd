extends Control
class_name SaveLoadMenu

signal save_slot_requested(slot_id: int)
signal load_slot_requested(slot_id: int)
signal menu_closed

const SLOT_COUNT := 10

@onready var dimmer: ColorRect = $Dimmer
@onready var slots_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/Content/Slots
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/Content/Header/CloseButton

var slot_date_labels: Dictionary = {}
var slot_load_buttons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	dimmer.gui_input.connect(_on_dimmer_gui_input)
	close_button.pressed.connect(close_menu)
	_build_slots()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()


func open_menu() -> void:
	refresh_slots()
	visible = true
	close_button.grab_focus()


func close_menu() -> void:
	if not visible:
		return
	visible = false
	emit_signal("menu_closed")


func _build_slots() -> void:
	slot_date_labels.clear()
	slot_load_buttons.clear()

	for child in slots_container.get_children():
		child.queue_free()

	for slot_id in range(1, SLOT_COUNT + 1):
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label = Label.new()
		label.text = "Slot %02d" % [slot_id]
		label.custom_minimum_size = Vector2(90, 0)
		row.add_child(label)

		var date_label = Label.new()
		date_label.text = "Empty"
		date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(date_label)

		var save_button = Button.new()
		save_button.text = "Save"
		save_button.custom_minimum_size = Vector2(96, 0)
		save_button.pressed.connect(_on_save_pressed.bind(slot_id))
		row.add_child(save_button)

		var load_button = Button.new()
		load_button.text = "Load"
		load_button.custom_minimum_size = Vector2(96, 0)
		load_button.pressed.connect(_on_load_pressed.bind(slot_id))
		row.add_child(load_button)

		slot_date_labels[slot_id] = date_label
		slot_load_buttons[slot_id] = load_button

		slots_container.add_child(row)

	refresh_slots()


func refresh_slots() -> void:
	for slot_id in range(1, SLOT_COUNT + 1):
		var slot: SaveSlot = StorageService.load_file(slot_id)

		var date_label := slot_date_labels.get(slot_id) as Label
		if date_label:
			date_label.text = slot.date_save if not slot.is_empty() else "Empty"

		var load_button := slot_load_buttons.get(slot_id) as Button
		if load_button:
			load_button.disabled = slot.is_empty()


func _on_save_pressed(slot_id: int) -> void:
	emit_signal("save_slot_requested", slot_id)


func _on_load_pressed(slot_id: int) -> void:
	emit_signal("load_slot_requested", slot_id)


func _on_dimmer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
