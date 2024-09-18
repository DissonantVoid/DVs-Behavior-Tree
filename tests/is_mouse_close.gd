extends "res://behavior_tree/leaves/bt_conditional.gd"

const _min_distance : float = 100.0

func tick(delta : float) -> Status:
	super(delta)
	var mouse_pos : Vector2 = behavior_tree.agent.get_global_mouse_position()
	if (mouse_pos.distance_to( behavior_tree.agent.global_position)
	<= _min_distance):
		return Status.success
	return Status.failure
