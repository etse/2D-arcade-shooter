extends Node

signal score_changed
@export var score: int = 0

func add_score(points: int):
	score = score + points
	emit_signal("score_changed", score)
