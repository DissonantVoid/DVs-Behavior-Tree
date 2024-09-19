@tool
class_name BtCompRandSelector
extends "res://behavior_tree/composites/bt_comp_random.gd"

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
