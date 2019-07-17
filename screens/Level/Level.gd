extends Node

func _ready():
	CameraControl.connect("screenshake", self, "_on_screen_shake")
	$HUD.set_max_health($Player.max_health)
	
func _on_screen_shake(amplitude, frequency, duration):
	$Camera/ScreenShake.start_shake(amplitude, frequency, duration)

func _on_Player_health_changed(health: float):
	$HUD.update_health(health)
