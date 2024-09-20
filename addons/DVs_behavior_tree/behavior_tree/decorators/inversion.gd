@tool
class_name BTInversion
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

func tick(delta : float) -> Status:
	super(delta)
	if _active_child == null: return Status.failure
	
	var status : Status = _active_child.tick(delta)
	if status == Status.running:
		return Status.running
	elif status == Status.success:
		return Status.failure
	elif status == Status.failure:
		return Status.success
	
	return Status.undefined
