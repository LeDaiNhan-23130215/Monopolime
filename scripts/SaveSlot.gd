extends Resource
class_name SaveSlot

var id: int = 0
var date_save: String = ""
var is_auto: bool = false
var occupied: bool = false
var v_total: int = 0
var player_count: int = 0


func _init(slot_id: int = 0, saved_at: String = "", auto_slot: bool = false, has_data: bool = false, total: int = 0, count: int = 0) -> void:
	id = slot_id
	date_save = saved_at
	is_auto = auto_slot
	occupied = has_data
	v_total = total
	player_count = count


func is_empty() -> bool:
	return not occupied or date_save.is_empty()


func to_dict() -> Dictionary:
	return {
		"id": id,
		"date_save": date_save,
		"is_auto": is_auto,
		"occupied": occupied,
		"v_total": v_total,
		"player_count": player_count
	}


static func from_dict(data: Dictionary) -> SaveSlot:
	return SaveSlot.new(
		int(data.get("id", 0)),
		str(data.get("date_save", "")),
		bool(data.get("is_auto", false)),
		bool(data.get("occupied", false)),
		int(data.get("v_total", 0)),
		int(data.get("player_count", 0))
	)
