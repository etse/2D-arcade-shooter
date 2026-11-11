## ~20 s tour of the menu screens and HUD: main menu (browse rows) -> options
## (toggle a slider) -> upgrade ship -> weapon shop -> level with the HUD,
## money going up and hull taking damage.
extends "res://.claude/skills/record-demo/scripts/demo_base.gd"


func run() -> void:
	Score.add_score(1200)
	Loadout.weapon_level = 3
	await goto(MENU)
	await wait(1.2)
	for i in 3:
		await tap("ui_down", 0.6)
	await click(node("MenuContainer/MainMenu/%Options"), 0.1, 0.6)  # Options
	await tap("ui_down", 0.5)
	await tap("ui_left", 0.2)
	await tap("ui_left", 0.5)
	await tap("ui_cancel", 0.6)
	await click(node("MenuContainer/MainMenu/%UpgradeShip"), 0.3, 1.2)
	await tap("ui_cancel", 0.6)
	await click(node("MenuContainer/MainMenu/%UpgradeWeapon"), 0.3, 1.6)
	await tap("ui_cancel", 0.6)
	await click(node("MenuContainer/MainMenu/%StartGame"), 0.3)

	var level := await scene_named("Level")
	await wait(0.4)
	var row := spawn_row(level, 3, 140.0, 420.0)
	press("shoot")
	await wait_until_cleared(4.0)
	press("shoot", false)
	var player := level.get_node("Player")
	for hit in [20, 25, 20]:
		player.on_hit(hit)
		player.health_changed.emit(player.health)
		await wait(0.7)
	await wait(1.0)
	log_line("hull=%d alive=%d" % [player.health, enemies_alive().size()])
