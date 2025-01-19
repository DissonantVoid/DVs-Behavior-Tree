# meta-default: true
# meta-description: Base template for behavior nodes
extends _BASE_

func enter():
	super()

func exit(is_interrupted : bool):
	super(is_interrupted)

func tick(delta : float):
	super(delta)
	
	_set_status(Status.undefined)