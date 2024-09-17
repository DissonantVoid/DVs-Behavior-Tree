extends "res://behavior_tree/leaves/bt_action.gd"

var _random_pos : Vector2
const _speed : float = 120.0
const _min_distance : float = 16.0

func enter():
	_random_pos = Vector2(
		randf_range(0.0, get_viewport().size.x),
		randf_range(0.0, get_viewport().size.y)
	)

func tick(delta : float) -> Status:
	var direction : Vector2 = (_random_pos - behavior_tree.agent.global_position).normalized()
	behavior_tree.agent.global_position += direction * _speed * delta
	
	if _random_pos.distance_to(behavior_tree.agent.global_position) <= _min_distance:
		return Status.success
	
	return Status.running
