extends Node

var stepComplete = false

func start():
	stepComplete = false
	$Timer.start()
	
func update(delta: float):
	return stepComplete
	
func exit():
	pass

func _on_Timer_timeout():
	stepComplete = true
	