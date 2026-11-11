extends Node

var BossEnemy = preload("res://components/Bosses/SimpleBoss/SimpleBoss.tscn")
@onready var startPos = $Points/Start
@onready var entryPos = $Points/Entry
@onready var leftPos = $Points/Left
@onready var rightPos = $Points/Right
var boss: Node2D = null
var bossDefeated = false

func start():
	bossDefeated = false
	boss = BossEnemy.instantiate()
	boss.position = startPos.position
	boss.destroyed.connect(_on_boss_destroyed)
	add_child(boss)

	await _move_boss(entryPos.position, 5)
	await _move_boss(rightPos.position, 3)
	if _boss_alive():
		boss.startShooting()

	while _boss_alive():
		await _move_boss(leftPos.position, 5)
		await _move_boss(rightPos.position, 5)

func update(delta: float):
	return bossDefeated

func exit():
	pass

func _boss_alive() -> bool:
	return is_instance_valid(boss) and boss.health > 0

func _move_boss(target: Vector2, duration: float):
	if not _boss_alive():
		return
	# Bound to the boss so the tween is cleaned up together with it.
	var tween = boss.create_tween()
	tween.tween_property(boss, "position", target, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished

func _on_boss_destroyed():
	bossDefeated = true
	boss.queue_free()
