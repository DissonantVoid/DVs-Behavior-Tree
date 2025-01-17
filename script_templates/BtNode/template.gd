# meta-default: true
# meta-description: Base template for behavior nodes
extends _BASE_

# called before the first tick, use for initialization
func enter():
	super()

# called after the last tick
# if is_interrupted, this node was interrupted while it was running
func exit(is_interrupted : bool):
	super(is_interrupted)

# called after enter() everytime the tree is ticked, use for processing node logic
func tick(delta : float):
	super(delta)
	
	# set status
	_set_status(Status.undefined)