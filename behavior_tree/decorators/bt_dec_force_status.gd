extends "res://behavior_tree/decorators/bt_decorator.gd"

@export_enum("success", "failure") var status : int = 0

func tick(delta : float) -> Status:
	if status == 0:
		return Status.success
	return Status.failure
