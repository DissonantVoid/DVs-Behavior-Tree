@tool
class_name BTCooldown
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

# as soon as child returns success or failure we ignore ticks for tick_every
# used order to not run expensive operations every tick

@export var tick_every : int :
	set(value):
		tick_every = max(value, 2)
		_ticked = tick_every

var _ticked : int
var _last_status : Status = Status.running

func tick(delta : float) -> Status:
	super(delta)
	if _active_child == null: return Status.failure
	
	if _last_status == Status.running || _ticked == tick_every:
		var status : Status = _active_child.tick(delta)
		_last_status = status
		_ticked = 0
		
		return status
	else:
		_ticked += 1
		return _last_status
