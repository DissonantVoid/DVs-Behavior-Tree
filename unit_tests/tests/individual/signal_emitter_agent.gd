extends Node

signal a
signal b(a : String, b : int, c : Dictionary)

var a_count : int = 0
var b_count : int = 0


func _on_a():
	a_count += 1

func _on_b(a : String, b : int, c : Dictionary):
	b_count += 1
