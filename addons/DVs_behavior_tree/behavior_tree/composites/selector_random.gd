@tool
class_name BTSelectorRandom
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/random_composite.gd"

func tick(delta : float) -> Status:
	super(delta)
	if _active_child == null || _weight_format_valid == false:
		return Status.failure
	
	var status : Status = _active_child.tick(delta)
	if status == Status.running:
		return Status.running
	
	elif status == Status.success:
		return Status.success
	
	elif status == Status.failure:
		# run next random child
		_active_child.exit(false)
		_active_child = _pick_rand_child()
		_active_child.enter()
		return Status.running
	
	return Status.undefined
