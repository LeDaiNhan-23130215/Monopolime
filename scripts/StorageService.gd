extends Node

const AUTO_SLOT_ID := 0
const SLOT_COUNT := 10
const SLOT_FILE_TEMPLATE := "user://save_slot_%02d.sav"
const STORAGE_CHECK_PATH := "user://.storage_check.tmp"


func save_file(save_id: int, game_data: Dictionary = {}) -> bool:
	if save_id == AUTO_SLOT_ID:
		push_warning("Slot 0 is reserved for auto-save")
		return false
	if not _is_valid_manual_slot(save_id):
		push_warning("Invalid save slot id: %d" % save_id)
		return false

	var slot = SaveSlot.new(save_id, _formatted_now(), false, true)
	var file = FileAccess.open(_slot_path(save_id), FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save file for slot %d" % save_id)
		return false

	var payload = slot.to_dict()
	for key in game_data.keys():
		payload[key] = game_data[key]

	file.store_string(_encode_payload(payload))
	return true


func save_auto(game_data: Dictionary = {}) -> bool:
	var slot = SaveSlot.new(AUTO_SLOT_ID, _formatted_now(), true, true)
	var file = FileAccess.open(_slot_path(AUTO_SLOT_ID), FileAccess.WRITE)
	if file == null:
		push_error("Cannot open auto-save file")
		return false

	var payload = slot.to_dict()
	for key in game_data.keys():
		payload[key] = game_data[key]

	file.store_string(_encode_payload(payload))
	return true


func load_file(save_id: int) -> SaveSlot:
	if not _is_valid_any_slot(save_id):
		push_warning("Invalid load slot id: %d" % save_id)
		return SaveSlot.new()

	var path = _slot_path(save_id)
	if not FileAccess.file_exists(path):
		return _empty_slot(save_id)

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _empty_slot(save_id)

	var raw_text = file.get_as_text()
	var parsed = _decode_payload(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is invalid for slot %d" % save_id)
		return _empty_slot(save_id)

	var loaded_slot = SaveSlot.from_dict(parsed)
	loaded_slot.id = save_id
	loaded_slot.is_auto = (save_id == AUTO_SLOT_ID)
	loaded_slot.occupied = not loaded_slot.date_save.is_empty()
	return loaded_slot


func load_game_data(save_id: int) -> Dictionary:
	if not _is_valid_any_slot(save_id):
		push_warning("Invalid load slot id: %d" % save_id)
		return {}

	var path = _slot_path(save_id)
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var raw_text = file.get_as_text()
	var parsed = _decode_payload(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is invalid for slot %d" % save_id)
		return {}

	return parsed


func has_save(save_id: int) -> bool:
	if not _is_valid_any_slot(save_id):
		return false
	return not load_file(save_id).is_empty()


func list_save_slots() -> Array[SaveSlot]:
	var slots: Array[SaveSlot] = []
	slots.append(load_file(AUTO_SLOT_ID))
	for slot_id in range(1, SLOT_COUNT + 1):
		slots.append(load_file(slot_id))
	return slots


func check_storage_availability() -> Dictionary:
	var check_file = FileAccess.open(STORAGE_CHECK_PATH, FileAccess.WRITE)
	if check_file == null:
		return {
			"ok": false,
			"reason": "unavailable"
		}

	check_file.store_string("storage_check")
	check_file.close()

	if not FileAccess.file_exists(STORAGE_CHECK_PATH):
		return {
			"ok": false,
			"reason": "full"
		}

	var remove_result = DirAccess.remove_absolute(ProjectSettings.globalize_path(STORAGE_CHECK_PATH))
	if remove_result != OK and remove_result != ERR_DOES_NOT_EXIST:
		push_warning("Storage check file cleanup failed")

	return {
		"ok": true,
		"reason": "ok"
	}


func _slot_path(save_id: int) -> String:
	return SLOT_FILE_TEMPLATE % save_id


func _is_valid_manual_slot(save_id: int) -> bool:
	return save_id >= 1 and save_id <= SLOT_COUNT


func _is_valid_any_slot(save_id: int) -> bool:
	return save_id == AUTO_SLOT_ID or _is_valid_manual_slot(save_id)


func _empty_slot(save_id: int) -> SaveSlot:
	return SaveSlot.new(save_id, "", save_id == AUTO_SLOT_ID, false)


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


func _encode_payload(payload: Dictionary) -> String:
	var json_text = JSON.stringify(payload)
	var bytes = json_text.to_utf8_buffer()
	return Marshalls.raw_to_base64(bytes)


func _decode_payload(encoded_text: String) -> Variant:
	if encoded_text.is_empty():
		return null

	var bytes = Marshalls.base64_to_raw(encoded_text)
	if bytes.is_empty():
		return null

	var json_text = bytes.get_string_from_utf8()
	return JSON.parse_string(json_text)

func validate_checksum(data):
	return 0
