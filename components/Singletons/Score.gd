extends Node

signal score_changed
export var score = 0

func add_score(points: float):
	score = score + points
	emit_signal("score_changed", score)
