extends Control
class_name GameOverScreen

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")
const UIFactory = preload("res://scripts/ui/UIFactory.gd")

signal play_again_requested
signal main_menu_requested

var subtitle: Label
var rows: VBoxContainer
var _confetti_rects: Array = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()
	UIFactory.make_responsive(self)

func _build() -> void:
	# Sky blue gradient background
	var bg := ColorRect.new()
	bg.color = Color("0B4FA0")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Confetti decoration on top portion
	var confetti = preload("res://scripts/ui/EventConfetti.gd").new()
	confetti.size = Vector2(1280, 220)
	confetti.position = Vector2.ZERO
	confetti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confetti.show_balloons = false
	confetti.confetti_count = 70
	add_child(confetti)

	# Decorative bottom cityscape strip
	var city_strip := ColorRect.new()
	city_strip.color = Color("083A7A")
	city_strip.position = Vector2(0, 760)
	city_strip.size = Vector2(1280, 140)
	add_child(city_strip)

	# Dice decorations (bottom corners)
	var dice_left := UIFactory.icon("dice", CoTyPhuTheme.GOLD, Vector2(90, 90))
	dice_left.position = Vector2(30, 740)
	add_child(dice_left)
	var dice_right := UIFactory.icon("dice", CoTyPhuTheme.GOLD, Vector2(90, 90))
	dice_right.position = Vector2(1160, 740)
	add_child(dice_right)

	# Player tokens bottom decoration
	var token_colors := [CoTyPhuTheme.BLUE, CoTyPhuTheme.RED, CoTyPhuTheme.GREEN, CoTyPhuTheme.GOLD]
	for i in range(4):
		var tok := UIFactory.icon("token", token_colors[i], Vector2(70, 80))
		tok.position = Vector2(140 + i * 80, 750)
		add_child(tok)
	for i in range(4):
		var tok := UIFactory.icon("token", token_colors[i], Vector2(70, 80))
		tok.position = Vector2(820 + i * 80, 750)
		add_child(tok)

	# Trophy (right side)
	var trophy := UIFactory.icon("trophy", CoTyPhuTheme.GOLD, Vector2(180, 148))
	trophy.position = Vector2(1010, 22)
	add_child(trophy)

	# "Chiến thắng!" banner with ribbon ends
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color("C0181A")
	banner_style.border_color = Color("F4A000")
	banner_style.set_border_width_all(5)
	banner_style.set_corner_radius_all(10)
	banner_style.set_content_margin_all(14)
	banner_style.shadow_color = Color(0, 0, 0, 0.5)
	banner_style.shadow_size = 14
	var banner := PanelContainer.new()
	banner.position = Vector2(160, 28)
	banner.size = Vector2(820, 100)
	banner.add_theme_stylebox_override("panel", banner_style)
	add_child(banner)

	# Ribbon end (left swallow tail)
	var ribbon_left := _ribbon_tail(true)
	ribbon_left.position = Vector2(120, 50)
	add_child(ribbon_left)
	# Ribbon end (right)
	var ribbon_right := _ribbon_tail(false)
	ribbon_right.position = Vector2(980, 50)
	add_child(ribbon_right)

	# Crown on top of banner
	var crown_top := _draw_crown_node()
	crown_top.position = Vector2(540, 0)
	add_child(crown_top)

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 16)
	banner.add_child(title_row)

	var title := UIFactory.label("Chiến thắng!", 56, CoTyPhuTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_outline_color", Color(0.3, 0.1, 0.0, 0.7))
	title.add_theme_constant_override("outline_size", 7)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	# Subtitle
	subtitle = UIFactory.label("", 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	subtitle.add_theme_constant_override("outline_size", 4)
	subtitle.position = Vector2(280, 144)
	subtitle.size = Vector2(720, 50)
	add_child(subtitle)

	# Ranking table
	var table_style := StyleBoxFlat.new()
	table_style.bg_color = Color("EDF6FF")
	table_style.border_color = Color("57C6FF")
	table_style.set_border_width_all(4)
	table_style.set_corner_radius_all(18)
	table_style.set_content_margin_all(0)
	table_style.shadow_color = Color(0, 0, 0, 0.35)
	table_style.shadow_size = 14
	var table := PanelContainer.new()
	table.name = "Ranking"
	table.position = Vector2(80, 210)
	table.size = Vector2(1120, 370)
	table.add_theme_stylebox_override("panel", table_style)
	add_child(table)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	table.add_child(root)

	# Table header
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color("1768C0")
	header_style.set_border_width_all(0)
	header_style.set_corner_radius_all(14)
	header_style.corner_radius_bottom_left = 0
	header_style.corner_radius_bottom_right = 0
	header_style.set_content_margin_all(0)
	var header_cont := PanelContainer.new()
	header_cont.add_theme_stylebox_override("panel", header_style)
	root.add_child(header_cont)

	var header := HBoxContainer.new()
	header_cont.add_child(header)
	for item in [["Hạng", 130], ["Người chơi", 240], ["Tiền", 180], ["Tài sản", 140], ["Tổng tài sản", 210], ["Trạng thái", 200]]:
		header.add_child(_header_cell(item[0], item[1]))

	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	root.add_child(rows)

	# Buttons
	var play_again := _styled_button("🎲  Chơi lại", CoTyPhuTheme.GREEN, Vector2(330, 76))
	play_again.position = Vector2(220, 626)
	play_again.pressed.connect(func(): emit_signal("play_again_requested"))
	play_again.mouse_entered.connect(func(): play_again.scale = Vector2(1.05, 1.05))
	play_again.mouse_exited.connect(func(): play_again.scale = Vector2.ONE)
	add_child(play_again)

	var menu := _styled_button("🏠  Về menu", CoTyPhuTheme.BLUE, Vector2(330, 76))
	menu.position = Vector2(640, 626)
	menu.pressed.connect(func(): emit_signal("main_menu_requested"))
	menu.mouse_entered.connect(func(): menu.scale = Vector2(1.05, 1.05))
	menu.mouse_exited.connect(func(): menu.scale = Vector2.ONE)
	add_child(menu)

func show_rankings(winner: Player, rankings: Array) -> void:
	visible = true
	subtitle.text = winner.name + " là người chiến thắng"
	for child in rows.get_children():
		child.queue_free()
	var rank_num := 1
	for item in rankings:
		var p: Player = item.get("player")
		var is_winner := p == winner
		var cash := p.state.balance if p and p.state else 0
		var props := p.properties.size() if p else 0
		var net := int(item.get("net_worth", cash))
		var status := "CHIẾN THẮNG" if is_winner else "Xếp thứ " + str(rank_num)
		rows.add_child(_table_row(rank_num, p, cash, props, net, status, is_winner))
		rank_num += 1
	_animate_open()

func _table_row(rank: int, p: Player, cash: int, props: int, net: int, status: String, is_winner: bool) -> Control:
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color("FFF4C4") if is_winner else (Color("F8F4EA") if rank % 2 == 0 else Color.WHITE)
	row_style.border_color = Color("E8D090") if is_winner else Color("E0D8C8")
	row_style.set_border_width_all(0)
	row_style.border_width_bottom = 1
	row_style.set_corner_radius_all(0)
	row_style.set_content_margin_all(0)

	var row_panel := PanelContainer.new()
	row_panel.add_theme_stylebox_override("panel", row_style)

	var row := HBoxContainer.new()
	row_panel.add_child(row)

	var player_color := CoTyPhuTheme.player_color(rank - 1)

	# Rank with medal icon
	var rank_cell := _data_cell(rank, 130, 72, Color.TRANSPARENT)
	var rank_col := VBoxContainer.new()
	rank_col.alignment = BoxContainer.ALIGNMENT_CENTER
	rank_col.custom_minimum_size = Vector2(130, 72)
	row.add_child(rank_col)
	var medal_label := _medal_label(rank, is_winner)
	rank_col.add_child(medal_label)

	# Player
	var player_col := HBoxContainer.new()
	player_col.add_theme_constant_override("separation", 8)
	player_col.alignment = BoxContainer.ALIGNMENT_CENTER
	player_col.custom_minimum_size = Vector2(240, 72)
	row.add_child(player_col)
	player_col.add_child(UIFactory.icon("token", player_color, Vector2(38, 44)))
	var player_name := UIFactory.label(p.name if p else "?", 22, player_color)
	player_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.2))
	player_name.add_theme_constant_override("outline_size", 2)
	player_col.add_child(player_name)

	# Cash
	var cash_col := HBoxContainer.new()
	cash_col.alignment = BoxContainer.ALIGNMENT_CENTER
	cash_col.add_theme_constant_override("separation", 4)
	cash_col.custom_minimum_size = Vector2(180, 72)
	row.add_child(cash_col)
	cash_col.add_child(UIFactory.icon("money", CoTyPhuTheme.GREEN, Vector2(26, 26)))
	var cash_lbl := UIFactory.label("$" + str(cash), 22, CoTyPhuTheme.TEXT_DARK)
	cash_col.add_child(cash_lbl)

	# Assets
	var asset_col := HBoxContainer.new()
	asset_col.alignment = BoxContainer.ALIGNMENT_CENTER
	asset_col.add_theme_constant_override("separation", 4)
	asset_col.custom_minimum_size = Vector2(140, 72)
	row.add_child(asset_col)
	asset_col.add_child(UIFactory.icon("home", CoTyPhuTheme.GREEN, Vector2(26, 26)))
	var props_lbl := UIFactory.label(str(props), 22, CoTyPhuTheme.TEXT_DARK)
	asset_col.add_child(props_lbl)

	# Net worth
	var net_lbl := UIFactory.label("$" + str(net), 26, CoTyPhuTheme.BLUE if not is_winner else CoTyPhuTheme.TEXT_GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	net_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.2))
	net_lbl.add_theme_constant_override("outline_size", 3)
	net_lbl.custom_minimum_size = Vector2(210, 72)
	net_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(net_lbl)

	# Status
	var status_cell := VBoxContainer.new()
	status_cell.alignment = BoxContainer.ALIGNMENT_CENTER
	status_cell.custom_minimum_size = Vector2(200, 72)
	row.add_child(status_cell)

	if is_winner:
		var win_style := StyleBoxFlat.new()
		win_style.bg_color = CoTyPhuTheme.GREEN
		win_style.set_border_width_all(0)
		win_style.set_corner_radius_all(12)
		win_style.set_content_margin_all(8)
		var win_badge := PanelContainer.new()
		win_badge.add_theme_stylebox_override("panel", win_style)
		win_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var win_lbl := UIFactory.label("CHIẾN THẮNG", 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		win_lbl.add_theme_color_override("font_outline_color", Color(0, 0.15, 0, 0.4))
		win_lbl.add_theme_constant_override("outline_size", 2)
		win_badge.add_child(win_lbl)
		# Trophy icon
		var trophy_small := UIFactory.icon("trophy", CoTyPhuTheme.GOLD, Vector2(30, 26))
		var w_row := HBoxContainer.new()
		w_row.add_theme_constant_override("separation", 4)
		w_row.alignment = BoxContainer.ALIGNMENT_CENTER
		w_row.add_child(win_badge)
		w_row.add_child(trophy_small)
		status_cell.add_child(w_row)
	else:
		var s_style := StyleBoxFlat.new()
		s_style.bg_color = Color("F0F0F0")
		s_style.border_color = Color("D8D8D8")
		s_style.set_border_width_all(2)
		s_style.set_corner_radius_all(10)
		s_style.set_content_margin_all(8)
		var s_badge := PanelContainer.new()
		s_badge.add_theme_stylebox_override("panel", s_style)
		s_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var s_lbl := UIFactory.label(status, 18, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
		s_lbl.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
		s_lbl.add_theme_constant_override("outline_size", 0)
		s_badge.add_child(s_lbl)
		status_cell.add_child(s_badge)

	return row_panel

func _medal_label(rank: int, is_winner: bool) -> Label:
	var lbl := Label.new()
	match rank:
		1: lbl.text = "🥇" if not is_winner else "👑"
		2: lbl.text = "🥈"
		3: lbl.text = "🥉"
		_: lbl.text = str(rank)
	lbl.add_theme_font_size_override("font_size", 32 if rank <= 3 else 26)
	lbl.add_theme_color_override("font_color", CoTyPhuTheme.GOLD if rank == 1 else CoTyPhuTheme.TEXT_DARK)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(130, 72)
	return lbl

func _header_cell(text: String, width: int) -> Label:
	var lbl := UIFactory.label(text, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0.3, 0.4))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.custom_minimum_size = Vector2(width, 52)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl

func _data_cell(text, width: int, height: int, bg: Color) -> Label:
	var lbl := UIFactory.label(str(text), 24, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	lbl.custom_minimum_size = Vector2(width, height)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if bg != Color.TRANSPARENT:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.set_border_width_all(0)
		s.set_corner_radius_all(0)
		s.set_content_margin_all(0)
		lbl.add_theme_stylebox_override("normal", s)
	return lbl

func _styled_button(text: String, color: Color, min_size: Vector2) -> Button:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.35)
	style.set_border_width_all(4)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(10)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	btn.add_theme_constant_override("outline_size", 4)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", CoTyPhuTheme.button(color.lightened(0.15), 20))
	btn.add_theme_stylebox_override("pressed", CoTyPhuTheme.button(color.darkened(0.2), 20))
	return btn

func _animate_open() -> void:
	modulate.a = 0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)

func _ribbon_tail(is_left: bool) -> Control:
	var deco = preload("res://scripts/ui/GameOverDecorations.gd").new()
	deco.kind = "ribbon_left" if is_left else "ribbon_right"
	deco.size = Vector2(60, 60)
	deco.custom_minimum_size = Vector2(60, 60)
	return deco

func _draw_crown_node() -> Control:
	var deco = preload("res://scripts/ui/GameOverDecorations.gd").new()
	deco.kind = "crown"
	deco.size = Vector2(80, 50)
	deco.custom_minimum_size = Vector2(80, 50)
	return deco
