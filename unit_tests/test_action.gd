extends BTAction

@export var tick_status : Status

func tick(delta : float):
	super(delta)
	_set_status(tick_status)
