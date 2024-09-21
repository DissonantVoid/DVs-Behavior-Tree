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
