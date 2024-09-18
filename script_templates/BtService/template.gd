# meta-default: true
# meta-description: Base template for behavior nodes
extends _BASE_

# Called when the parent composite is entered
func parent_entered():
	super()

# Called when the parent composite is exited
func parent_exiting():
	super()

# Called as long as the parent hasn't exited, the tick rate can be different than other behavior nodes 
func _tick(delta : float):
	pass