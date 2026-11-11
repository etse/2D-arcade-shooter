extends Node

var basicEnemy = preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn")
var spawnCount = 0
@onready var startPoints = [$Points/StartLeft, $Points/StartCenter, $Points/StartRight, $Points/StartCenter]
@onready var endPoints = [$Points/EndLeft, $Points/EndCenter, $Points/EndRight, $Points/EndCenter]

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
	$Enemies.add_child(enemy)
	# Bind the tween to the enemy so it dies with it if the enemy is shot down.
	var tween = enemy.create_tween()
	tween.tween_property(enemy, "position", endPos.position, 5).set_trans(Tween.TRANS_LINEAR)
	# End points are below the screen: remove enemies that fly past the player.
	tween.finished.connect(enemy.queue_free)
	spawnCount += 1
