extends BTAction

const _min_distance : float = 5.0

func enter():
	super()
	
	behavior_tree.agent.move_to(behavior_tree.blackboard["closest_obstacle"].global_position)

func exit(is_interrupted : bool):
	super(is_interrupted)
	
	behavior_tree.agent.stop_moving()

func tick(delta ):
	super(delta)
	
	var distance : float = behavior_tree.agent.global_position.distance_to(
		behavior_tree.blackboard["closest_obstacle"].global_position
	)
	if distance <= _min_distance:
		_set_status(Status.success)
	else:
		_set_status(Status.running)
