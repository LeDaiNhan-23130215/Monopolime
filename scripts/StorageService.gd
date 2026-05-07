extends Node

const SLOT_COUNT := 10
const SLOT_FILE_TEMPLATE := "user://save_slot_%02d.json"


func save_file(save_id: int) -> bool:
	if not _is_valid_slot(save_id):
		push_warning("Invalid save slot id: %d" % save_id)
		return false

	var slot = SaveSlot.new(save_id, _formatted_now())
	var file = FileAccess.open(_slot_path(save_id), FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save file for slot %d" % save_id)
		return false

	file.store_string(JSON.stringify(slot.to_dict()))
	return true


func load_file(save_id: int) -> SaveSlot:
	if not _is_valid_slot(save_id):
		push_warning("Invalid load slot id: %d" % save_id)
		return SaveSlot.new()

	var path = _slot_path(save_id)
	if not FileAccess.file_exists(path):
		return SaveSlot.new(save_id, "")

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return SaveSlot.new(save_id, "")

	var raw_text = file.get_as_text()
	var parsed = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is invalid JSON for slot %d" % save_id)
		return SaveSlot.new(save_id, "")

	return SaveSlot.from_dict(parsed)


func has_save(save_id: int) -> bool:
	if not _is_valid_slot(save_id):
		return false
	return not load_file(save_id).is_empty()


func list_save_slots() -> Array[SaveSlot]:
	var slots: Array[SaveSlot] = []
	for slot_id in range(1, SLOT_COUNT + 1):
		slots.append(load_file(slot_id))
	return slots


func _slot_path(save_id: int) -> String:
	return SLOT_FILE_TEMPLATE % save_id


func _is_valid_slot(save_id: int) -> bool:
	return save_id >= 1 and save_id <= SLOT_COUNT


func _formatted_now() -> String:
	var dt = Time.get_datetime_dict_from_system()
	return "%02d:%02d:%02d %02d/%02d/%04d" % [
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
		int(dt.get("second", 0)),
		int(dt.get("day", 1)),
		int(dt.get("month", 1)),
		int(dt.get("year", 1970))
	]

func check_storage_availability():
	return 0
	
func validate_checksum(data):
	return 0
