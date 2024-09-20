@tool
class_name BTRepeatUntilStatus
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

@export var status : StatusBinary
## 0 = infinite
@export var max_tries : int = 0 :
	set(value):
		max_tries = max(value, 0)

var _tried : int = 0

func enter():
	super()
	_tried = 0

func tick(delta : float) -> Status:
	super(delta)
	if _active_child == null: return Status.failure
	
	var child_status : Status = _active_child.tick(delta)
	
	if (child_status == Status.success && status == StatusBinary.success ||
	child_status == Status.failure && status == StatusBinary.failure):
		return Status.success
	
	if max_tries > 0:
		_tried += 1
		if _tried == max_tries:
			return Status.success
	
	return Status.running
