extends Node2D

var basicEnemy = preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn") 
onready var tweenNode = get_node("tween")

signal spawned_enemy(enemy)

func _ready():
	pass

func _on_Timer_timeout():
	var enemy = basicEnemy.instance()
	enemy.position = $StartLeft.position	
	tweenNode.interpolate_property(enemy, "position", $StartLeft.position, $EndLeft.position, 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tweenNode.start()
	emit_signal("spawned_enemy", enemy)
	