extends "res://behavior_tree/leaves/bt_action.gd"

const _min_distance : float = 16.0
const _max_distance : float = 100.0
const _speed : float = 200.0

func tick(delta : float) -> Status:
	super(delta)
	var mouse_pos : Vector2 = behavior_tree.agent.get_global_mouse_position()
	var distance : Vector2 = mouse_pos - behavior_tree.agent.global_position
	if distance.length() <= _min_distance:
		return Status.success
	elif distance.length() >= _max_distance:
		return Status.failure
	
	behavior_tree.agent.global_position +=\
		distance.normalized() * _speed * delta
	
	return Status.running
