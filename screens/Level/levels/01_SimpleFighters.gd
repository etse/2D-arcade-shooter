extends Node

var basicEnemy = preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn")

signal spawned_enemy(enemy)

func start():
	$Timer.start()
	
func update(delta: float):
	pass

func _on_Timer_timeout():
	var enemy = basicEnemy.instance()
	enemy.position = $Points.StartLeft.position
	$tween.interpolate_property(enemy, "position", $Points.StartLeft.position, $Points.EndLeft.position, 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$tween.start()
	print("spawn")
	emit_signal("spawned_enemy", enemy)
	