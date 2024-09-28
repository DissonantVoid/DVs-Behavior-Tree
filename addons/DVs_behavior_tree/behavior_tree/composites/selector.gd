@tool
@icon("res://addons/DVs_behavior_tree/icons/selector.svg")
class_name BTSelector
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/composite.gd"

## Ticks its children from first to last, if the child fails it ticks the next child,
## otherwise returns the child's status. Can be thought of as an "OR" node in that it only
## executes the next child if the previous child fails.
## example: an NPC that determines whether to go outside or go to sleep depending on the time of day:
## selector -> day routine, night routine.

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
