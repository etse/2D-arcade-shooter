## The player's equipment: current weapon and its upgrade level.
## Lives as an autoload so it survives scene changes (menu <-> level).
extends Node

signal changed

var weapon: WeaponData = preload("res://components/Weapons/FocusFire/FocusFire.tres")
var weapon_level: int = 1


func is_weapon_maxed() -> bool:
	return weapon_level >= weapon.max_level()


## Price of the next weapon upgrade, or -1 if the weapon is at max level.
func next_upgrade_cost() -> int:
	return weapon.get_upgrade_cost(weapon_level)


func can_afford_upgrade() -> bool:
	return not is_weapon_maxed() and Score.score >= next_upgrade_cost()


## Pays for and applies one weapon upgrade. Returns false if maxed or too expensive.
func upgrade_weapon() -> bool:
	if is_weapon_maxed() or not Score.spend(next_upgrade_cost()):
		return false
	weapon_level += 1
	changed.emit()
	return true
