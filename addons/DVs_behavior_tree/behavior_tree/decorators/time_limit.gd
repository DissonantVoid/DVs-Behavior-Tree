@tool
@icon("res://addons/DVs_behavior_tree/icons/time_limit.svg")
class_name BTTimeLimit
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

## Fails if child fails to return success or failure before the timeout,
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
	
	if _active_child:
		_active_child.enter()

func exit(is_interrupted : bool):
	super(is_interrupted)

func tick(delta : float):
	super(delta)
	if _active_child == null:
		_set_status(Status.failure)
		return
	
	if (Time.get_ticks_msec() - _enter_time) / 1000.0 >= _time:
		_set_status(Status.failure)
	else:
		_active_child.tick(delta)
		_set_status(_active_child.get_status())
