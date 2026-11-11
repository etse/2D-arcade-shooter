## A selectable menu row in the weapon-shop style: [icon] Title / detail  TAG.
## Focus-based, so Godot's focus navigation (arrow keys) moves between rows.
## Enter / click emits `selected` after a short flash.
## Hover follows real mouse movement only (not `mouse_entered`), so a pointer
## resting where a panel appears doesn't steal keyboard focus.
@tool
class_name MenuRow
extends PanelContainer

signal selected

## Delay between accept and `selected`, so the flash + sound register before a
## panel switch or scene change.
const ACCEPT_DELAY := 0.15

@export var title: String = "":
	set(value):
		title = value
		_update()
@export var detail: String = "":
	set(value):
		detail = value
		_update()
## Short text on the right, e.g. "ON", "EQUIPPED".
@export var tag: String = "":
	set(value):
		tag = value
		_update()
@export var tag_color: Color = UIStyle.GREEN:
	set(value):
		tag_color = value
		_update()
@export var icon: Texture2D:
	set(value):
		icon = value
		_update()
## Greyed out; still focusable (so it can explain itself) but never `selected`.
@export var disabled: bool = false:
	set(value):
		disabled = value
		_update()
## Shown in the owning menu's hint bar while the row is focused.
@export var hint: String = ""
@export var title_size: int = 36:
	set(value):
		title_size = value
		_update()

var _quiet_focus := false
var _busy := false


func _ready():
	focus_entered.connect(_on_focus_changed.bind(true))
	focus_exited.connect(_on_focus_changed.bind(false))
	_update()


## Focus without the move sound (e.g. when a panel opens).
func focus_quietly():
	_quiet_focus = true
	grab_focus()
	_quiet_focus = false


## Same as pressing Enter on the row.
func press():
	if disabled or _busy:
		return
	_busy = true
	$AcceptSound.play()
	add_theme_stylebox_override("panel", UIStyle.ROW)
	await get_tree().create_timer(ACCEPT_DELAY / 2.0).timeout
	_update()
	await get_tree().create_timer(ACCEPT_DELAY / 2.0).timeout
	_busy = false
	selected.emit()


func _gui_input(event: InputEvent):
	if event is InputEventMouseMotion and not has_focus():
		grab_focus()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("mouse_click"):
		accept_event()
		press()


func _on_focus_changed(_focused: bool):
	if has_focus() and not _quiet_focus and not Engine.is_editor_hint():
		$MoveSound.play()
	_update()


func _update():
	if not is_node_ready():
		return
	var lit := has_focus()
	add_theme_stylebox_override("panel", UIStyle.ROW_SELECTED if lit else UIStyle.ROW)
	var title_label: Label = $HBox/Text/Title
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", title_size)
	var color := UIStyle.GOLD if lit else Color.WHITE
	title_label.add_theme_color_override("font_color", color)
	$HBox/Text/Detail.text = detail
	$HBox/Text/Detail.visible = not detail.is_empty()
	$HBox/Tag.text = tag
	$HBox/Tag.add_theme_color_override("font_color", tag_color)
	$HBox/Icon.texture = icon
	$HBox/Icon.visible = icon != null
	modulate = Color(1, 1, 1, 0.45) if disabled else Color.WHITE
