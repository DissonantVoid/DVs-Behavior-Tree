@tool
@icon("res://addons/DVs_behavior_tree/icons/inversion.svg")
class_name BTInversion
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

## Inverts the status of its child.

func enter():
	super()
	
	if _active_child:
		_active_child.enter()

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
