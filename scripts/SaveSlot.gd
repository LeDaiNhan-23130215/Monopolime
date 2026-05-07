extends Resource
class_name SaveSlot

var id: int = 0
var date_save: String = ""


func _init(slot_id: int = 0, saved_at: String = "") -> void:
	id = slot_id
	date_save = saved_at


func is_empty() -> bool:
	return date_save.is_empty()


func to_dict() -> Dictionary:
	return {
		"id": id,
		"date_save": date_save
	}


static func from_dict(data: Dictionary) -> SaveSlot:
	return SaveSlot.new(
		int(data.get("id", 0)),
		str(data.get("date_save", ""))
	)
