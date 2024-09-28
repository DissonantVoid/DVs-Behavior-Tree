extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/condition.gd"

const _min_distance : float = 100.0

func tick(delta : float):
	super(delta)
	
	var mouse_pos : Vector2 = behavior_tree.agent.get_global_mouse_position()
	if (mouse_pos.distance_to( behavior_tree.agent.global_position)
	<= _min_distance):
		_set_status(Status.success)
	else:
		_set_status(Status.failure)
