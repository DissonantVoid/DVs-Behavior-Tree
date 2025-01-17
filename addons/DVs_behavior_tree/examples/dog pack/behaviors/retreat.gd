extends BTAction

const _speed : float = 200.0
const _min_success_distance : float = 32.0
const _move_away_distance : float = 250.0

var _target_position : Vector2

func enter():
	super()
	
	var target : Node2D = get_tree().current_scene.target
	var direction_away : Vector2 = (behavior_tree.agent.global_position - target.global_position).normalized()
	_target_position = target.global_position + direction_away * _move_away_distance

func exit(is_interrupted : bool):
	super(is_interrupted)
	
	behavior_tree.global_blackboard.erase("current_attack_dog")

func tick(delta : float):
	super(delta)
	
	var agent := behavior_tree.agent
	var direction : Vector2 = (_target_position - agent.global_position).normalized()
	agent.global_position += direction * _speed * delta
	
	if agent.global_position.distance_to(_target_position) <= _min_success_distance:
		_set_status(Status.success)
		return
	
	_set_status(Status.running)
