extends Node
onready var menuScnene = "res://screens/Menu/Menu.tscn"

func _ready():
	$Overlay.modulate = Color(0, 0, 0, 1)
	CameraControl.connect("screenshake", self, "_on_screen_shake")
	$HUD.set_max_health($Player.max_health)
	$Tween.interpolate_property($Overlay, "modulate", Color(0, 0, 0, 1), Color(0, 0, 0, 0), 1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()
	
func _on_screen_shake(amplitude, frequency, duration):
	$Camera/ScreenShake.start_shake(amplitude, frequency, duration)

func _on_Player_health_changed(health: float):
	$HUD.update_health(health)

func _on_Player_destroyed():
	$Tween.interpolate_property($Overlay, "modulate", Color(0, 0, 0, 0), Color(0, 0, 0, 1), 2, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_completed")
	get_tree().change_scene(menuScnene)
