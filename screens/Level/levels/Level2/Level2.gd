## Level 2: runs the children of $Waves in order (wave protocol, see AGENTS.md)
## and emits `completed` after the last one (the boss).
extends Node2D

signal completed

var waves: Array[Node] = []
var currentWave: Node = null
var waveCount := 0


func _ready():
	waves = $Waves.get_children()
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
