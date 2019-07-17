extends CanvasLayer

func _process(delta):
	$ScoreLabel.text = "$%s" % Score.score
	
func set_max_health(health: float):
	$HealthBar.max_value = health
	
func update_health(health: float):
	$HealthTween.stop_all()
	$HealthTween.interpolate_property($HealthBar, "value", $HealthBar.value, health, 0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$HealthTween.start()
