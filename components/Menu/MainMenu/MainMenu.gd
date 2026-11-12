## Main menu panel (weapon-shop style): one full-width frame with title, money
## and menu rows (MenuRow), hint bar below.
extends VBoxContainer

signal StartGame
signal UpgradeWeapon
signal UpgradeShip
signal Options

@onready var _rows: Array[Node] = $Main/Panel/Margin/VBox/Rows.get_children()


func _ready():
	for row: MenuRow in _rows:
		row.focus_entered.connect(_show_hint.bind(row))
	# Wrap around: Up on the first row goes to the last and vice versa.
	_rows[0].focus_neighbor_top = _rows[0].get_path_to(_rows[-1])
	_rows[-1].focus_neighbor_bottom = _rows[-1].get_path_to(_rows[0])
	Score.score_changed.connect(func(_score): refresh())
	Loadout.changed.connect(refresh)
	visibility_changed.connect(_on_visibility_changed)
	refresh()
	_on_visibility_changed()


func refresh():
	%Money.text = "$%d" % Score.score
	%StartGame.detail = "Level %d" % Campaign.level_number()
	%UpgradeWeapon.detail = "%s  -  power %d / %d" % [Loadout.weapon.name, Loadout.weapon_level, Loadout.weapon.max_level()]


func _show_hint(row: MenuRow):
	%Text.text = "Up/Down: select.   " + row.hint


func _on_visibility_changed():
	# Give keyboard focus back when returning from another panel.
	if visible:
		refresh()
		%StartGame.focus_quietly()


func _on_StartGame_selected():
	StartGame.emit()

func _on_UpgradeWeapon_selected():
	UpgradeWeapon.emit()

func _on_UpgradeShip_selected():
	UpgradeShip.emit()

func _on_Options_selected():
	Options.emit()
