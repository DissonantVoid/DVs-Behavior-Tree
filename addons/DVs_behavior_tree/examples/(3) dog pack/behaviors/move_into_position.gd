extends BTAction

const _distance_min : float = 140.0
const _distance_max : float = 350.0
const _max_end_angle_offset : float = PI / 4.0
const _speed : float = 120.0

var _circle_start_position : Vector2
const _min_success_distance : float = 32.0

func enter():
	super()
	
	var target : Node2D = get_tree().current_scene.target
	var random_distance : float = randf_range(_distance_min, _distance_max)
	
	var curr_angle_to_target : float = (behavior_tree.agent.global_position - target.global_position).angle()
	
	var start_angle : float = curr_angle_to_target + randf_range(-_max_end_angle_offset, _max_end_angle_offset)
	var end_angle : float = start_angle + randf_range(-_max_end_angle_offset, _max_end_angle_offset)
	
	behavior_tree.blackboard["circle_end_position"] =\
		target.global_position + Vector2(random_distance, 0.0).rotated(end_angle)
	
	_circle_start_position = target.global_position + Vector2(random_distance, 0.0).rotated(start_angle)

func tick(delta : float):
	super(delta)
	
	var agent := behavior_tree.agent
	var direction : Vector2 = (_circle_start_position - agent.global_position).normalized()
	agent.global_position += direction * _speed * delta
	
	if agent.global_position.distance_to(_circle_start_position) <= _min_success_distance:
		_set_status(Status.success)
		return
	
	_set_status(Status.running)
