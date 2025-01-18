extends BTCondition

func tick(delta ):
	super(delta)
	
	if get_tree().current_scene.materials_container.get_child_count():
		_set_status(Status.success)
	else:
		_set_status(Status.failure)
