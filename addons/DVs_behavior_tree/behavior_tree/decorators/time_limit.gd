@tool
class_name BTTimeLimit
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

## Fails if child fails to return success or failure before the timout,
## otherwise returns child's status.

## Minimum wait time.
@export var min : float = 1.0 :
	set(value):
		min = max(value, 0.05)
		if value > max:
			max = value
## Maximum wait time.
@export var max : float = 1.0 :
	set(value):
		max = max(value, 0.05)
		if value < min:
			min = value

var _enter_time : float
var _time : float

func enter():
	super()
	_enter_time = Time.get_ticks_msec()
	_time = randf_range(min, max)

func exit(is_interrupted : bool):
	super(is_interrupted)

func tick(delta : float) -> Status:
	super(delta)
	if _active_child == null: return Status.failure
	
	if (Time.get_ticks_msec() - _enter_time) / 1000.0 >= _time:
		return Status.failure
	return _active_child.tick(delta)
