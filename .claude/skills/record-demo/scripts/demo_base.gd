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


## Wait until the current scene's root node has this name (e.g. after a menu
## button triggers a scene change). Returns the scene root.
func scene_named(scene_name: String) -> Node:
	while get_tree().current_scene == null or get_tree().current_scene.name != scene_name:
		await get_tree().process_frame
	await get_tree().process_frame
	return get_tree().current_scene


## Node in the current scene, e.g. node("MenuContainer/MainMenu/StartGame").
func node(path: String) -> Node:
	return get_tree().current_scene.get_node(path)


func _root_name_of(scene_path: String) -> String:
	var state := (load(scene_path) as PackedScene).get_state()
	return state.get_node_name(0)


# --- menu ------------------------------------------------------------------------

## Focus a menu Label (components/Menu/Label) and "press" it, playing its
## select + accept animation and sound like a real key press.
func click(label: Node, focus_time := 0.15, after := 0.3) -> void:
	label.grab_focus()
	await wait(focus_time)
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	label._on_Label_gui_input(ev)
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
