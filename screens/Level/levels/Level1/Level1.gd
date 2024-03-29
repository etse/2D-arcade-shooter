extends Node2D

@onready var waves = [$Waves/Wait, $Waves/SimpleFighters, $Waves/Formation, $Waves/Wait, $Waves/BossBattle]
@onready var currentWave = null
var waveCount = 0

func _ready():
	currentWave = waves[waveCount]
	currentWave.start()

func _process(delta):
	if currentWave.update(delta):
		currentWave.exit()
		waveCount += 1
		currentWave = waves[waveCount % waves.size()]
		currentWave.start()
	
