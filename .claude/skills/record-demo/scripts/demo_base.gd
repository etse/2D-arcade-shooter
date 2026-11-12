## Base class for scripted demo recordings ("directors").
## A director extends this file and implements `run()`; it may cheat freely
## (add money, spawn enemies, set weapon levels, jump between scenes).
## Recording ends when run() returns. See ../SKILL.md.
extends Node

const MENU := "res://screens/Menu/Menu.tscn"
const LEVEL := "res://screens/Level/Level.tscn"
const BasicEnemy := preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn")
const Boss := preload("res://components/Bosses/SimpleBoss/SimpleBoss.tscn")


## Override this with the demo's script. Use `await` freely.
func run() -> void:
	push_error("demo director must override run()")


func _ready():
	_start.call_deferred()


func _start():
	# Detach from the launcher scene so we survive change_scene_to_file().
	var root := get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	await run()
	log_line("end score=%d" % Score.score)
	get_tree().quit()


# --- logging -------------------------------------------------------------------

## Printed lines starting with "DEMO" are shown by record.sh (use for sanity checks).
func log_line(text: String) -> void:
	print("DEMO ", text)


# --- time & scenes ---------------------------------------------------------------

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Change scene and wait until it is ready. Returns the new scene root.
func goto(scene_path: String) -> Node:
	get_tree().change_scene_to_file(scene_path)
	return await scene_named(_root_name_of(scene_path))


## Wait until the game itself switches to `scene_path` (MENU, LEVEL, …).
func wait_for_scene(scene_path: String) -> Node:
	return await scene_named(_root_name_of(scene_path))


## Wait until the current scene's root node has this name (e.g. after a menu
## button triggers a scene change). Returns the scene root.
func scene_named(scene_name: String) -> Node:
	while get_tree().current_scene == null or get_tree().current_scene.name != scene_name:
		await get_tree().process_frame
	await get_tree().process_frame
	return get_tree().current_scene


## Node in the current scene, e.g. node("MenuContainer/MainMenu/%StartGame")
## (menu rows are unique names inside their panel scene; see SKILL.md).
func node(path: String) -> Node:
	return get_tree().current_scene.get_node(path)


func _root_name_of(scene_path: String) -> String:
	var state := (load(scene_path) as PackedScene).get_state()
	return state.get_node_name(0)


# --- menu ------------------------------------------------------------------------

## Focus a menu row (components/UI/MenuRow) and "press" it, with its
## highlight, flash and sound like a real key press.
func click(row: Node, focus_time := 0.15, after := 0.3) -> void:
	row.grab_focus()
	await wait(focus_time)
	await row.press()
	await wait(after)


# --- player input ------------------------------------------------------------------

## Press/release an input action (move_left/right/up/down, shoot) as real input.
func press(action: String, pressed := true) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


## Tap an action like a key press (press + release), then wait `after` seconds.
## Use for menus that read input directly, e.g. the weapon shop
## (ui_up/ui_down/ui_left/ui_right/ui_accept/ui_cancel).
func tap(action: String, after := 0.25) -> void:
	press(action, true)
	await get_tree().process_frame
	press(action, false)
	await wait(after)


## Hold an action for `seconds`, then release it.
func hold(action: String, seconds: float) -> void:
	press(action, true)
	await wait(seconds)
	press(action, false)


# --- spawning ------------------------------------------------------------------------

## A row of BasicEnemies centred on x=960 that swoops in from above to hover at y.
func spawn_row(level: Node, count: int, spacing: float, y: float) -> Array[Node]:
	var enemies: Array[Node] = []
	for i in count:
		var enemy := BasicEnemy.instantiate()
		var x := 960.0 + (i - (count - 1) / 2.0) * spacing
		enemy.position = Vector2(x, -100 - i * 30)
		level.add_child(enemy)
		var t := enemy.create_tween()
		t.tween_property(enemy, "position", Vector2(x, y), 0.9 + i * 0.08) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		enemies.append(enemy)
	return enemies


## The level-1 boss flying in to `target` and starting to shoot.
func spawn_boss(level: Node, health := 140.0, target := Vector2(960, 200)) -> Node:
	var boss := Boss.instantiate()
	boss.health = health
	boss.position = Vector2(target.x, -250)
	level.add_child(boss)
	var t := boss.create_tween()
	t.tween_property(boss, "position", target, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(boss.startShooting)
	return boss


func enemies_alive() -> Array:
	return get_tree().get_nodes_in_group("enemies").filter(func(e): return e.health > 0)


func any_enemy_alive() -> bool:
	return not enemies_alive().is_empty()


## Wait until `enemy` is dead or freed (or `timeout` seconds pass).
func wait_until_dead(enemy: Node, timeout := 5.0) -> void:
	var waited := 0.0
	while is_instance_valid(enemy) and enemy.health > 0 and waited < timeout:
		await wait(0.05)
		waited += 0.05


## Wait until every enemy is dead (or `timeout` seconds pass).
func wait_until_cleared(timeout := 10.0) -> void:
	var waited := 0.0
	while any_enemy_alive() and waited < timeout:
		await wait(0.1)
		waited += 0.1


# --- transitions -----------------------------------------------------------------------
# A black overlay owned by the director (on top of everything, survives scene
# changes). Use it to cut between parts of the game: fade_out(), cheat/jump
# while black, fade_in().

var _fade: ColorRect


func _fade_rect() -> ColorRect:
	if _fade == null:
		var layer := CanvasLayer.new()
		layer.layer = 128
		add_child(layer)
		_fade = ColorRect.new()
		_fade.color = Color.BLACK
		_fade.size = Vector2(1920, 1080)
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade.modulate.a = 0.0
		layer.add_child(_fade)
	return _fade


func fade_out(seconds := 0.6) -> void:
	var t := create_tween()
	t.tween_property(_fade_rect(), "modulate:a", 1.0, seconds)
	await t.finished


func fade_in(seconds := 0.6) -> void:
	var t := create_tween()
	t.tween_property(_fade_rect(), "modulate:a", 0.0, seconds)
	await t.finished


## Go black instantly (e.g. right after a scene change, before jumping ahead).
func black() -> void:
	_fade_rect().modulate.a = 1.0


## Run the game `seconds` (game time) at `speed`x. Do it while black() to skip
## ahead, e.g. to let a freshly started wave fill the screen.
func fast_forward(seconds: float, speed := 6.0) -> void:
	Engine.time_scale = speed
	await wait(seconds)   # scene-tree timers run in game time
	Engine.time_scale = 1.0


# --- level cheats ------------------------------------------------------------------------

## Start level `number` (1-based) directly, skipping the menu.
func goto_level(number: int) -> Node:
	Campaign.level_index = number - 1
	return await goto(LEVEL)


## Jump the current level to the wave node named `wave_name` (see the level's
## `waves`), e.g. Level 1: "SimpleFighters", "DifferentStrength", "Formation",
## "Attackers", "BossBattle"; Level 2: see Level2.tscn `Waves`.
## Clears enemies and bullets on screen first unless `clear` is false.
func skip_to_wave(level: Node, wave_name: String, clear := true) -> Node:
	var l1: Node = level.level
	var index: int = l1.waves.map(func(w): return w.name).find(wave_name)
	assert(index >= 0, "no wave named " + wave_name)
	if l1.currentWave != null:
		l1.currentWave.exit()
	if clear:
		clear_screen()
	l1.waveCount = index
	l1.currentWave = l1.waves[index]
	l1.currentWave.start()
	log_line("skip to wave %s" % wave_name)
	return l1.currentWave


## Remove all enemies (incl. bosses) and bullets.
func clear_screen() -> void:
	for group in ["enemies", "bullets"]:
		for n in get_tree().get_nodes_in_group(group):
			n.queue_free()


var _god_player: Node


## Keep the level's player at full health (fireballs and ramming still flash/shake).
func god_mode(level: Node) -> void:
	_god_player = level.get_node("Player")


func _process(_delta: float) -> void:
	if is_instance_valid(_god_player) and _god_player.health < _god_player.max_health:
		_god_player.health = _god_player.max_health
		_god_player.health_changed.emit(_god_player.health)


# --- autopilot ------------------------------------------------------------------------------

## Play the level by itself for `seconds` (or until `until.call()` is true):
## hold fire and slide under a target (close in x, heavies preferred), sticking
## with it until it dies or leaves the screen. Doesn't dodge: use god_mode().
func autopilot(seconds: float, until := Callable()) -> void:
	var player: Node2D = get_tree().current_scene.get_node("Player")
	var held := ""
	press("shoot")
	var elapsed := 0.0
	while elapsed < seconds and not (until.is_valid() and until.call()):
		if not is_instance_valid(player):
			break
		var want := _autopilot_direction(player)
		if want != held:
			if held != "":
				press(held, false)
			if want != "":
				press(want)
			held = want
		await get_tree().process_frame
		elapsed += get_process_delta_time() / maxf(Engine.time_scale, 0.001)
	if held != "":
		press(held, false)
	press("shoot", false)


var _target: Node2D


func _autopilot_direction(player: Node2D) -> String:
	var px := player.global_position.x
	var alive := enemies_alive()
	# No dodging: it fought the targeting (ship froze between the two). Pair
	# the autopilot with god_mode() so ramming does no lasting harm.
	# Stick with one target until it dies or leaves the shooting zone, so the
	# ship commits instead of dithering between enemies.
	if not (is_instance_valid(_target) and _target in alive and _in_zone(_target)):
		_target = null
		var best := INF
		for e in alive:
			if not _in_zone(e):
				continue
			# Prefer close in x; heavies and bosses are worth a detour.
			var cost: float = absf(e.global_position.x - px) - (300.0 if e.health > 10 else 0.0)
			if cost < best:
				best = cost
				_target = e
	if _target == null:
		return ""
	var target_x := clampf(_target.global_position.x, 120.0, 1800.0)
	if absf(target_x - px) < 35.0:
		return ""
	return "move_right" if target_x > px else "move_left"


func _in_zone(e: Node2D) -> bool:
	return e.global_position.y > 30.0 and e.global_position.y < 720.0
