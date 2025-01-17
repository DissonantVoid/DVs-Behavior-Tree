extends BTCondition

func tick(delta : float):
	super(delta)
	
	var obstacles : Array[Node] = get_tree().current_scene.get_obstacles()
	if obstacles:
		var agent := behavior_tree.agent
		
		var closest_obstacle : Node2D = null
		var closest_obstacle_dist : float = 0.0
		for obstacle : Node2D in obstacles:
			if closest_obstacle == null:
				closest_obstacle = obstacle
				closest_obstacle_dist =\
					agent.global_position.distance_to(obstacle.global_position)
			else:
				var distance : float = agent.global_position.distance_to(obstacle.global_position)
				if distance < closest_obstacle_dist:
					closest_obstacle = obstacle
					closest_obstacle_dist = distance
		
		behavior_tree.blackboard["closest_obstacle"] = closest_obstacle
		_set_status(Status.success)
		return
	
	_set_status(Status.failure)
