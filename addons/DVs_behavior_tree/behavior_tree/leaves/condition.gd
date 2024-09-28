@tool
@icon("res://addons/DVs_behavior_tree/icons/condition.svg")
class_name BTCondition
extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/leaf.gd"

## Acts as a boolean, checks some condition and returns either success or failure.

func get_status() -> Status:
	if _status == Status.running:
		push_warning("Condition nodes should return either success or failure")
	return super()
