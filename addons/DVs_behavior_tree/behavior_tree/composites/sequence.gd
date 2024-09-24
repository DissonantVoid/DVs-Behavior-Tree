@tool
@icon("res://addons/DVs_behavior_tree/icons/sequence.svg")
class_name BTSequence
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/composite.gd"

## Ticks its children from first to last, if the child succeeds it ticks the next child,
## otherwise returns the child's status. Can be thought of as an "AND" node in that it only
## executes the next child if the previous child succeeds.
## example: an NPC that needs to open a door: sequence -> has key, go to door, open door, enter.

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
