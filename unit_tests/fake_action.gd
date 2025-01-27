extends BTAction

@export var tick_status : Status = Status.undefined

var _ticks_counter : int = 0

# this node is a paid actor
func tick(delta : float):
	super(delta)
	_set_status(tick_status)
	_ticks_counter += 1

func get_ticks() -> int:
	return _ticks_counter

func reset_ticks():
	_ticks_counter = 0
