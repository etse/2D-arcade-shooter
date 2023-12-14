extends Node

var basicEnemy = preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn")
var spawnCount = 0
@onready var startPoints = [$Points/StartLeft, $Points/StartCenter, $Points/StartRight, $Points/StartCenter]
@onready var endPoints = [$Points/EndLeft, $Points/EndCenter, $Points/EndRight, $Points/EndCenter]
@onready var tween = get_tree().create_tween()

func start():
	spawnCount = 0
	$Timer.start()
	
func update(delta: float):
	if spawnCount >= 8:
		return true
	
func exit():
	$Timer.stop()

func _on_Timer_timeout():
	var enemy = basicEnemy.instantiate()
	var startPos = startPoints[spawnCount % startPoints.size()]
	var endPos = endPoints[spawnCount % endPoints.size()]
	enemy.position = startPos.position
	tween.tween_property(enemy, "position", endPos.position, 5).set_trans(Tween.TRANS_LINEAR)
	tween.play()
	$Enemies.add_child(enemy)
	spawnCount += 1
	

func _on_tween_tween_completed(object, key):
	object.queue_free()
