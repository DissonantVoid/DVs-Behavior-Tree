@tool
@icon("res://addons/DVs_behavior_tree/icons/fallback.svg")
class_name BTFallback
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/composite.gd"

## Ticks its children from left to right, if a child fails it ticks the next child,
## otherwise returns the child's status. Can be thought of as an "OR" node in that it only
## executes the next child if the previous child fails.

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
		_set_status(Status.success)
	
	elif status == Status.failure:
		# run next child
		var next_child : BTNode = _get_next_valid_child(_active_child.get_index())
		if next_child == null:
			# ran all children
			_set_status(Status.success)
		else:
			# next child
			_active_child.exit(false)
			_active_child = next_child
			_active_child.enter()
			_set_status(Status.running)
