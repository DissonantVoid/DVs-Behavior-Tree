extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/condition.gd"

func tick(delta : float):
	super(delta)
	
	if behavior_tree.agent.detection_area.get_overlapping_areas().size() > 0:
		_set_status(Status.success)
	else:
		_set_status(Status.failure)
