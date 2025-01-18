extends BTAction

var _tween : Tween
const _tween_time : float = 0.3

func enter():
	super()
	
	# do a flip
	_tween = create_tween()
	_tween.tween_property(behavior_tree.agent, "scale:x", -1.0, _tween_time/2.0)
	_tween.tween_property(behavior_tree.agent, "scale:x", 1.0, _tween_time/2.0)

func tick(delta ):
	super(delta)
	
	if _tween.is_running():
		_set_status(Status.running)
	else:
		behavior_tree.agent.pickup_obstacle(behavior_tree.blackboard["closest_obstacle"])
		_set_status(Status.success)
