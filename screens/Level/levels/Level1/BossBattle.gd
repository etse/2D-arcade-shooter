extends Node

var BossEnemy = preload("res://components/Bosses/SimpleBoss/SimpleBoss.tscn")
onready var startPos = $Points/Start
onready var entryPos = $Points/Entry
onready var leftPos = $Points/Left
onready var rightPos = $Points/Right


func start():
	var boss = BossEnemy.instance()
	boss.position = startPos.position
	add_child(boss)
	
	$Tween.interpolate_property(boss, "position", startPos.position, entryPos.position, 5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	
	$Tween.interpolate_property(boss, "position", entryPos.position, rightPos.position, 3, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()
	boss.startShooting()
	yield($Tween, "tween_completed")
	
	while(boss.health > 0):
		$Tween.interpolate_property(boss, "position", rightPos.position, leftPos.position, 5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		$Tween.start()
		yield($Tween, "tween_completed")
		
		$Tween.interpolate_property(boss, "position", leftPos.position, rightPos.position, 5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		$Tween.start()
		yield($Tween, "tween_completed")
	
func update(delta: float):
	pass
	
