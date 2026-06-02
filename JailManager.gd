extends RefCounted
class_name JailManager

# =========================
# JailManager – UC-07: Vào Tù và Ra Tù
# Tách biệt toàn bộ nghiệp vụ tù ra khỏi GameController
# để dễ kiểm thử và bảo trì.
# Nguyễn Văn Thanh
# Luồng chính:
#   7.1.1 → 7.1.3 : go_to_jail()          (Ngày 1)
#   7.1.4          : begin_jail_turn()     (Ngày 1)
#   7.1.5 → 7.1.6 : resolve_jail_turn()   (Ngày 2)
#   7.2.x          : _try_escape_*()       (Ngày 2)
#   7.3.x          : _handle_fine_broke()  (Ngày 3)
# =========================

const JAIL_POSITION   : int = 10   # BR-21, BR-25
const JAIL_FINE       : int = 50   # BR-29
const MAX_JAIL_TURNS  : int = 3    # BR-27

# Phụ thuộc được inject từ ngoài (GameController)
var _gc: GameController  # GameController

func _init(game_controller: GameController) -> void:
	_gc = game_controller


# =========================
# VÀO TÙ & TRẠNG THÁI TÙ
# =========================

## 7.1.1 → 7.1.3  Đưa người chơi vào tù ngay lập tức.
## Gọi khi: dừng ô "Vào tù", rút thẻ sự kiện, đổ double 3 lần (BR-04, BR-26).
func go_to_jail(player: Player) -> void:
	print("🔒 [JailManager] ", player.name, " VÀO TÙ! (BR-21, BR-25, BR-26)")

	# 7.1.2 – Di chuyển đến ô Thăm tù (index 10)
	player.state.update_position(JAIL_POSITION)

	# 7.1.3 – Đánh dấu trạng thái, đặt bộ đếm lượt tù = 0
	player.state.set_in_jail(true)   # set_in_jail(true) đã reset jail_turns = 0

	# Hiệu ứng UI
	_gc.ui.play_sfx(GameUI.SFX_JAIL)
	_gc.ui.show_jail()

	var world_pos = _gc.board.get_cell_position(JAIL_POSITION)
	var offset    = _gc.get_offset(player.player_id)
	if player.token:
		await player.token.move_to(world_pos + offset)

	_gc.ui.show_message("🔒 " + player.name + " bị vào Tù! (Ô số " + str(JAIL_POSITION) + ")")
	_gc.ui.add_history(player.name + " bị vào Tù", Color("#B71C1C"))

	# 7.1.3 – Kết thúc lượt chơi hiện tại ngay lập tức (GameController xử lý end_turn)


## 7.1.4  Đầu mỗi lượt của người đang ở tù: tăng bộ đếm, hiển thị trạng thái.
## Trả về số lượt ở tù hiện tại (sau khi tăng).
func begin_jail_turn(player: Player) -> int:
	player.state.jail_turns += 1
	var turns_so_far: int = player.state.jail_turns

	print("[JailManager] ", player.name, " bắt đầu lượt tù ", turns_so_far, "/", MAX_JAIL_TURNS, " (BR-27)")

	# Người chơi không di chuyển nhưng vẫn giữ tài sản và thu tiền thuê (BR-27)
	# → GameController chỉ cần gọi begin_jail_turn và chờ người chơi chọn cách ra tù

	if player.state.special_cards > 0:
		_gc.ui.show_message(
			player.name + " đang ở Tù (Lượt " + str(turns_so_far) + "/" + str(MAX_JAIL_TURNS) +
			"). Có thẻ Ra Tù – chọn cách ra!")
	else:
		_gc.ui.show_message(
			player.name + " đang ở Tù (Lượt " + str(turns_so_far) + "/" + str(MAX_JAIL_TURNS) +
			"). Đổ Double hoặc Nộp $" + str(JAIL_FINE) + " để ra!")

	return turns_so_far


## Kiểm tra người chơi có đang ở tù không.
func is_in_jail(player: Player) -> bool:
	return player.state.in_jail


## Trả về số lượt đã ở tù (0 = vừa vào).
func jail_turns(player: Player) -> int:
	return player.state.jail_turns
