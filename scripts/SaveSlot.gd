extends Resource
class_name SaveSlot

var id: int = 0
var date_save: String = ""
var is_auto: bool = false
var occupied: bool = false


func _init(slot_id: int = 0, saved_at: String = "", auto_slot: bool = false, has_data: bool = false) -> void:
	id = slot_id
	date_save = saved_at
	is_auto = auto_slot
	occupied = has_data


func is_empty() -> bool:
	return not occupied or date_save.is_empty()


func to_dict() -> Dictionary:
	return {
		"id": id,
		"date_save": date_save,
		"is_auto": is_auto,
		"occupied": occupied
	}


static func from_dict(data: Dictionary) -> SaveSlot:
	return SaveSlot.new(
		int(data.get("id", 0)),
		str(data.get("date_save", "")),
		bool(data.get("is_auto", false)),
		bool(data.get("occupied", false))
	)
