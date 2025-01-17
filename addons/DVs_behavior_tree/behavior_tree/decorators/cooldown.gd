@tool
@icon("res://addons/DVs_behavior_tree/icons/cooldown.svg")
class_name BTCooldown
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

## If child returns success or failure the cooldown will start preventing child from
## ticking again until a certain number of ticks occures,
## while the cooldown is active it will return the last status that the child has returned before the cooldown.

## The cooldown in ticks.
@export var tick_cooldown : int :
	set(value):
		tick_cooldown = max(value, 2)
		_ticked = tick_cooldown
## If true, the internal tick counter will reset when this node is exited.
@export var reset_on_exit : bool = true

var _ticked : int
var _last_status : Status = Status.running

func enter():
	super()
	
	if _active_child:
		_active_child.enter()

func exit(is_interrupted : bool):
	super(is_interrupted)
	if reset_on_exit: _ticked = tick_cooldown

func tick(delta : float):
	super(delta)
	if _active_child == null:
		_set_status(Status.failure)
		return
	
	if _last_status == Status.running || _ticked == tick_cooldown:
		_active_child.tick(delta)
		var status : Status = _active_child.get_status()
		_last_status = status
		_ticked = 0
		_set_status(status)
	else:
		_ticked += 1
		_set_status(_last_status)
