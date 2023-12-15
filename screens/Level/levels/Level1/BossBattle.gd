extends Node

var BossEnemy = preload("res://components/Bosses/SimpleBoss/SimpleBoss.tscn")
@onready var startPos = $Points/Start
@onready var entryPos = $Points/Entry
@onready var leftPos = $Points/Left
@onready var rightPos = $Points/Right
@onready var tween = get_tree().create_tween()


func start():
	var boss = BossEnemy.instantiate()
	boss.position = startPos.position
	add_child(boss)
	
	tween.tween_property(boss, "position", startPos.position, 5).set_trans(Tween.TRANS_SINE)
	tween.play
	await tween.tween_completed
	
	tween.tween_property(boss, "position", entryPos.position, 3).set_trans(Tween.TRANS_SINE)
	tween.play()
	boss.startShooting()
	await tween.tween_completed
	
	while(boss.health > 0):
		tween.tween_property(boss, "position", rightPos.position, 5).set_trans(Tween.TRANS_SINE)
		tween.play()
		await tween.tween_completed
		
		tween.tween_property(boss, "position", rightPos.position, 5).set_trans(Tween.TRANS_SINE)
		tween.play()
		await tween.tween_completed
	
func update(delta: float):
	pass
	
