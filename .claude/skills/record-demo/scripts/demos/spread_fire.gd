## ~25 s demo of the Tyrian-style weapon shop + Spread fire: browse weapons
## (live preview), buy Spread fire (trade-in), power it up and down, then
## play with it at power 1, 5 and 10 vs rows + boss.
extends "res://.claude/skills/record-demo/scripts/demo_base.gd"

const SPREAD_FIRE := preload("res://components/Weapons/SpreadFire/SpreadFire.tres")


func run() -> void:
	# 1) Shop: preview Pulse fire, browse to Spread fire, buy it, power it up
	Score.add_score(1500)
	await goto(MENU)
	await wait(0.6)
	await click(node("MenuContainer/MainMenu/%UpgradeWeapon"))
	await wait(1.6)                 # Pulse fire preview
	await tap("ui_down", 1.8)       # Spread fire preview (power 1)
	var before := Score.score
	await tap("ui_accept", 1.2)
	log_line("bought %s: $%d -> $%d" % [Loadout.weapon.name, before, Score.score])
	for i in 4:
		await tap("ui_right", 0.5)
	await wait(1.0)
	await tap("ui_left", 1.0)       # downgrade: refund
	log_line("power %d, $%d" % [Loadout.weapon_level, Score.score])
	await tap("ui_down", 0.5)       # DONE
	await tap("ui_accept", 0.4)
	await click(node("MenuContainer/MainMenu/%StartGame"))

	# 2) In game: low power vs a row
	var level := await scene_named("Level")
	await wait(0.3)
	spawn_row(level, 3, 120.0, 420.0)
	press("shoot")
	await wait_until_cleared(3.0)
	press("shoot", false)
	log_line("power %d: alive=%d" % [Loadout.weapon_level, enemies_alive().size()])

	# 3) Max power: spray covers most of the screen
	Loadout.weapon_level = SPREAD_FIRE.max_level()
	spawn_row(level, 8, 105.0, 470.0)
	spawn_row(level, 7, 125.0, 330.0)
	spawn_boss(level)
	press("shoot")
	await wait(0.5)
	await hold("move_left", 0.3)
	await hold("move_right", 0.6)
	await hold("move_left", 0.3)
	await wait_until_cleared(8.0)
	await wait(1.0)
	press("shoot", false)
	log_line("power 10: alive=%d" % enemies_alive().size())
