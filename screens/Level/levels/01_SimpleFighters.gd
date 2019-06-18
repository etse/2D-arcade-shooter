extends Node

var basicEnemy = preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn")
var spawnCount = 0
onready var startPoints = [$Points/StartLeft, $Points/StartCenter, $Points/StartRight, $Points/StartCenter]
onready var endPoints = [$Points/EndLeft, $Points/EndCenter, $Points/EndRight, $Points/EndCenter]

func start():
	$Timer.start()
	
func update(delta: float):
	pass

func _on_Timer_timeout():
	var enemy = basicEnemy.instance()
	var startPos = startPoints[spawnCount % startPoints.size()]
	var endPos = endPoints[spawnCount % endPoints.size()]
	enemy.position = startPos.position
	$tween.interpolate_property(enemy, "position", startPos.position, endPos.position, 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$tween.start()
	$Enemies.add_child(enemy)
	spawnCount += 1
	