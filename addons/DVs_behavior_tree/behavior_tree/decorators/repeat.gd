@tool
@icon("res://addons/DVs_behavior_tree/icons/repeat.svg")
class_name BTRepeat
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

## Ticks child a certain number of times, can optionally be set to return
## success if a certain status is returned. If child returns running, it will not count that tick.

## If the status is return by the child, this returns success.
@export var stop_on_status : bool = false :
	set(value):
		stop_on_status = value
		notify_property_list_changed()
## The target status.
@export var status : StatusBinary
## The maximum times this waits for child to return the target status, if 0 it will run indefinitely.
@export var max_tries : int = 0 :
	set(value):
		max_tries = max(value, 0)

var _tried : int = 0

func enter():
	super()
	_tried = 0
	if _active_child:
		_active_child.enter()

func tick(delta : float):
	super(delta)
	if _active_child == null:
		_set_status(Status.failure)
		return
	
	_active_child.tick(delta)
	var child_status : Status = _active_child.get_status()
	if stop_on_status && child_status == status:
		_set_status(Status.success)
		return
	
	if child_status != Status.running:
		if max_tries > 0:
			_tried += 1
			if _tried == max_tries:
				_set_status(Status.success)
			else:
				# next tick
				_active_child.exit(false)
				_active_child.enter()
				_set_status(Status.running)
	else:
		_set_status(Status.running)

func _validate_property(property : Dictionary):
	if stop_on_status == false && property["name"] == "status":
		property.usage = PROPERTY_USAGE_NO_EDITOR
