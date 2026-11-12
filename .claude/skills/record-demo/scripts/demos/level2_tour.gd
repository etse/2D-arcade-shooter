## ~50 s look at Level 2: menu shows "Level 2", fast Rush wave, gunships
## stopping to fire bursts, the Crossfire wave, then the Dreadnought's
## three bullet-hell phases. Cheats: Level 1 marked done, Spread fire power 5,
## god mode, wave skips while black.
extends "res://.claude/skills/record-demo/scripts/demo_base.gd"


func run() -> void:
	Campaign.level_index = 1
	Loadout.weapon = Loadout.WEAPONS[1]
	Loadout.weapon_level = 5
	await goto(MENU)
	await wait(1.5)
	await click(node("MenuContainer/MainMenu/%StartGame"))
	var level := await wait_for_scene(LEVEL)
	god_mode(level)
	skip_to_wave(level, "Rush")
	await autopilot(6.0)

	await fade_out()
	skip_to_wave(level, "GunshipAmbush")
	await fade_in()
	await autopilot(9.0)

	await fade_out()
	skip_to_wave(level, "Crossfire")
	await fast_forward(3.0)
	await fade_in()
	await autopilot(8.0)

	await fade_out()
	var battle := skip_to_wave(level, "BossBattle")
	await fast_forward(3.0)
	await fade_in()
	await wait(1.0)
	var boss: Node = battle.boss
	boss.phase_changed.connect(func(p): log_line("phase %d" % p))
	await autopilot(40.0, func(): return not is_instance_valid(boss) or boss.health <= 0)
	log_line("boss dead=%s score=%d" % [not is_instance_valid(boss) or boss.health <= 0, Score.score])
	await wait(2.5)
	await fade_out(1.0)
