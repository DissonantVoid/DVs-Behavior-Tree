@tool
class_name BTForceStatus
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

## Forces success or failure to be returned no matter what the child's status is.

@export var status : StatusBinary = StatusBinary.success

func tick(delta : float):
	super(delta)
	_set_status(Status.success if status == StatusBinary.success else Status.failure)
