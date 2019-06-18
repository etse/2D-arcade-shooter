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
	print("SPAWN!")
	var enemy = basicEnemy.instance()
	var path = PathFollow2D.new()
	path.add_child(enemy)
	if spawnCount % 2 == 0:
		$Enemies/LeftPath.add_child(path)
	else:
		$Enemies/RightPath.add_child(path)
	path.rotate = false
	path.rotation = 0
	$Tween.interpolate_property(path, "unit_offset", 0, 1, 8, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	spawnCount += 1
	

func _on_Tween_tween_completed(object, key):
	object.queue_free()
