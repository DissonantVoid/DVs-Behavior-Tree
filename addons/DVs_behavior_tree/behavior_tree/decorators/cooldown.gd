@tool
class_name BTCooldown
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

## If child returns success or failure the cooldown will start preventing child from
## ticking again until a certain number of ticks occures,
## while the cooldown is active it will return the last status that the child has returned before the cooldown.
## Mainly used to prevent an expensive condition node from running when it's not nessesary to keep the result up to date.

@export var tick_every : int :
	set(value):
		tick_every = max(value, 2)
		_ticked = tick_every
@export var reset_on_exit : bool = true

var _ticked : int
var _last_status : Status = Status.running

func exit(is_interrupted : bool):
	super(is_interrupted)
	if reset_on_exit: _ticked = tick_every

func tick(delta : float):
	super(delta)
	if _active_child == null:
		_set_status(Status.failure)
		return
	
	if _last_status == Status.running || _ticked == tick_every:
		_active_child.tick(delta)
		var status : Status = _active_child.get_status()
		_last_status = status
		_ticked = 0
		_set_status(status)
	else:
		_ticked += 1
		_set_status(_last_status)
