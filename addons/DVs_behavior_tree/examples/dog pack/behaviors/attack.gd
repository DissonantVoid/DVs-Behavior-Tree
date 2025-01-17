extends BTAction

var _tween : Tween
const _tween_time : float = 0.8

func enter():
	super()
	
	_tween = create_tween()
	_tween.tween_property(behavior_tree.agent, "scale:x", 2.0, _tween_time/2.0)
	_tween.tween_property(behavior_tree.agent, "scale:x", 1.0, _tween_time/2.0)
	
	behavior_tree.agent.say("chomp!")

func exit(is_interrupted : bool):
	super(is_interrupted)

func tick(delta ):
	super(delta)
	
	if _tween.is_running():
		_set_status(Status.running)
	else:
		_set_status(Status.success)
