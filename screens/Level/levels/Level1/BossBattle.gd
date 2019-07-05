extends Node

var BossEnemy = preload("res://components/Bosses/SimpleBoss/SimpleBoss.tscn")
onready var startPos = $Points/Start
onready var entryPos = $Points/Entry

func start():
	var boss = BossEnemy.instance()
	boss.position = startPos.position
	$Tween.interpolate_property(boss, "position", startPos.position, entryPos.position, 5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()
	add_child(boss)
	
func update(delta: float):
	pass
	
