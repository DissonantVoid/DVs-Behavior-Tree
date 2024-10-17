@tool
@icon("res://addons/DVs_behavior_tree/icons/condition.svg")
class_name BTCondition
extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/leaf.gd"

## Base class for conditions. Acts as a boolean, checks some condition and returns either success or failure.

func _set_status(status : Status):
	super(status)
	if _status == Status.running:
		push_warning("Condition nodes should return either success or failure")
