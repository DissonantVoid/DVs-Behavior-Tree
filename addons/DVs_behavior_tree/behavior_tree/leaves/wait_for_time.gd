@tool
class_name BTWaitForTime
extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/action.gd"

## Returns running for a certain time before return success.
## If min != max the time will be randomized.

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
	if _timer.is_stopped():
		return Status.success
	return Status.running
