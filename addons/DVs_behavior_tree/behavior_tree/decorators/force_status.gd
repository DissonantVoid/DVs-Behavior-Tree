@tool
class_name BTForceStatus
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

@export var status : StatusBinary = StatusBinary.success

func tick(delta : float) -> Status:
	super(delta)
	if status == StatusBinary.success:
		return Status.success
	return Status.failure
