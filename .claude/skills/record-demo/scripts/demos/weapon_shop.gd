## ~18 s demo: weak level-1 Focus fire -> shop upgrades 1..10 -> maxed weapon
## shredding two enemy rows and the boss.
extends "res://.claude/skills/record-demo/scripts/demo_base.gd"


func run() -> void:
	# 1) Title screen -> start level
	await goto(MENU)
	await wait(0.9)
	await click(node("MenuContainer/MainMenu/StartGame"))

	# 2) Level-1 weapon: park under each enemy until it goes down
	var level := await scene_named("Level")
	await wait(0.4)
	var row := spawn_row(level, 3, 170.0, 420.0)
	press("shoot")
	await wait_until_dead(row[1])          # middle, right above the player
	await hold("move_left", 0.3)
	await wait_until_dead(row[0])
	await hold("move_right", 0.64)
	await wait_until_dead(row[2])
	await wait(0.5)
	press("shoot", false)
	log_line("weak weapon: score=%d alive=%d" % [Score.score, enemies_alive().size()])

	# 3) Cheat money, max the weapon out in the shop
	Score.add_score(9000)
	await goto(MENU)
	await wait(0.3)
	await click(node("MenuContainer/MainMenu/UpgradeWeapon"))
	await wait(0.6)
	while not Loadout.is_weapon_maxed():
		await click(node("MenuContainer/WeaponShop/Upgrade"), 0.02, 0.3)
	await wait(0.6)
	await click(node("MenuContainer/WeaponShop/Back"))
	await wait(0.25)
	await click(node("MenuContainer/MainMenu/StartGame"))

	# 4) Maxed weapon vs two rows + boss: sweep until everything is dead
	level = await scene_named("Level")
	await wait(0.3)
	spawn_row(level, 6, 120.0, 470.0)
	spawn_row(level, 5, 140.0, 360.0)
	spawn_boss(level)
	press("shoot")
	await wait(0.5)
	for i in 2:
		if not any_enemy_alive():
			break
		await hold("move_left", 0.45)
		await hold("move_right", 1.1)
		await hold("move_left", 0.6)
		await wait(0.3)
	await wait_until_cleared()
	await wait(1.0)  # let the last explosions play
	press("shoot", false)
	log_line("maxed weapon: alive=%d" % enemies_alive().size())
