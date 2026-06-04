extends RefCounted
class_name JailManager

# =========================
# JailManager – UC-09: Vào Tù và Ra Tù
#
# Luồng chính:
#   9.1.1 → 9.1.3 : go_to_jail() 
#   9.1.4          : begin_jail_turn() 
#   9.1.5 → 9.1.6 : resolve_jail_turn()
#   9.2.x          : _try_escape_*() 
#   9.3.x          : _handle_fine_broke()
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

## 9.1.1 → 9.1.3  Đưa người chơi vào tù ngay lập tức.
## Gọi khi: dừng ô "Vào tù", rút thẻ sự kiện, đổ double 3 lần (BR-04, BR-26).
func go_to_jail(player: Player) -> void:
	print("🔒 [JailManager] ", player.name, " VÀO TÙ! (BR-21, BR-25, BR-26)")

	# 9.1.2 – Di chuyển đến ô Thăm tù
	player.state.update_position(JAIL_POSITION)

	# 9.1.3 – Đánh dấu trạng thái, đặt bộ đếm lượt tù = 0
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

	# 9.1.3 – Kết thúc lượt chơi hiện tại ngay lập tức (GameController xử lý end_turn)


## 9.1.4  Đầu mỗi lượt của người đang ở tù: tăng bộ đếm, hiển thị trạng thái.
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


# =========================
# RA TÙ (9.2.x)
# =========================

## 9.1.5 → 9.1.6  Xử lý toàn bộ lượt của người đang ở tù sau khi tung xúc xắc.
## Gọi từ GameController.resolve_roll() thay cho _handle_jail_turn().
## Trả về true nếu người chơi đã ra tù và được di chuyển.
func resolve_jail_turn(player: Player, dice_result: DiceResult) -> bool:
	var turns_so_far: int = player.state.jail_turns  # đã tăng bởi begin_jail_turn()

	# --- Ưu tiên 1: Có thẻ Ra Tù + không đổ double → dùng thẻ (BR-28 nhánh 9.2.3)
	if player.state.special_cards > 0 and not dice_result.is_double:
		return await _try_escape_with_card(player, dice_result)

	# --- Ưu tiên 2: Đổ double → ra tù miễn phí (BR-28 nhánh 9.2.1)
	if dice_result.is_double:
		return await _try_escape_with_double(player, dice_result)

	# --- Không đổ double, không có thẻ
	# Nếu đủ 3 lượt → cưỡng chế nộp phạt (BR-27, BR-28 nhánh 9.2.5)
	if turns_so_far >= MAX_JAIL_TURNS:
		return await _force_pay_fine(player, dice_result)

	# Còn lượt → giữ nguyên vị trí, kết thúc lượt
	_gc.ui.show_message(
		player.name + " không đổ Double. Vẫn ở Tù (Lượt " +
		str(turns_so_far) + "/" + str(MAX_JAIL_TURNS) + ").")
	_gc.ui.add_history(player.name + " ở lại Tù lượt " + str(turns_so_far), Color("#795548"))
	return false


## 9.2.3 → 9.2.4  Dùng thẻ Ra Tù miễn phí.
func _try_escape_with_card(player: Player, dice_result: DiceResult) -> bool:
	print("[JailManager] ", player.name, " dùng thẻ Ra Tù (BR-28 nhánh 9.2.3)")

	# 9.2.4 – Thu hồi 1 thẻ từ kho đồ
	player.state.special_cards -= 1

	# 9.1.6 – Gỡ trạng thái tù
	_release_from_jail(player)

	_gc.ui.show_message(player.name + " dùng thẻ Ra Tù Miễn Phí! (còn " +
		str(player.state.special_cards) + " thẻ)")
	_gc.ui.add_history(player.name + " thoát tù bằng thẻ đặc biệt", Color("#1B5E20"))

	# Cho phép di chuyển theo điểm xúc xắc (9.1.6)
	await _gc.move_player(player, dice_result.total())
	await _gc.handle_landed_cell(player, player.state.position)
	return true


## 9.2.1 → 9.2.2  Đổ double → ra tù, di chuyển theo tổng xúc xắc.
func _try_escape_with_double(player: Player, dice_result: DiceResult) -> bool:
	print("[JailManager] ", player.name, " đổ Double – thoát tù! (BR-28 nhánh 9.2.1)")

	# 9.1.6 – Gỡ trạng thái tù, đặt lại bộ đếm
	_release_from_jail(player)

	_gc.ui.show_message(player.name + " đổ Double – Thoát Tù!")
	_gc.ui.add_history(player.name + " thoát tù bằng Double", Color("#1B5E20"))

	# Di chuyển bình thường theo tổng xúc xắc (9.1.6)
	await _gc.move_player(player, dice_result.total())
	await _gc.handle_landed_cell(player, player.state.position)
	return true


## 9.2.5 → 9.2.6  Cưỡng chế nộp phạt $50 sau khi hết 3 lượt.
func _force_pay_fine(player: Player, dice_result: DiceResult) -> bool:
	print("[JailManager] ", player.name, " hết 3 lượt – cưỡng chế nộp $", JAIL_FINE, " (BR-27, BR-28)")

	_gc.ui.show_message(player.name + " hết " + str(MAX_JAIL_TURNS) +
		" lượt! Bị cưỡng chế nộp phạt $" + str(JAIL_FINE) + ".")

	# 9.2.6 – Kiểm tra số dư trước khi nộp
	var paid: bool = await _pay_fine(player, dice_result)
	return paid


## 9.2.5 Người chơi tự nguyện nộp phạt $50 để ra tù.
func pay_fine_voluntarily(player: Player, dice_result: DiceResult) -> bool:
	print("[JailManager] ", player.name, " chủ động nộp phạt $", JAIL_FINE,)
	_gc.ui.show_message(player.name + " chọn nộp phạt $" + str(JAIL_FINE) + " để ra tù.")
	return await _pay_fine(player, dice_result)


## Nội bộ: kiểm tra tiền và trừ $50, sau đó cho di chuyển (9.2.6).
func _pay_fine(player: Player, dice_result: DiceResult) -> bool:
	# 7.2.6 – Đủ tiền mặt
	if FinanceManager.can_afford(player, JAIL_FINE):
		_gc.process_payment(player, null, JAIL_FINE, "Phạt tù $" + str(JAIL_FINE))
		_release_from_jail(player)

		_gc.ui.show_message(player.name + " nộp $" + str(JAIL_FINE) + " – Ra Tù!")
		_gc.ui.add_history(player.name + " trả $" + str(JAIL_FINE) + " ra tù", Color("#F57F17"))

		# 9.1.6 – Di chuyển theo xúc xắc
		await _gc.move_player(player, dice_result.total())
		await _gc.handle_landed_cell(player, player.state.position)
		return true

	# Không đủ tiền mặt → luồng ngoại lệ 9.3.x
	return await _handle_fine_broke(player, dice_result)


## 9.1.6 helper: xóa trạng thái tù, reset bộ đếm.
func _release_from_jail(player: Player) -> void:
	player.state.set_in_jail(false)   # set_in_jail(false) cũng reset jail_turns = 0
	print("[JailManager] ", player.name, " đã Ra Tù (9.1.6)")


# =========================
# NGÀY 3 9.3.x & TÍCH HỢP GAME CONTROLLER
# =========================

## 9.3.1 → 9.3.3  Xử lý khi người chơi không đủ $50 tiền mặt để nộp phạt.
func _handle_fine_broke(player: Player, dice_result: DiceResult) -> bool:
	print("[JailManager] ", player.name, " thiếu tiền mặt cho phạt tù (9.3.1)")

	# 9.3.1 – Tính tổng khả năng tài chính (tiền mặt + giá trị thế chấp)
	var total_capacity: int = player.get_total_capacity()

	_gc.ui.show_message(
		player.name + " thiếu tiền mặt! Tiền mặt: $" + str(player.state.balance) +
		" | Tổng tài sản có thể huy động: $" + str(total_capacity))
	_gc.ui.add_history(
		player.name + " thiếu $" + str(JAIL_FINE) + " tiền mặt (tổng tài sản: $" +
		str(total_capacity) + ")", Color("#E65100"))

	# 9.3.2 – Đủ khả năng tài chính (nhờ thế chấp)
	if total_capacity >= JAIL_FINE:
		print("[JailManager] 9.3.2 – Yêu cầu thế chấp để gom đủ $", JAIL_FINE)
		_gc.ui.show_message(
			player.name + " cần thế chấp tài sản để gom đủ $" + str(JAIL_FINE) +
			". Mở Quản lý tài sản...")

		# Mở giao diện quản lý tài sản, chờ người chơi thế chấp đủ tiền
		var amount_needed: int = max(0, JAIL_FINE - player.state.balance)
		_gc.ui.request_mortgage(player, amount_needed)

		# Chờ sự kiện turn_action_completed phát ra từ FinanceManager/UI
		await _gc.turn_action_completed

		# Sau khi thế chấp, quay lại kiểm tra tiền (9.2.6)
		if FinanceManager.can_afford(player, JAIL_FINE):
			_gc.process_payment(player, null, JAIL_FINE, "Phạt tù sau thế chấp")
			_release_from_jail(player)

			_gc.ui.show_message(player.name + " đã nộp $" + str(JAIL_FINE) + " – Ra Tù!")
			_gc.ui.add_history(player.name + " thế chấp xong, trả $" + str(JAIL_FINE) + " ra tù", Color("#F57F17"))
			await _gc.move_player(player, dice_result.total())
			await _gc.handle_landed_cell(player, player.state.position)
			return true
		else:
			# Vẫn không đủ sau khi thế chấp → phá sản
			print("[JailManager] - Vẫn thiếu tiền sau thế chấp → phá sản")
			_declare_jail_bankruptcy(player)
			return false

	# 9.3.3 – Hoàn toàn không đủ tài chính → phá sản
	print("[JailManager] 9.3.3 – Tổng tài sản < $", JAIL_FINE, " → kích hoạt phá sản (BR-30, BR-31)")
	_declare_jail_bankruptcy(player)
	return false


## 9.3.3  Tuyên bố phá sản: giải phóng tài sản, loại khỏi ván (BR-30, BR-31).
func _declare_jail_bankruptcy(player: Player) -> void:
	_gc.ui.show_message("💀 " + player.name + " không thể trả phạt tù – PHÁ SẢN! (BR-31)")
	_gc.ui.add_history("💀 " + player.name + " phá sản trong tù", Color("#B71C1C"))

	# Giải phóng toàn bộ tài sản về ngân hàng (BR-30)
	player.release_all_assets()

	if _gc.board.has_method("remove_player_token"):
		_gc.board.remove_player_token(player)

	# Vẽ lại bảng
	for cell in _gc.board.cells:
		cell.queue_redraw()

	_gc.emit_signal("turn_action_completed")


# =========================
# TÍCH HỢP: API CHO GAMECONTROLLER
# =========================

## Thay thế GameController._handle_jail_turn().
## Gọi từ GameController.resolve_roll() khi player.state.in_jail == true.
##
## Sử dụng:
##   if player.state.in_jail:
##       var escaped = await jail_manager.handle_jail_turn(player, final_result)
##       end_turn()
##       ...
##       return
func handle_jail_turn(player: Player, dice_result: DiceResult) -> bool:
	# 9.1.4 – Tăng bộ đếm lượt tù (begin_jail_turn được gọi ở start_turn)
	# Ở đây chỉ resolve sau khi tung xúc xắc.
	var escaped = await resolve_jail_turn(player, dice_result)
	_gc.ui.update_player_info(_gc.game_state.players)
	return escaped


## Kiểm tra nhanh các điều kiện vào tù để GameController dùng thống nhất.
## Trả về lý do vào tù hoặc "" nếu không vào tù.
static func get_jail_trigger(is_double: bool, double_count: int, cell_type: String, card_action: String) -> String:
	if double_count >= 3:
		return "triple_double"   # BR-04
	if cell_type == "go_to_jail":
		return "cell"            # BR-26 – dừng vào ô Vào tù
	if card_action == "go_jail":
		return "card"            # BR-26 – rút thẻ sự kiện vào tù
	return ""
