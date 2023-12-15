extends Node

var basicEnemy = preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn")
var spawnCount = 0
@onready var tween = get_tree().create_tween()

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
	path.rotate = false
	path.rotation = 0
	tween.interpolate_property(path, "progress_ratio", 1).set_trans(Tween.TRANS_LINEAR)
	tween.play()
	spawnCount += 1
	

func _on_Tween_tween_completed(object, key):
	object.queue_free()
