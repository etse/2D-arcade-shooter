extends Node2D

signal completed

@onready var waves = [$Waves/Wait, $Waves/SimpleFighters, $Waves/DifferentStrength, $Waves/Formation, $Waves/Attackers, $Waves/Wait, $Waves/BossBattle]
@onready var currentWave = null
var waveCount = 0

func _ready():
	currentWave = waves[waveCount]
	currentWave.start()

func _process(delta):
	if currentWave == null:
		return
	if currentWave.update(delta):
		currentWave.exit()
		waveCount += 1
		if waveCount >= waves.size():
			currentWave = null
			completed.emit()
			return
		currentWave = waves[waveCount]
		currentWave.start()
