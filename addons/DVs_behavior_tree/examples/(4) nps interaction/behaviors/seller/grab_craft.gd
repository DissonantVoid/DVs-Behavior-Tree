extends BTAction

func tick(delta : float):
	super(delta)
	
	var agent := behavior_tree.agent
	var stock : Marker2D = get_tree().current_scene.seller_stock
	var direction : Vector2 =\
		(stock.global_position - agent.global_position).normalized()
	agent.position += direction * agent.speed * delta
	
	if agent.global_position.distance_to(stock.global_position) <= agent.min_distance_to_target:
		get_tree().current_scene.crafts_container.get_child(0).queue_free()
		_set_status(Status.success)
	else:
		_set_status(Status.running)
