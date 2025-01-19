# meta-default: true
# meta-description: Base template for composite attachments
extends _BASE_

func parent_entered():
	super()

func parent_exiting(is_interrupted : bool):
	super(is_interrupted)

func tick(delta : float):
	super(delta)