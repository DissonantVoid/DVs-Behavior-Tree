extends BTAction

var _tween : Tween
const _tween_time : float = 1.5

func enter():
	super()
	
	get_tree().current_scene.goods_container.get_child(0).queue_free()
	
	_tween = create_tween()
	_tween.tween_property(behavior_tree.agent, "scale:x", 1.5, _tween_time/2.0)
	_tween.tween_property(behavior_tree.agent, "scale:x", 1.0, _tween_time/2.0)

func exit(is_interrupted : bool):
	super(is_interrupted)

func tick(delta ):
	super(delta)
	
	if _tween.is_running():
		_set_status(Status.running)
	else:
		_set_status(Status.success)
