## Weapon shop panel shown from the main menu ("Upgrade weapon").
## Tyrian-style: a list of weapons (Loadout.WEAPONS) + DONE on the right, and a
## live preview of the highlighted weapon with a 10-step power bar on the left.
##   Up/Down       move the cursor (the preview follows it)
##   Enter         buy the highlighted weapon (trading in the equipped one for
##                 its full value, see Loadout) / DONE goes back
##   Left/Right    downgrade (full refund) / upgrade the equipped weapon
##   Esc           back
## Mouse: hover a row to highlight it, click to choose; click < > for power.
extends VBoxContainer

signal back

const TITLE_FONT := UIStyle.BOLD_FONT
const TEXT_FONT := UIStyle.TEXT_FONT
const COLOR_DIM := UIStyle.DIM
const COLOR_TEXT := UIStyle.TEXT
const COLOR_GOLD := UIStyle.GOLD
const COLOR_EMPTY := UIStyle.EMPTY
const COLOR_UP := UIStyle.GREEN
const COLOR_ERROR := UIStyle.RED
const COLOR_OK := UIStyle.GREEN
const COLOR_EQUIPPED := UIStyle.GREEN
const COLOR_DISABLED := UIStyle.DISABLED
const ROW_ICON_SIZE := Vector2(84, 84)
const POWER_SEGMENT_SIZE := Vector2(30, 46)
const METER_SEGMENTS := 24
const METER_SIZE := Vector2(34, 0)
## Meter colours from bottom (weak) to top (strong).
const METER_LOW := Color(0.85, 0.1, 0.0)
const METER_HIGH := Color(1, 0.9, 0.2)
const STAT_FONT_SIZE := 24

@onready var _preview = $Main/Showcase/Margin/VBox/View/Window/Preview
@onready var _meter: VBoxContainer = $Main/Showcase/Margin/VBox/View/Firepower/Meter
@onready var _dps: Label = $Main/Showcase/Margin/VBox/View/Firepower/Value
@onready var _down: Label = $Main/Showcase/Margin/VBox/Power/Down
@onready var _up: Label = $Main/Showcase/Margin/VBox/Power/Up
@onready var _segments: HBoxContainer = $Main/Showcase/Margin/VBox/Power/Segments
@onready var _power_info: Label = $Main/Showcase/Margin/VBox/PowerInfo
@onready var _money: Label = $Main/Store/Margin/VBox/MoneyRow/Money
@onready var _list: VBoxContainer = $Main/Store/Margin/VBox/List
@onready var _description: Label = $Main/Store/Margin/VBox/Description
@onready var _stats: GridContainer = $Main/Store/Margin/VBox/Stats
@onready var _hint: Label = $Hint/Text

## Row index under the cursor; rows are Loadout.WEAPONS followed by DONE.
var cursor := 0
var _rows: Array[PanelContainer] = []
var _row_style: StyleBox = UIStyle.ROW
var _row_style_selected: StyleBox = UIStyle.ROW_SELECTED
## DPS that fills the meter: the strongest weapon at max power, so the meter
## always compares weapons against the best one in the shop.
var _max_dps := 1.0
## Shown instead of the hint until the cursor moves or something else happens.
var _status := ""
var _status_color := COLOR_TEXT
## False while fading out after DONE, so input isn't handled twice.
var _active := false


func _ready():
	_build_rows()
	_build_meter()
	for i in Loadout.WEAPONS[0].max_level():
		var segment := ColorRect.new()
		segment.custom_minimum_size = POWER_SEGMENT_SIZE
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_segments.add_child(segment)
	for weapon in Loadout.WEAPONS:
		_max_dps = maxf(_max_dps, weapon.get_dps(weapon.max_level()))
	_down.gui_input.connect(_on_arrow_input.bind(-1))
	_up.gui_input.connect(_on_arrow_input.bind(1))
	Score.score_changed.connect(func(_score): refresh())
	Loadout.changed.connect(refresh)
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


# --- building ---------------------------------------------------------------------

func _build_rows():
	for weapon in Loadout.WEAPONS:
		_add_row(weapon.icon, weapon.name)
	_add_row(null, "DONE")


## One list row: [icon] Name / detail line. Built in code; refresh() fills it.
func _add_row(icon: Texture2D, title: String):
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _row_style)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	row.add_child(hbox)

	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.custom_minimum_size = ROW_ICON_SIZE if icon else Vector2(ROW_ICON_SIZE.x, 0)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = icon
	hbox.add_child(icon_rect)

	var text := VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text)
	var name_label := _make_label(title, TITLE_FONT, 36, Color.WHITE)
	name_label.name = "Name"
	text.add_child(name_label)
	var detail := _make_label("", TEXT_FONT, 26, COLOR_TEXT)
	detail.name = "Detail"
	detail.visible = icon != null
	text.add_child(detail)

	var tag := _make_label("", TITLE_FONT, 26, COLOR_EQUIPPED)
	tag.name = "Tag"
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(tag)

	for child in [hbox, icon_rect, text, name_label, detail, tag]:
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var index := _rows.size()
	row.gui_input.connect(_on_row_input.bind(index))
	_list.add_child(row)
	_rows.append(row)


## Vertical "firepower" meter, top segment first.
func _build_meter():
	for i in METER_SEGMENTS:
		var segment := ColorRect.new()
		segment.custom_minimum_size = METER_SIZE
		segment.size_flags_vertical = Control.SIZE_EXPAND_FILL
		segment.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_meter.add_child(segment)


func _make_label(text: String, font: Font, size: int, color: Color) -> Label:
	return UIStyle.make_label(text, font, size, color)


# --- state ------------------------------------------------------------------------

func _done_index() -> int:
	return Loadout.WEAPONS.size()


## The weapon under the cursor, or the equipped one when DONE is highlighted.
func highlighted_weapon() -> WeaponData:
	return Loadout.WEAPONS[cursor] if cursor < _done_index() else Loadout.weapon


## Level shown for `weapon`: the owned level, or 1 for weapons not owned.
func _shown_level(weapon: WeaponData) -> int:
	return Loadout.weapon_level if weapon == Loadout.weapon else 1


func refresh():
	var weapon := highlighted_weapon()
	var equipped := weapon == Loadout.weapon
	var level := _shown_level(weapon)

	_money.text = "$%d" % Score.score
	_refresh_rows()
	_preview.show_weapon(weapon, level)
	_refresh_power(weapon, level, equipped)
	_refresh_meter(weapon.get_dps(level))
	_description.text = weapon.description
	if equipped and not Loadout.is_weapon_maxed():
		_fill_stats(weapon, level, level + 1)
	else:
		_fill_stats(weapon, level, level)
	_refresh_hint(weapon, equipped)


func _refresh_rows():
	for i in _rows.size():
		var row := _rows[i]
		var selected := i == cursor
		row.add_theme_stylebox_override("panel", _row_style_selected if selected else _row_style)
		var name_label: Label = row.find_child("Name", true, false)
		name_label.add_theme_color_override("font_color", COLOR_GOLD if selected else Color.WHITE)
		if i == _done_index():
			continue
		var weapon: WeaponData = Loadout.WEAPONS[i]
		var detail: Label = row.find_child("Detail", true, false)
		var tag: Label = row.find_child("Tag", true, false)
		if weapon == Loadout.weapon:
			detail.text = "Power %d / %d   -   worth $%d" % [Loadout.weapon_level, weapon.max_level(), Loadout.trade_in_value()]
			tag.text = "EQUIPPED"
		else:
			detail.text = "Cost: %d" % weapon.price
			tag.text = ""


func _refresh_power(weapon: WeaponData, level: int, equipped: bool):
	var segments := _segments.get_children()
	for i in segments.size():
		var segment: ColorRect = segments[i]
		segment.visible = i < weapon.max_level()
		if i < level:
			segment.color = COLOR_GOLD if equipped else COLOR_GOLD.darkened(0.55)
		else:
			segment.color = COLOR_EMPTY
	var can_down := equipped and Loadout.can_downgrade()
	var can_up := equipped and not Loadout.is_weapon_maxed()
	_down.add_theme_color_override("font_color", COLOR_GOLD if can_down else COLOR_DISABLED)
	_up.add_theme_color_override("font_color", COLOR_GOLD if can_up else COLOR_DISABLED)
	if not equipped:
		_power_info.text = "Not owned  -  preview at power 1"
		_power_info.add_theme_color_override("font_color", COLOR_DIM)
	elif Loadout.is_weapon_maxed():
		_power_info.text = "POWER %d / %d  -  MAX" % [level, weapon.max_level()]
		_power_info.add_theme_color_override("font_color", COLOR_GOLD)
	else:
		_power_info.text = "POWER %d / %d" % [level, weapon.max_level()]
		_power_info.add_theme_color_override("font_color", Color.WHITE)


func _refresh_meter(dps: float):
	var lit := ceili(clampf(dps / _max_dps, 0.0, 1.0) * METER_SEGMENTS)
	var segments := _meter.get_children()
	for i in METER_SEGMENTS:
		var from_bottom := METER_SEGMENTS - 1 - i
		var segment: ColorRect = segments[i]
		var color := METER_LOW.lerp(METER_HIGH, float(from_bottom) / (METER_SEGMENTS - 1))
		segment.color = color if from_bottom < lit else Color(color, 0.12)
	_dps.text = "%d" % roundi(dps)


func _refresh_hint(weapon: WeaponData, equipped: bool):
	if not _status.is_empty():
		_hint.text = _status
		_hint.add_theme_color_override("font_color", _status_color)
		return
	_hint.add_theme_color_override("font_color", COLOR_TEXT)
	if cursor == _done_index():
		_hint.text = "Up/Down: select a weapon.   Enter: back to the main menu."
	elif equipped:
		var parts: Array[String] = []
		if not Loadout.is_weapon_maxed():
			parts.append("Right: upgrade ($%d)" % Loadout.next_upgrade_cost())
		if Loadout.can_downgrade():
			parts.append("Left: downgrade (+$%d back)" % Loadout.downgrade_refund())
		if parts.is_empty():
			parts.append("Left/Right: change power level")
		_hint.text = "Up/Down: select a weapon.   " + "   ".join(parts) + "."
	else:
		var cost := Loadout.buy_cost(weapon)
		var price := "$%d" % cost if cost >= 0 else "get $%d back" % -cost
		_hint.text = "Enter: buy for %s  (your %s is traded in for $%d)." % [price, Loadout.weapon.name, Loadout.trade_in_value()]


## Stats at `level`, with the value at `next` shown as an upgrade when it differs.
func _fill_stats(weapon: WeaponData, level: int, next: int):
	for child in _stats.get_children():
		_stats.remove_child(child)
		child.queue_free()
	var rows := [["Damage", weapon.get_damage(level), weapon.get_damage(next), ""]]
	if weapon.fire_pattern == WeaponData.FirePattern.SPREAD:
		# A minigun's volleys get longer as they get bigger, so volleys/s can
		# drop on upgrade; bullets/s is the number that actually rises.
		rows.append(["Bullets/s", _bullets_per_second(weapon, level), _bullets_per_second(weapon, next), "%.1f"])
		rows.append(["Spread", weapon.get_spread_angle(level), weapon.get_spread_angle(next), "%d deg"])
	else:
		rows.append(["Bullets", weapon.get_bullet_count(level), weapon.get_bullet_count(next), "%d"])
		rows.append(["Fire rate", 1.0 / weapon.get_fire_interval(level), 1.0 / weapon.get_fire_interval(next), "%.1f/s"])
	for row in rows:
		var current := _format_stat(row[3], row[1])
		var upgraded := _format_stat(row[3], row[2])
		_stats.add_child(_make_label(row[0], TEXT_FONT, STAT_FONT_SIZE, COLOR_DIM))
		_stats.add_child(_make_label(current, TEXT_FONT, STAT_FONT_SIZE, Color.WHITE))
		var arrow := "> " + upgraded if upgraded != current else ""
		_stats.add_child(_make_label(arrow, TEXT_FONT, STAT_FONT_SIZE, COLOR_UP))


func _bullets_per_second(weapon: WeaponData, level: int) -> float:
	return weapon.get_bullet_count(level) / weapon.get_fire_interval(level)


## `format` is a printf-style string, or "" for a plain number (2.5, 1.75, 3).
func _format_stat(format: String, value: float) -> String:
	return String.num(value, 2) if format.is_empty() else format % value


func _show_status(text: String, color: Color):
	_status = text
	_status_color = color
	refresh()


# --- actions ----------------------------------------------------------------------

func _move_cursor_to(index: int):
	if index == cursor:
		return
	cursor = clampi(index, 0, _done_index())
	_status = ""
	$MoveSound.play()
	refresh()


func move_cursor(step: int):
	_move_cursor_to(wrapi(cursor + step, 0, _done_index() + 1))


## Enter / click on the highlighted row.
func accept():
	if cursor == _done_index():
		$AcceptSound.play()
		_active = false
		back.emit()
		return
	var weapon: WeaponData = Loadout.WEAPONS[cursor]
	if weapon == Loadout.weapon:
		_show_status("%s is already equipped. Left/Right changes its power." % weapon.name, COLOR_TEXT)
		return
	var cost := Loadout.buy_cost(weapon)
	if Loadout.buy_weapon(weapon):
		$AcceptSound.play()
		_show_status("%s equipped!" % weapon.name, COLOR_OK)
	else:
		_show_status("Not enough money - need $%d more." % (cost - Score.score), COLOR_ERROR)


## Left/Right: change the equipped weapon's power level by `step` (-1 or +1).
func change_power(step: int):
	if highlighted_weapon() != Loadout.weapon:
		_show_status("Buy %s first (Enter) to change its power." % highlighted_weapon().name, COLOR_ERROR)
		return
	if step > 0:
		var cost := Loadout.next_upgrade_cost()
		if Loadout.is_weapon_maxed():
			_show_status("Already at max power.", COLOR_TEXT)
		elif Loadout.upgrade_weapon():
			$MoveSound.play()
			_show_status("Upgraded to power %d for $%d." % [Loadout.weapon_level, cost], COLOR_OK)
		else:
			_show_status("Not enough money - need $%d more." % (cost - Score.score), COLOR_ERROR)
	else:
		var refund := Loadout.downgrade_refund()
		if Loadout.downgrade_weapon():
			$MoveSound.play()
			_show_status("Downgraded to power %d, got $%d back." % [Loadout.weapon_level, refund], COLOR_OK)
		else:
			_show_status("Already at the lowest power.", COLOR_TEXT)


# --- input ------------------------------------------------------------------------

func _input(event: InputEvent):
	if not _active:
		return
	if event.is_action_pressed("ui_up", true):
		move_cursor(-1)
	elif event.is_action_pressed("ui_down", true):
		move_cursor(1)
	elif event.is_action_pressed("ui_left", true):
		change_power(-1)
	elif event.is_action_pressed("ui_right", true):
		change_power(1)
	elif event.is_action_pressed("ui_accept"):
		accept()
	elif event.is_action_pressed("ui_cancel"):
		_move_cursor_to(_done_index())
		accept()
	else:
		return
	get_viewport().set_input_as_handled()


## Hover follows real mouse movement only (not `mouse_entered`), so a pointer
## resting where the panel appears doesn't steal the keyboard cursor.
func _on_row_input(event: InputEvent, index: int):
	if event is InputEventMouseMotion:
		_move_cursor_to(index)
	elif event.is_action_pressed("mouse_click"):
		_move_cursor_to(index)
		accept()


func _on_arrow_input(event: InputEvent, step: int):
	if event.is_action_pressed("mouse_click"):
		if cursor == _done_index():
			_move_cursor_to(Loadout.WEAPONS.find(Loadout.weapon))
		change_power(step)


func _on_visibility_changed():
	_active = visible
	if not visible:
		return
	# Nothing in the shop uses GUI focus; keep the main menu's from reacting.
	get_viewport().gui_release_focus()
	cursor = Loadout.WEAPONS.find(Loadout.weapon)
	_status = ""
	refresh()
