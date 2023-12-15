extends CanvasLayer

func _ready():
	pass

func _process(delta):
	$ScoreLabel.text = "$%s" % Score.score
	
func set_max_health(health: float):
	$HealthBar.max_value = health
	
func update_health(health: float):
	var healthTween = create_tween()
	healthTween.stop()
	healthTween.tween_property($HealthBar, "value", health, 0.3).set_trans(Tween.TRANS_LINEAR)
	healthTween.play()
