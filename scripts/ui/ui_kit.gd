class_name UiKit
extends RefCounted
## UI 主题与按钮工厂，保证字体、圆角、描边和阴影统一。


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = Painter.font()
	theme.default_font_size = 16
	theme.set_font("font", "Button", Painter.bold_font())
	theme.set_font_size("font_size", "Button", 18)
	theme.set_color("font_color", "Button", Painter.WHITE)
	theme.set_color("font_hover_color", "Button", Painter.WHITE)
	theme.set_color("font_pressed_color", "Button", Painter.CREAM)
	theme.set_color("font_focus_color", "Button", Painter.WHITE)
	return theme


static func make_button(text: String, primary := true, width := 260.0, height := 56.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, height)
	button.add_theme_font_override("font", Painter.bold_font())
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _button_style(primary, false, false))
	button.add_theme_stylebox_override("hover", _button_style(primary, true, false))
	button.add_theme_stylebox_override("pressed", _button_style(primary, false, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", _button_style(primary, false, true))
	var font_color := Painter.WHITE if primary else Painter.INK
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", Painter.CREAM if primary else Painter.BROWN)
	button.add_theme_color_override("font_focus_color", font_color)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


static func _button_style(primary: bool, hover: bool, pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var fill := Painter.CORAL if primary else Painter.CREAM
	if hover:
		fill = Painter.CORAL.lightened(0.10) if primary else Painter.MINT_LIGHT
	if pressed:
		fill = Painter.CORAL_DARK if primary else Painter.PEACH
	style.bg_color = fill
	style.border_color = Painter.INK
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.23, 0.16, 0.12, 0.20)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 4 if not pressed else 1)
	return style
