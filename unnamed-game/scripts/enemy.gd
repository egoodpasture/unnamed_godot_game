extends Node2D

signal died

func is_dead():
	died.emit()
	queue_free()
