extends Node2D

signal spawned_enemy(enemy)
onready var currentWave = $Waves/SimpleFighters

func _ready():
	currentWave.start()

func _process(delta):
	currentWave.update(delta)
	