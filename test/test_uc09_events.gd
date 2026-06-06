extends GutTest

# ════════════════════════════════════════════════════════════════════
# Test UC-09: Xử lý sự kiện (thẻ Cơ Hội / Khí Vận)
# Kiểm tra trực tiếp EventHandler._on_choice_selected với từng loại thẻ,
# không cần UI thật. Bao gồm cả 2 lỗi đã sửa (birthday, move target).
# ════════════════════════════════════════════════════════════════════

func _make_board() -> Board:
	var board := Board.new()
	for i in range(20):
		board.cell_positions.append(Vector2(i * 10, 0))
		var c := Cell.new()
		c.index = i
		board.cells.append(c)
	return board

# Tạo controller + state + handler (KHÔNG gắn UI để cô lập logic)
func _make_ctx() -> Dictionary:
	var controller := GameController.new()
	add_child_autofree(controller)

	var state := GameState.new()
	var p1 := Player.new(0, "P1")
	var p2 := Player.new(1, "P2")
	state.players = [p1, p2]
	state.current_player = 0
	state.board_size = 20

	controller.game_state = state
	controller.board = _make_board()
	controller.ui = null  # các hàm đều guard `if ui:` nên an toàn

	var eh := EventHandler.new(controller)
	add_child_autofree(eh)
	return {"c": controller, "eh": eh, "p1": p1, "p2": p2}


func test_reward_cong_tien():
	var ctx := _make_ctx()
	var p: Player = ctx["p1"]
	p.state.balance = 1000
	ctx["eh"]._current_player = p
	ctx["eh"]._current_card = {"type": "reward", "amount": 150}
	ctx["eh"]._on_choice_selected(0)
	assert_eq(p.state.balance, 1150, "reward +150")


func test_penalty_tru_tien():
	var ctx := _make_ctx()
	var p: Player = ctx["p1"]
	p.state.balance = 1000
	ctx["eh"]._current_player = p
	ctx["eh"]._current_card = {"type": "penalty", "amount": 50}
	ctx["eh"]._on_choice_selected(0)
	assert_eq(p.state.balance, 950, "penalty -50")


func test_move_ve_xuat_phat_cong_200():
	var ctx := _make_ctx()
	var p: Player = ctx["p1"]
	p.state.balance = 1000
	p.state.position = 8
	ctx["eh"]._current_player = p
	ctx["eh"]._current_card = {"type": "move", "target": 0}
	await ctx["eh"]._on_choice_selected(0)
	assert_eq(p.state.position, 0, "move ve o 0")
	assert_eq(p.state.balance, 1200, "qua GO +200")


func test_move_toi_bai_do_xe_dung_o():
	# Lỗi cũ: thẻ ghi target=20 (ngoài bàn 20 ô). Đã sửa thành 10.
	var ctx := _make_ctx()
	var p: Player = ctx["p1"]
	p.state.position = 3
	ctx["eh"]._current_player = p
	ctx["eh"]._current_card = {"type": "move", "target": 10}
	await ctx["eh"]._on_choice_selected(0)
	assert_eq(p.state.position, 10, "move toi o 10 (Bai do xe)")
	assert_between(p.state.position, 0, 19, "vi tri nam trong ban 20 o")


func test_jail_vao_tu():
	var ctx := _make_ctx()
	var p: Player = ctx["p1"]
	p.state.in_jail = false
	ctx["eh"]._current_player = p
	ctx["eh"]._current_card = {"type": "jail"}
	await ctx["eh"]._on_choice_selected(0)
	assert_true(p.state.in_jail, "in_jail = true")
	assert_eq(p.state.position, 5, "ve o 5 (Tham tu)")


func test_card_ra_tu_mien_phi():
	var ctx := _make_ctx()
	var p: Player = ctx["p1"]
	p.state.get_out_of_jail_cards = 0
	ctx["eh"]._current_player = p
	ctx["eh"]._current_card = {"type": "card"}
	ctx["eh"]._on_choice_selected(0)
	assert_eq(p.state.get_out_of_jail_cards, 1, "+1 the ra tu")


func test_birthday_nguoi_khac_tra_tien():
	# Lỗi cũ: `get_players` thiếu () → không ai trả tiền. Đã sửa.
	var ctx := _make_ctx()
	var p1: Player = ctx["p1"]
	var p2: Player = ctx["p2"]
	p1.state.balance = 1000
	p2.state.balance = 1000
	ctx["eh"]._current_player = p1
	ctx["eh"]._current_card = {"type": "birthday"}
	ctx["eh"]._on_choice_selected(0)
	assert_eq(p1.state.balance, 1050, "P1 nhan 50")
	assert_eq(p2.state.balance, 950, "P2 tra 50")


func test_choice_nop_phat():
	var ctx := _make_ctx()
	var p: Player = ctx["p1"]
	p.state.balance = 1000
	ctx["eh"]._current_player = p
	ctx["eh"]._current_card = {"type": "choice", "choices": ["a", "b"]}
	ctx["eh"]._on_choice_selected(0)
	assert_eq(p.state.balance, 950, "choice idx=0 nop phat -50")


func test_khong_co_the_target_ngoai_ban():
	# Bảo đảm KHÔNG còn thẻ move nào có target ngoài phạm vi 0..19
	var ctx := _make_ctx()
	var eh = ctx["eh"]
	var bad: Array = []
	for deck in [eh.chance_cards, eh.community_chest_cards]:
		for card in deck:
			if card.get("type", "") == "move":
				var t: int = int(card.get("target", 0))
				if t < 0 or t > 19:
					bad.append(t)
	assert_eq(bad.size(), 0, "khong co target ngoai 0..19, sai: " + str(bad))
