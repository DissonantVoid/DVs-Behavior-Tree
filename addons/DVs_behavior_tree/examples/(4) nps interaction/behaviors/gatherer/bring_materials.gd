extends BTAction

func tick(delta : float):
	super(delta)
	
	var agent := behavior_tree.agent
	var table : Marker2D = get_tree().current_scene.craft_table
	var direction : Vector2 =\
		(table.global_position - agent.global_position).normalized()
	agent.position += direction * agent.speed * delta
	
	if agent.global_position.distance_to(table.global_position) <= agent.min_distance_to_target:
		var goods := Sprite2D.new()
		goods.texture = load("res://addons/DVs_behavior_tree/icons/leaf.svg")
		get_tree().current_scene.goods_container.add_child(goods)
		goods.global_position = table.global_position
		
		_set_status(Status.success)
	else:
		_set_status(Status.running)
