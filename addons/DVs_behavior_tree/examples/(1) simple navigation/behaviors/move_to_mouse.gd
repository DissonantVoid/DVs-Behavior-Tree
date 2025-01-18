extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/action.gd"

const _max_distance : float = 100.0
const _speed : float = 200.0

func tick(delta : float):
	super(delta)
	var mouse_pos : Vector2 = behavior_tree.agent.get_global_mouse_position()
	var distance : Vector2 = mouse_pos - behavior_tree.agent.global_position
	if distance.length() >= _max_distance:
		_set_status(Status.failure)
		return
	
	behavior_tree.agent.global_position +=\
		distance.normalized() * _speed * delta
	
	_set_status(Status.running)
