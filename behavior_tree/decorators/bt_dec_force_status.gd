extends "res://behavior_tree/decorators/bt_decorator.gd"

@export var status : StatusShort

func tick(delta : float) -> Status:
	if status == 0:
		return Status.success
	return Status.failure
