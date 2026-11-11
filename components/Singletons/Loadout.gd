## The player's equipment: current weapon and its upgrade level.
## Lives as an autoload so it survives scene changes (menu <-> level).
## The player owns exactly one weapon; buying another trades the current one
## in for its full value (price + all upgrades paid), so no money is lost.
extends Node

signal changed

## Every weapon sold in the shop, in display order.
const WEAPONS: Array[WeaponData] = [
	preload("res://components/Weapons/PulseFire/PulseFire.tres"),
	preload("res://components/Weapons/SpreadFire/SpreadFire.tres"),
]

var weapon: WeaponData = WEAPONS[0]
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


func can_downgrade() -> bool:
	return weapon_level > 1


## Refund for going down one level: exactly what that upgrade cost.
func downgrade_refund() -> int:
	return weapon.get_upgrade_cost(weapon_level - 1) if can_downgrade() else 0


## Removes one weapon level and refunds its full price. Returns false at level 1.
func downgrade_weapon() -> bool:
	if not can_downgrade():
		return false
	var refund := downgrade_refund()
	weapon_level -= 1
	Score.add_score(refund)
	changed.emit()
	return true


## What trading in the current weapon pays back.
func trade_in_value() -> int:
	return weapon.get_total_value(weapon_level)


## Net price of switching to `new_weapon` (its price minus the trade-in value).
## Negative means the player gets money back.
func buy_cost(new_weapon: WeaponData) -> int:
	return new_weapon.price - trade_in_value()


func can_afford_weapon(new_weapon: WeaponData) -> bool:
	return Score.score >= buy_cost(new_weapon)


## Trades in the current weapon and equips `new_weapon` at level 1.
## Returns false if it is already equipped or the player can't afford it.
func buy_weapon(new_weapon: WeaponData) -> bool:
	if new_weapon == weapon or not can_afford_weapon(new_weapon):
		return false
	Score.add_score(trade_in_value())
	Score.spend(new_weapon.price)
	weapon = new_weapon
	weapon_level = 1
	changed.emit()
	return true
