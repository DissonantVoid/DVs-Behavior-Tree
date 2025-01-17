# meta-default: true
# meta-description: Base template for Decorators
extends _BASE_

# called before the first tick, use for initialization
func enter():
	super() # this will set _active_child to the first child

# called after the last tick
# if is_interrupted, this node was interrupted while it was running
func exit(is_interrupted : bool):
	super(is_interrupted) # this will cleanup _active_child

# called after enter() everytime the tree is ticked, use for processing node logic
func tick(delta : float):
	super(delta)

  # ensure that the decorator has a child
  if _active_child == null:
		_set_status(Status.failure)
		return
	
	# set status
	_set_status(Status.undefined)