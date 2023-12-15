extends CanvasLayer
var healthTween: Tween

func _ready():
	healthTween = create_tween()

func _process(delta):
	$ScoreLabel.text = "$%s" % Score.score
	
func set_max_health(health: float):
	$HealthBar.max_value = health
	
func update_health(health: float):
	healthTween.stop()
	healthTween.tween_property($HealthBar, "value", health, 0.3).from_current().set_trans(Tween.TRANS_LINEAR)
	healthTween.play()
