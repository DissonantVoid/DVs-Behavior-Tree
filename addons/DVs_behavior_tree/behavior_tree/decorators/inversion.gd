@tool
class_name BTInversion
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

## Takes the child's status and inverts it if it's success or failure.

func tick(delta : float):
	super(delta)
	if _active_child == null:
		_set_status(Status.failure)
		return
	
	_active_child.tick(delta)
	var status : Status = _active_child.get_status()
	if status == Status.running:
		_set_status(Status.running)
	elif status == Status.success:
		_set_status(Status.failure)
	elif status == Status.failure:
		_set_status(Status.success)
