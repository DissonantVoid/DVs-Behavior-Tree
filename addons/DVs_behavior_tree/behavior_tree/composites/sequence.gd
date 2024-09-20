@tool
class_name BTSequence
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/composite.gd"

func tick(delta : float) -> Status:
	super(delta)
	if _active_child == null: return Status.failure
	
	var status : Status = _active_child.tick(delta)
	if status == Status.running:
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
