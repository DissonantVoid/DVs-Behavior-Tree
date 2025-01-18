extends BTAction

var _offscreen_position : Vector2
const _min_distance : float = 5.0

func enter():
	super()
	
	var view_size : Vector2 = get_viewport().size
	var agent_pos : Vector2 = behavior_tree.agent.global_position
	
	var closest_edge : Vector2
	var closest_edge_distance : float = INF
	for vec : Vector2 in [
		Vector2(0.0, agent_pos.y), Vector2(agent_pos.x, 0),
		Vector2(view_size.x, agent_pos.y), Vector2(agent_pos.x, view_size.y)
	]:
		var distance : float = vec.distance_to(agent_pos)
		if distance < closest_edge_distance:
			closest_edge = vec
			closest_edge_distance = distance
	
	_offscreen_position = closest_edge
	behavior_tree.agent.move_to(_offscreen_position)

func exit(is_interrupted : bool):
	super(is_interrupted)
	
	behavior_tree.agent.stop_moving()

func tick(delta ):
	super(delta)
	
	var distance : float = behavior_tree.agent.global_position.distance_to(
		_offscreen_position
	)
	if distance <= _min_distance:
		_set_status(Status.success)
	else:
		_set_status(Status.running)
