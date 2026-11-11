extends Node

var basicEnemy = preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn")
var spawnCount = 0

func start():
	spawnCount = 0
	$Timer.start()
	
func update(delta: float):
	if spawnCount >= 16:
		return true
	
func exit():
	$Timer.stop()

func _on_Timer_timeout():
	var enemy = basicEnemy.instantiate()
	var path = PathFollow2D.new()
	path.add_child(enemy)
	if spawnCount % 2 == 0:
		$Enemies/LeftPath.add_child(path)
	else:
		$Enemies/RightPath.add_child(path)
	path.rotates = false
	path.rotation = 0
	var tween = path.create_tween()
	tween.tween_property(path, "progress_ratio", 1.0, 10).set_trans(Tween.TRANS_LINEAR)
	# Paths end below the screen: free the follower (and its enemy) when done.
	tween.finished.connect(path.queue_free)
	spawnCount += 1
