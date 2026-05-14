extends RefCounted
class_name CoTyPhuTheme

const BG_BLUE := Color("#0754A8")
const DEEP_BLUE := Color("#06336F")
const PANEL_BLUE := Color("#0876D9")
const PANEL_BLUE_DARK := Color("#0350A8")
const CREAM := Color("#FFF1D4")
const CREAM_DARK := Color("#F4DCA6")
const GOLD := Color("#FFC832")
const GREEN := Color("#48B82E")
const BLUE := Color("#168BE3")
const RED := Color("#E94C3D")
const ORANGE := Color("#F6A623")
const PURPLE := Color("#8E4FD6")
const TEXT_DARK := Color("#1E1B18")
const TEXT_BLUE := Color("#0056B8")
const TEXT_GREEN := Color("#0C7724")

static func panel(bg: Color, border: Color, radius: int = 18, border_width: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style

static func button(color: Color, radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.35)
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(8)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style

static func button_pressed(color: Color, radius: int = 16) -> StyleBoxFlat:
	var style := button(color.darkened(0.22), radius)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	return style

static func player_color(index: int) -> Color:
	var colors := [Color("#2D8CFF"), RED, Color("#39B54A"), Color("#F4C542")]
	return colors[index % colors.size()]

static func group_color(group: String) -> Color:
	match group:
		"brown":
			return Color("#9B5A2E")
		"light_blue":
			return Color("#64C7FF")
		"pink":
			return Color("#E970B8")
		"orange":
			return ORANGE
		"red":
			return RED
		"yellow":
			return GOLD
		"green":
			return GREEN
		"blue":
			return BLUE
	return Color("#D8D0B8")
