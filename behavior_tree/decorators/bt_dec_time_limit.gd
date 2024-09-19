@tool
class_name BtDecTimeLimit
extends "res://behavior_tree/decorators/bt_decorator.gd"

@export var max : float = 1.0 :
	set(value):
		value = max(value, 0.05)
		if value >= min:
			max = value
@export var min : float = 1.0 :
	set(value):
		value = max(value, 0.05)
		if value <= max:
			min = value

@onready var _timer : Timer = $Timer

func enter():
	super()
	_timer.wait_time = randf_range(min, max)
	_timer.start()

func exit(is_interrupted : bool):
	super(is_interrupted)
	_timer.stop()

func tick(delta : float) -> Status:
	super(delta)
	if _active_child == null: return Status.failure
	if _timer.is_stopped():
		return Status.failure
	
	return _active_child.tick(delta)
