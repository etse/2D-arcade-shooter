extends Node2D

signal spawned_enemy(enemy)

func _ready():
	$Waves/SimpleFighters.start()

func _process(delta):
	$Waves/SimpleFighters.update()
	