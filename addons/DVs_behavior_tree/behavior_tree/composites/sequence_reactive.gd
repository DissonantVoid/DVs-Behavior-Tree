@tool
class_name BTSequenceReactive
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/composite.gd"

# TODO: better description, same for selector_reactive
## Similar to the normal sequence except when a child returns running
## this will start over from the first child and return running. The sequence is reactive
## in the sense that it rechecks previous children if a long running child is active (move_to for example)
## reacting to any previous child having a failure status.

func tick(delta : float) -> Status:
	super(delta)
	if _active_child == null: return Status.failure
	
	var status : Status = _active_child.tick(delta)
	if status == Status.running:
		# start over
		_active_child.exit(true)
		_active_child = _get_next_valid_child()
		return Status.running
		
	elif status == Status.success:
		# run next child
		var next_child : BTNode = _get_next_valid_child(_active_child.get_index())
		if next_child == null:
			# ran all children
			return Status.success
		else:
			# next child
			_active_child.exit(false)
			_active_child = next_child
			_active_child.enter()
			return Status.running
		
	elif status == Status.failure:
		return Status.failure
	
	return Status.undefined
