# meta-default: true
# meta-description: Base template for behavior nodes
extends _BASE_

# Called before the node is ticked, use for initialization
func enter():
	pass

# Called after the last tick, use for de-initialization
# is_interrupted refers to whether this exited because the parent was satisfied with the last tick status
# or because it was interrupted by a higher priority node
func exit(is_interrupted : bool):
	pass

# Called after enter() everytime the tree is ticked, use for processing node logic
func tick(delta : float) -> Status:
	return Status.undefined