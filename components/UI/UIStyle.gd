## Shared look of all menus and the HUD (the "weapon shop" style): dark
## translucent panels with gold borders, gold Arcade titles, 8-bit fonts.
## Use these instead of hard-coding colours/fonts so every screen stays alike.
class_name UIStyle
extends RefCounted

const GOLD := Color(1, 0.75, 0)
const TEXT := Color(0.85, 0.8, 0.65)
const DIM := Color(0.6, 0.6, 0.68)
const GREEN := Color(0.24, 0.94, 0.27)
const RED := Color(1, 0.35, 0.3)
const EMPTY := Color(1, 1, 1, 0.12)
const DISABLED := Color(1, 1, 1, 0.2)

const TITLE_FONT := preload("res://assets/fonts/Arcade.ttf")
const BOLD_FONT := preload("res://assets/fonts/8bitOperatorPlus-Bold.ttf")
const TEXT_FONT := preload("res://assets/fonts/8bitOperatorPlus-Regular.ttf")

## Big gold-bordered panel.
const FRAME := preload("res://components/UI/styles/Frame.tres")
## Black "screen" inside a frame (e.g. the weapon preview).
const WINDOW := preload("res://components/UI/styles/Window.tres")
## Full-width hint/status bar under a menu.
const HINT := preload("res://components/UI/styles/Hint.tres")
## Selectable list row, normal / highlighted.
const ROW := preload("res://components/UI/styles/Row.tres")
const ROW_SELECTED := preload("res://components/UI/styles/RowSelected.tres")
## Small in-game HUD panel.
const HUD := preload("res://components/UI/styles/Hud.tres")


static func make_label(text: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
