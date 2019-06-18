extends Node

var basicEnemy = preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn") 

signal spawned_enemy(enemy)

func start():
	$Timer.start()
	
func update(delta: float):
	pass

func _on_Timer_timeout():
	var enemy = basicEnemy.instance()
	enemy.position = $StartLeft.position	
	$tween.interpolate_property(enemy, "position", $StartLeft.position, $EndLeft.position, 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$tween.start()
	emit_signal("spawned_enemy", enemy)
	