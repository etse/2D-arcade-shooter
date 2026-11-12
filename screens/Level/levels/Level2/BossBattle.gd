## Flies the Dreadnought in, starts its fight, finishes when it is destroyed.
extends Node

const BOSS := preload("res://components/Bosses/Dreadnought/Dreadnought.tscn")

var boss: Node2D = null
var bossDefeated := false


func start() -> void:
	bossDefeated = false
	boss = BOSS.instantiate()
	boss.position = Vector2(960, -320)
	boss.destroyed.connect(_on_boss_destroyed)
	add_child(boss)
	var t := boss.create_tween()
	t.tween_property(boss, "position", Vector2(960, 230), 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(boss.start_fight)


func update(_delta: float) -> bool:
	return bossDefeated


func exit() -> void:
	pass


func _on_boss_destroyed() -> void:
	bossDefeated = true
	boss.queue_free()
