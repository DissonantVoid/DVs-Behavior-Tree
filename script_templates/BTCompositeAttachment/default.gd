# meta-default: true
# meta-description: Base template for composite attachments
extends _BASE_

# called when the parent composite's enter() is called
func parent_entered():
	super()

# called when the parent composite's exit() is called
# if is_interrupted, the parent was interrupted while it was running
func parent_exiting(is_interrupted : bool):
	super(is_interrupted)

# called every parent tick by default, tick rate can be customized 
func tick(delta : float):
	super(delta)