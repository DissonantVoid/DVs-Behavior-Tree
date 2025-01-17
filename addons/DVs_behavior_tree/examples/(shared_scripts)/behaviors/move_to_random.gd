extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/action.gd"

var _random_pos : Vector2
const _speed : float = 120.0
const _min_distance : float = 16.0

func enter():
	super()
	_random_pos = Vector2(
	randf_range(0.0, get_viewport().size.x),
	randf_range(0.0, get_viewport().size.y)
	)

func tick(delta : float):
	super(delta)
	var direction : Vector2 = (_random_pos - behavior_tree.agent.global_position).normalized()
	behavior_tree.agent.global_position += direction * _speed * delta

	if _random_pos.distance_to(behavior_tree.agent.global_position) <= _min_distance:
		_set_status(Status.success)
	else:
		_set_status(Status.running)
