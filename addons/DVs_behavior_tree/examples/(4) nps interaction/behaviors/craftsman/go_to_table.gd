extends BTAction

func tick(delta : float):
	super(delta)
	
	var agent := behavior_tree.agent
	var table : Marker2D = get_tree().current_scene.craft_table
	var direction : Vector2 =\
		(table.global_position - agent.global_position).normalized()
	agent.position += direction * agent.speed * delta
	
	if agent.global_position.distance_to(table.global_position) <= agent.min_distance_to_target:
		_set_status(Status.success)
	else:
		_set_status(Status.running)
