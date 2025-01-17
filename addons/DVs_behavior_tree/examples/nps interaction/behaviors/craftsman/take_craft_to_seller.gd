extends BTAction

func tick(delta : float):
	super(delta)
	
	var agent := behavior_tree.agent
	var stock : Marker2D = get_tree().current_scene.seller_stock
	var direction : Vector2 =\
		(stock.global_position - agent.global_position).normalized()
	agent.position += direction * agent.speed * delta
	
	if agent.global_position.distance_to(stock.global_position) <= agent.min_distance_to_target:
		var craft := Sprite2D.new()
		craft.texture = load("res://addons/DVs_behavior_tree/icons/force_status.svg")
		get_tree().current_scene.crafts_container.add_child(craft)
		craft.global_position = stock.global_position
		
		_set_status(Status.success)
	else:
		_set_status(Status.running)
