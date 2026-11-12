extends Node

var menuScnene = "res://screens/Menu/Menu.tscn"
var ending = false
## The current level (Level1, Level2, …), instanced from Campaign.
var level: Node

func _ready():
	level = Campaign.level_scene().instantiate()
	add_child(level)
	move_child(level, $Projectiles.get_index())  # below bullets and the fade overlay
	level.completed.connect(_on_level_completed)
	var tween = get_tree().create_tween()
	$Overlay.modulate = Color(0, 0, 0, 1)
	CameraControl.connect("screenshake", Callable(self, "_on_screen_shake"))
	$HUD.set_max_health($Player.max_health)
	tween.tween_property($Overlay, "modulate", Color(0, 0, 0, 0), 1).set_trans(Tween.TRANS_CUBIC)
	tween.play()

func _on_screen_shake(amplitude, frequency, duration):
	$Camera/ScreenShake.start_shake(amplitude, frequency, duration)

func _on_Player_health_changed(health: float):
	$HUD.update_health(health)

func _on_Player_destroyed():
	_return_to_menu()

func _on_level_completed():
	Campaign.complete_level()
	# Short pause after the boss explodes before fading out.
	await get_tree().create_timer(2.0).timeout
	_return_to_menu()

func _return_to_menu():
	if ending:
		return
	ending = true
	var tween = get_tree().create_tween()
	tween.tween_property($Overlay, "modulate", Color(0, 0, 0, 1), 2).set_trans(Tween.TRANS_CUBIC)
	tween.play()
	await tween.finished
	get_tree().change_scene_to_file(menuScnene)
