extends BTAction

const _speed : float = 140.0
const _min_success_distance : float = 32.0

func enter():
	super()
	
	behavior_tree.agent.say("Awhooooooo!")

func tick(delta : float):
	super(delta)
	
	var target : Node2D = get_tree().current_scene.target
	var agent := behavior_tree.agent
	var direction : Vector2 = (target.global_position - agent.global_position).normalized()
	agent.global_position += direction * _speed * delta
	
	if agent.global_position.distance_to(target.global_position) <= _min_success_distance:
		_set_status(Status.success)
		return
	
	_set_status(Status.running)
