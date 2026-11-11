## Weapon shop panel shown from the main menu ("Upgrade weapon").
## Shows the equipped weapon (see the Loadout autoload) and lets the player
## spend money (Score) on upgrading it, one level at a time.
extends VBoxContainer

signal back

const STAT_FONT := preload("res://assets/fonts/8bitOperatorPlus-Regular.ttf")
const STAT_FONT_SIZE := 26
const COLOR_DIM := Color(0.65, 0.65, 0.65)
const COLOR_UP := Color(0.24, 0.94, 0.27)
const COLOR_ERROR := Color(1, 0.35, 0.3)
const COLOR_OK := Color(0.24, 0.94, 0.27)

@onready var _money: Label = $Money
@onready var _icon: TextureRect = $Item/Margin/Row/Icon
@onready var _name: Label = $Item/Margin/Row/Info/Name
@onready var _description: Label = $Item/Margin/Row/Info/Description
@onready var _level: Label = $Item/Margin/Row/Info/Level
@onready var _stats: GridContainer = $Item/Margin/Row/Info/Stats
@onready var _upgrade: Label = $Upgrade
@onready var _status: Label = $Status


func _ready():
	Score.score_changed.connect(func(_score): refresh())
	Loadout.changed.connect(refresh)
	visibility_changed.connect(_on_visibility_changed)
	refresh()


func refresh():
	var weapon := Loadout.weapon
	var level := Loadout.weapon_level
	var maxed := Loadout.is_weapon_maxed()

	_money.text = "Money: $%d" % Score.score
	_icon.texture = weapon.icon
	_name.text = weapon.name
	_description.text = weapon.description
	_level.text = "Level %d / %d" % [level, weapon.max_level()]

	_fill_stats(weapon, level, maxed)

	_upgrade.visible = not maxed
	if not maxed:
		_upgrade.text = "Upgrade to level %d  -  $%d" % [level + 1, Loadout.next_upgrade_cost()]


func _fill_stats(weapon: WeaponData, level: int, maxed: bool):
	for child in _stats.get_children():
		_stats.remove_child(child)
		child.queue_free()
	var next := level if maxed else level + 1
	var rows := [
		["Damage", weapon.get_damage(level), weapon.get_damage(next), "%s"],
		["Bullets", weapon.get_bullet_count(level), weapon.get_bullet_count(next), "%s"],
		["Fire rate", 1.0 / weapon.get_fire_interval(level), 1.0 / weapon.get_fire_interval(next), "%.1f/s"],
	]
	for row in rows:
		var current: String = row[3] % row[1]
		var upgraded: String = row[3] % row[2]
		_add_stat_cell(row[0], COLOR_DIM)
		_add_stat_cell(current, Color.WHITE)
		if maxed:
			_add_stat_cell("", Color.WHITE)
		elif upgraded != current:
			_add_stat_cell("->  " + upgraded, COLOR_UP)
		else:
			_add_stat_cell("", Color.WHITE)


func _add_stat_cell(text: String, color: Color):
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 200
	label.add_theme_font_override("font", STAT_FONT)
	label.add_theme_font_size_override("font_size", STAT_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	_stats.add_child(label)


func _show_status(text: String, color: Color):
	_status.text = text
	_status.add_theme_color_override("font_color", color)


func _on_visibility_changed():
	if not visible:
		return
	_status.text = ""
	refresh()
	if _upgrade.visible:
		_upgrade.grab_focus()
	else:
		$Back.grab_focus()


func _on_Upgrade_selected():
	var cost := Loadout.next_upgrade_cost()
	if Loadout.upgrade_weapon():
		_show_status("Upgraded to level %d!" % Loadout.weapon_level, COLOR_OK)
		if Loadout.is_weapon_maxed():
			_show_status("Max level reached!", COLOR_OK)
			$Back.grab_focus()
	elif Loadout.is_weapon_maxed():
		_show_status("Already at max level", COLOR_ERROR)
	else:
		_show_status("Not enough money - need $%d more" % (cost - Score.score), COLOR_ERROR)


func _on_Back_selected():
	back.emit()
