extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/action.gd"

const _dodge_speed : float = 140.0

func tick(delta : float):
	super(delta)
	
	var areas_in_range : Array[Area2D] =\
		behavior_tree.agent.detection_area.get_overlapping_areas()
	
	if areas_in_range.size() == 0:
		_set_status(Status.success)
	else:
		var average_dodge_dir : Vector2 = Vector2.ZERO
		for area : Area2D in areas_in_range:
			average_dodge_dir += (behavior_tree.agent.global_position - area.global_position).normalized()
		
		average_dodge_dir /= areas_in_range.size()
		
		behavior_tree.agent.position += average_dodge_dir * _dodge_speed * delta
		_set_status(Status.running)
