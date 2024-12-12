# meta-default: true
# meta-description: Base template for composite attachments
extends _BASE_

# called when the parent composite is entered
func parent_entered():
	super()

# called when the parent composite is exited
func parent_exiting():
	super()

# called every parent tick by default, tick rate can be customized 
func _tick(delta : float):
	pass