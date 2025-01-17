extends BTAction

var _circle_end_position : Vector2
const _min_success_distance : float = 32.0

func enter():
	super()
	
	_circle_end_position = behavior_tree.blackboard["circle_end_position"]

func tick(delta : float):
	super(delta)
	
	var agent := behavior_tree.agent
	var direction : Vector2 = (_circle_end_position - agent.global_position).normalized()
	agent.global_position += direction * agent.circulate_speed * delta
	
	if agent.global_position.distance_to(_circle_end_position) <= _min_success_distance:
		_set_status(Status.success)
		return
	
	_set_status(Status.running)
