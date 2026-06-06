extends RefCounted
class_name CoTyPhuPalette

# ════════════════════════════════════════════════════════════════════
# Bảng màu + factory style dùng chung cho giao diện E.
# Lấy cảm hứng phối màu "Cờ Tỷ Phú" từ nhánh D, viết mới cho E.
# CHỈ là dữ liệu trình bày + tạo StyleBox — KHÔNG chứa logic game.
# ════════════════════════════════════════════════════════════════════

# --- Palette nền / panel ---
const BG_BLUE        := Color("#0754A8")
const DEEP_BLUE      := Color("#06336F")
const PANEL_BLUE     := Color("#0876D9")
const PANEL_BLUE_DK  := Color("#0350A8")
const CREAM          := Color("#FFF1D4")
const CREAM_DARK     := Color("#F4DCA6")
const GOLD           := Color("#FFC832")
const GREEN          := Color("#48B82E")
const BLUE           := Color("#168BE3")
const RED            := Color("#E94C3D")
const ORANGE         := Color("#F6A623")
const PURPLE         := Color("#8E4FD6")
const TEXT_DARK      := Color("#1E1B18")
const TEXT_LIGHT     := Color("#FFF7E6")

# --- Màu nhóm đất theo color_name mà E đang dùng ("Red"/"Green"/"Yellow"/"Blue") ---
static func group_color(color_name: String) -> Color:
	match color_name:
		"Red":    return RED
		"Green":  return GREEN
		"Yellow": return GOLD
		"Blue":   return BLUE
	return Color("#D8D0B8")

# --- Màu người chơi: giữ ĐÚNG thứ tự theo player_id của E để không đổi ý nghĩa ---
static func player_color(index: int) -> Color:
	var colors := [Color("#2D8CFF"), RED, GREEN, Color("#F4C542")]
	return colors[index % colors.size()]

# --- Factory StyleBox cho panel ---
static func panel_style(bg: Color, border: Color, radius := 16, border_width := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(12)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	return s

# --- Factory StyleBox cho nút ---
static func button_style(color: Color, radius := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = color.lightened(0.35)
	s.set_border_width_all(3)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(8)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 5
	s.shadow_offset = Vector2(0, 3)
	return s

static func button_style_pressed(color: Color, radius := 14) -> StyleBoxFlat:
	var s := button_style(color.darkened(0.22), radius)
	s.shadow_size = 2
	s.shadow_offset = Vector2(0, 1)
	return s

# --- Helper: áp style nút (normal/hover/pressed) cho một Button có sẵn ---
# Chỉ chỉnh hình ảnh; KHÔNG đổi text, signal hay hành vi của nút.
static func style_button(btn: Button, color: Color, font_size := 0) -> void:
	if btn == null:
		return
	btn.add_theme_stylebox_override("normal", button_style(color))
	btn.add_theme_stylebox_override("hover", button_style(color.lightened(0.12)))
	btn.add_theme_stylebox_override("pressed", button_style_pressed(color))
	btn.add_theme_stylebox_override("disabled", button_style(Color("#888888")))
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	btn.add_theme_constant_override("outline_size", 3)
	if font_size > 0:
		btn.add_theme_font_size_override("font_size", font_size)

# --- Việt hóa TÊN HIỂN THỊ của ô (chỉ ở tầng vẽ, KHÔNG đổi dữ liệu cell_name) ---
# Logic game so khớp bằng cell_type, không dùng chuỗi tên, nên map này an toàn.
static func display_name(cell_name: String) -> String:
	match cell_name:
		"GO":          return "Xuất phát"
		"Visit Jail":  return "Thăm tù"
		"Go To Jail":  return "Vào tù"
		"Chance":      return "Cơ hội"
		"Chest":       return "Khí vận"
		"Tax":         return "Thuế"
		"Parking":     return "Bãi đỗ xe"
	return cell_name
