extends BTAction

func tick(delta : float):
	super(delta)
	
	var agent := behavior_tree.agent
	var sell_point : Marker2D = get_tree().current_scene.sell_point
	var direction : Vector2 =\
		(sell_point.global_position - agent.global_position).normalized()
	agent.position += direction * agent.speed * delta
	
	if agent.global_position.distance_to(sell_point.global_position) <= agent.min_distance_to_target:
		_set_status(Status.success)
	else:
		_set_status(Status.running)
