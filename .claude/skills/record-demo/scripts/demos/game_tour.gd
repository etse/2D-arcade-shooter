## ~55 s tour of the whole game: start Level 1 with the starting Pulse fire,
## cut (fade) to the hardest wave, cut to the boss and kill it, back in the
## menu buy Spread fire + 6 upgrades, then cut into the hardest wave again
## to show it off. Cheats: god mode, wave skips, fast-forward while black,
## weakened boss, money.
extends "res://.claude/skills/record-demo/scripts/demo_base.gd"

const BOSS_HEALTH := 45.0
const SHOP_MONEY := 16000   # Spread fire trade (+$100) + 6 upgrades ($15750)


func run() -> void:
	# 1) Title -> start the game, play the first wave
	await goto(MENU)
	await wait(1.2)
	await click(node("MenuContainer/MainMenu/%StartGame"))
	var level := await wait_for_scene(LEVEL)
	god_mode(level)
	skip_to_wave(level, "SimpleFighters")
	await autopilot(8.0)
	log_line("first wave: score=%d" % Score.score)

	# 2) Cut to the hardest wave
	await fade_out()
	skip_to_wave(level, "Attackers")
	await fast_forward(3.0)
	await fade_in()
	await autopilot(8.0)
	log_line("attackers: score=%d" % Score.score)

	# 3) Cut to the boss (weakened so the weak weapon can finish it)
	await fade_out()
	var battle := skip_to_wave(level, "BossBattle")
	await fast_forward(4.5)
	var boss: Node = battle.boss
	boss.health = BOSS_HEALTH
	await fade_in()
	await autopilot(25.0, func(): return not is_instance_valid(boss) or boss.health <= 0)
	log_line("boss dead=%s score=%d" % [not is_instance_valid(boss) or boss.health <= 0, Score.score])
	await wait(1.5)                  # let the explosion play
	await fade_out()
	Score.add_score(SHOP_MONEY)
	fast_forward(5.0)                # skip the level's own pause + fade to menu
	await wait_for_scene(MENU)
	Campaign.level_index = 0         # beating the boss advanced to Level 2; replay Level 1
	node("MenuContainer/MainMenu").refresh()
	Engine.time_scale = 1.0
	await fade_in(0.4)

	# 4) Shop: buy Spread fire and power it up 6 times
	await wait(0.6)
	await click(node("MenuContainer/MainMenu/%UpgradeWeapon"))
	await wait(1.3)                  # Pulse fire preview
	await tap("ui_down", 1.5)        # Spread fire preview
	await tap("ui_accept", 0.9)      # buy (trade in Pulse fire)
	for i in 6:
		await tap("ui_right", 0.45)
	await wait(1.2)
	log_line("bought %s power %d, $%d left" % [Loadout.weapon.name, Loadout.weapon_level, Score.score])
	await tap("ui_cancel", 0.4)
	await click(node("MenuContainer/MainMenu/%StartGame"))

	# 5) Cut into a busy wave with the new weapon
	level = await wait_for_scene(LEVEL)
	black()
	god_mode(level)
	skip_to_wave(level, "Attackers")
	await fast_forward(5.0)
	await fade_in()
	await autopilot(11.0)
	log_line("spread fire: score=%d" % Score.score)
	await fade_out(1.0)
