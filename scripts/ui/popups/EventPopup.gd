extends Control
class_name EventPopup

const CoTyPhuTheme = preload("res://scripts/ui/CoTyPhuTheme.gd")
const UIFactory = preload("res://scripts/ui/UIFactory.gd")

signal event_confirmed

var title_label: Label
var event_title: Label
var icon_art: Control
var description_label: Label
var amount_label: Label
var deck_count_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()
	UIFactory.make_responsive(self)

func _build() -> void:
	add_child(UIFactory.dim_overlay())

	# Outer panel — warm golden orange
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("FFE8A0")
	panel_style.border_color = Color("F0A030")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(18)
	panel_style.set_content_margin_all(12)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 14
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(425, 180)
	panel.size = Vector2(430, 360)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 5)
	panel.add_child(root)

	# Title banner (blue with stars)
	var title_style := StyleBoxFlat.new()
	title_style.bg_color = Color("2575D0")
	title_style.border_color = Color("57C6FF")
	title_style.set_border_width_all(2)
	title_style.set_corner_radius_all(12)
	title_style.set_content_margin_all(6)
	var title_panel := PanelContainer.new()
	title_panel.add_theme_stylebox_override("panel", title_style)
	root.add_child(title_panel)

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 6)
	title_panel.add_child(title_row)

	var star_left := UIFactory.label("★", 20, CoTyPhuTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var star_right := UIFactory.label("★", 20, CoTyPhuTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title_label = UIFactory.label("Thẻ sự kiện", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0.1, 0.4, 0.6))
	title_label.add_theme_constant_override("outline_size", 3)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	title_row.add_child(star_left)
	title_row.add_child(title_label)
	title_row.add_child(star_right)

	# Event name (big, bold, colored)
	event_title = UIFactory.label("Sinh nhật vui vẻ!", 30, CoTyPhuTheme.RED, HORIZONTAL_ALIGNMENT_CENTER)
	event_title.add_theme_color_override("font_outline_color", Color(0.5, 0.1, 0.0, 0.5))
	event_title.add_theme_constant_override("outline_size", 4)
	event_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_title.custom_minimum_size = Vector2(0, 38)
	root.add_child(event_title)

	# Large illustration area with confetti & balloons backdrop
	var icon_holder := Control.new()
	icon_holder.custom_minimum_size = Vector2(0, 70)
	icon_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(icon_holder)

	var confetti = preload("res://scripts/ui/EventConfetti.gd").new()
	confetti.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_holder.add_child(confetti)

	icon_art = UIFactory.icon("gift", CoTyPhuTheme.BLUE, Vector2(96, 78))
	icon_art.set_anchors_preset(Control.PRESET_CENTER)
	icon_art.position = Vector2(-48, -39)
	icon_holder.add_child(icon_art)

	# Description
	description_label = UIFactory.label("", 18, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(0, 38)
	root.add_child(description_label)

	# Amount label
	amount_label = UIFactory.label("", 24, CoTyPhuTheme.TEXT_GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	amount_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.25))
	amount_label.add_theme_constant_override("outline_size", 2)
	amount_label.custom_minimum_size = Vector2(0, 26)
	root.add_child(amount_label)

	# Event type badge row
	var badge_row := HBoxContainer.new()
	badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(badge_row)

	var event_badge_style := StyleBoxFlat.new()
	event_badge_style.bg_color = Color("FFFAEC")
	event_badge_style.border_color = CoTyPhuTheme.GOLD
	event_badge_style.set_border_width_all(2)
	event_badge_style.set_corner_radius_all(10)
	event_badge_style.set_content_margin_all(5)
	var event_badge := PanelContainer.new()
	event_badge.add_theme_stylebox_override("panel", event_badge_style)
	badge_row.add_child(event_badge)
	var badge_lbl := UIFactory.label("🎁  Sự kiện", 14, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	badge_lbl.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	badge_lbl.add_theme_constant_override("outline_size", 0)
	event_badge.add_child(badge_lbl)

	deck_count_label = UIFactory.label("", 14, CoTyPhuTheme.TEXT_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	deck_count_label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	deck_count_label.add_theme_constant_override("outline_size", 0)
	root.add_child(deck_count_label)

	# OK button
	var ok_style := StyleBoxFlat.new()
	ok_style.bg_color = CoTyPhuTheme.ORANGE
	ok_style.border_color = CoTyPhuTheme.GOLD
	ok_style.set_border_width_all(3)
	ok_style.set_corner_radius_all(14)
	ok_style.set_content_margin_all(5)
	ok_style.shadow_color = Color(0, 0, 0, 0.35)
	ok_style.shadow_size = 4
	ok_style.shadow_offset = Vector2(0, 2)

	var ok := Button.new()
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(150, 42)
	ok.add_theme_font_size_override("font_size", 21)
	ok.add_theme_color_override("font_color", Color.WHITE)
	ok.add_theme_color_override("font_outline_color", Color(0.4, 0.15, 0.0, 0.6))
	ok.add_theme_constant_override("outline_size", 3)
	ok.add_theme_stylebox_override("normal", ok_style)
	ok.add_theme_stylebox_override("hover", CoTyPhuTheme.button(CoTyPhuTheme.ORANGE.lightened(0.15), 20))
	ok.add_theme_stylebox_override("pressed", CoTyPhuTheme.button(CoTyPhuTheme.ORANGE.darkened(0.15), 20))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func(): visible = false; emit_signal("event_confirmed"))
	ok.mouse_entered.connect(func(): ok.scale = Vector2(1.05, 1.05))
	ok.mouse_exited.connect(func(): ok.scale = Vector2.ONE)
	root.add_child(ok)

func show_event(title: String, description: String, amount: int, icon_id: String = "gift") -> void:
	visible = true
	title_label.text = "Thẻ sự kiện"
	event_title.text = title
	description_label.text = description
	icon_art.call("configure", _icon_for(icon_id), CoTyPhuTheme.BLUE, "")
	deck_count_label.text = ""
	if amount != 0:
		var sign := "+" if amount > 0 else ""
		amount_label.text = "Mỗi người chơi trả bạn $" + str(abs(amount)) if amount > 0 else "Trả $" + str(abs(amount))
		amount_label.add_theme_color_override("font_color", CoTyPhuTheme.TEXT_GREEN if amount > 0 else CoTyPhuTheme.RED)
	else:
		amount_label.text = ""
	modulate.a = 0
	scale = Vector2(0.88, 0.88)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.24)


func show_deck_card(deck_title: String, card: Dictionary, deck_color: Color, amount: int, deck_counts := {}) -> void:
	visible = true
	var is_chance := deck_title.find("CƠ HỘI") >= 0
	var remaining_key := "chance" if is_chance else "community"
	var total_key := "chance_total" if is_chance else "community_total"
	var remaining := int(deck_counts.get(remaining_key, 0))
	var total := int(deck_counts.get(total_key, 40))

	title_label.text = "BỘ THẺ " + deck_title
	event_title.text = str(card.get("title", deck_title))
	description_label.text = str(card.get("text", ""))
	icon_art.call("configure", _icon_for(str(card.get("icon", "gift"))), deck_color, "")
	deck_count_label.text = "Còn lại: " + str(remaining) + "/" + str(total) + " thẻ"

	if amount != 0:
		var sign := "+" if amount > 0 else "-"
		amount_label.text = sign + "$" + str(abs(amount))
		amount_label.add_theme_color_override("font_color", CoTyPhuTheme.TEXT_GREEN if amount > 0 else CoTyPhuTheme.RED)
	else:
		amount_label.text = ""

	event_title.add_theme_color_override("font_color", deck_color)
	event_title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.0, 0.65))
	modulate.a = 0
	scale = Vector2(0.88, 0.88)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.24)

func _icon_for(icon_id: String) -> String:
	match icon_id:
		"money": return "money"
		"jail": return "jail"
		"tax": return "money"
		"travel": return "city"
		"go": return "city"
		"arrow": return "hourglass"
		"car": return "city"
		"chance": return "dice"
		"wind": return "hourglass"
		"shield": return "trophy"
		"heart": return "gift"
		"storm": return "hourglass"
		"mountain": return "pagoda"
		"palm": return "palm"
		"bridge": return "bridge"
		"dice": return "dice"
		"token": return "token"
		"home": return "home"
		"trophy": return "trophy"
	return "gift"
