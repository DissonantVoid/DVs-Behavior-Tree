extends "res://behavior_tree/decorators/bt_decorator.gd"

@export var status : StatusBinary

func tick(delta : float) -> Status:
	super(delta)
	if status == 0:
		return Status.success
	return Status.failure
