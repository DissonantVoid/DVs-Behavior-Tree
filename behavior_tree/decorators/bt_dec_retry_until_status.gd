extends "res://behavior_tree/decorators/bt_decorator.gd"

@export var status : StatusShort
## if true when the child returns a status of running the tried counter will not increment
@export var ignore_running_status : bool = false
@export var max_tries : int = 0 :
	set(value):
		max_tries = max(value, 0)

var _tried : int = 0

func enter():
	super()
	_tried = 0

func tick(delta : float) -> Status:
	if _active_child == null: return Status.failure
	
	var status : Status = _active_child.tick(delta)
	
	if (status == Status.success && status == 0 ||
	status == Status.failure && status == 0):
		return Status.success
	
	if max_tries > 0 && (status != Status.running or ignore_running_status):
		_tried += 1
		if _tried == max_tries:
			return Status.success
	
	return Status.running
