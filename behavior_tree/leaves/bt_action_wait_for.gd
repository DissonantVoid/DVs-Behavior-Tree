@tool
extends "res://behavior_tree/leaves/bt_action.gd"

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
	_timer.wait_time = randf_range(min, max)
	_timer.start()

func exit(is_interrupted : bool):
	_timer.stop()

func tick(delta : float) -> Status:
	if _timer.is_stopped():
		return Status.success
	return Status.running
