extends "res://behavior_tree/decorators/bt_decorator.gd"

## 0 = infinite
@export var repeat_count : int = 0

var _repeated : int = 0

func enter():
	super()
	_repeated = 0

func tick(delta : float) -> Status:
	if _active_child == null: return Status.failure
	
	var status : Status = _active_child.tick(delta)
	if status == Status.running:
		return Status.running
	elif status == Status.failure:
		return Status.failure
		
	elif status == Status.success:
		_repeated += 1
		if _repeated == repeat_count:
			return Status.success
		else:
			return Status.running
	
	# NoT aLl PaThS rEtUrN a VaLuE
	return Status.running
