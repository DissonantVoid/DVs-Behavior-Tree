# meta-default: true
# meta-description: Base template for Decorators
extends _BASE_

func enter():
	super()

func exit(is_interrupted : bool):
	super(is_interrupted)

func tick(delta : float):
	super(delta)

  if _active_child == null:
		_set_status(Status.failure)
		return
	
	_set_status(Status.undefined)