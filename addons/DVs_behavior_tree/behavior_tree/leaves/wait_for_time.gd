@tool
@icon("res://addons/DVs_behavior_tree/icons/wait_for_time.svg")
class_name BTWaitForTime
extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/action.gd"

## Returns running for a certain time before returning success.

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

func tick(delta : float):
	super(delta)
	if (Time.get_ticks_msec() - _enter_time) / 1000.0 >= _time:
		_set_status(Status.success)
	else:
		_set_status(Status.running)
