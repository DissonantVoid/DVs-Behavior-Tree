# meta-default: true
# meta-description: Base template for behavior nodes
extends _BASE_

# Called before the node is ticked, use for initialization
func enter():
	super()

# Called after the last tick, use for de-initialization
# is_interrupted refers to whether this exited because it retuend properly after last tick
# or because it was interrupted by another node
func exit(is_interrupted : bool):
	super(is_interrupted)

# Called after enter() everytime the tree is ticked, use for processing node logic
func tick(delta : float):
	super(delta)
	_set_status(Status.undefined)