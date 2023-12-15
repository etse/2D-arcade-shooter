extends Node

var BossEnemy = preload("res://components/Bosses/SimpleBoss/SimpleBoss.tscn")
@onready var startPos = $Points/Start
@onready var entryPos = $Points/Entry
@onready var leftPos = $Points/Left
@onready var rightPos = $Points/Right


func start():
	var moveToScreenTween = create_tween()
	var boss = BossEnemy.instantiate()
	boss.position = startPos.position
	add_child(boss)
	
	moveToScreenTween.tween_property(boss, "position", entryPos.position, 5).from(startPos.position).set_trans(Tween.TRANS_SINE)
	moveToScreenTween.play
	await moveToScreenTween.finished
	
	var moveRightTween = create_tween()
	moveRightTween.tween_property(boss, "position", rightPos.position, 3).set_trans(Tween.TRANS_SINE)
	moveRightTween.play()
	boss.startShooting()
	await moveRightTween.finished
	
	while(boss.health > 0):
		var movementTween = create_tween()
		movementTween.tween_property(boss, "position", leftPos.position, 5).set_trans(Tween.TRANS_SINE)		
		movementTween.tween_property(boss, "position", rightPos.position, 5).set_trans(Tween.TRANS_SINE)
		movementTween.play()
		await movementTween.finished
	
func update(delta: float):
	pass
	
