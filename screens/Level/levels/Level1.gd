extends Node2D

onready var currentWave = $Waves/SimpleFighters

func _ready():
	currentWave.start()

func _process(delta):
	currentWave.update(delta)
	