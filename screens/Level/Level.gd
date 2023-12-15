extends Node

var menuScnene = "res://screens/Menu/Menu.tscn"

func _ready():
	var tween = get_tree().create_tween()
	$Overlay.modulate = Color(0, 0, 0, 1)
	CameraControl.connect("screenshake", Callable(self, "_on_screen_shake"))
	$HUD.set_max_health($Player.max_health)
	tween.tween_property($Overlay, "modulate", Color(0, 0, 0, 0), 1).set_trans(Tween.TRANS_CUBIC)
	tween.play()
	
func _on_screen_shake(amplitude, frequency, duration):
	$Camera3D/ScreenShake.start_shake(amplitude, frequency, duration)

func _on_Player_health_changed(health: float):
	$HUD.update_health(health)

func _on_Player_destroyed():
	var tween = get_tree().create_tween()
	tween.tween_property($Overlay, "modulate", Color(0, 0, 0, 1), 2).set_trans(Tween.TRANS_CUBIC)
	tween.play()
	await tween.finished
	get_tree().change_scene_to_file(menuScnene)
