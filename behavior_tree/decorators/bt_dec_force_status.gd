@tool
class_name BtDecForceStatus
extends "res://behavior_tree/decorators/bt_decorator.gd"

@export var status : StatusBinary = StatusBinary.success

func tick(delta : float) -> Status:
	super(delta)
	if status == StatusBinary.success:
		return Status.success
	return Status.failure
