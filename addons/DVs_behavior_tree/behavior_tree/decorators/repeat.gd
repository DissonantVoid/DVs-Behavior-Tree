@tool
class_name BTRepeat
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

## Continues to tick child for a certain number of ticks, can optionally be set to stop
## and return success if a certain status is returned. If child returns running, it will not count that tick.

## Continues to tick child and return running until the target status is returned,
## can optionally have a maximum number of tries after which it will return success.

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

func tick(delta : float) -> Status:
	super(delta)
	if _active_child == null: return Status.failure
	
	var child_status : Status = _active_child.tick(delta)
	if stop_on_status && child_status == status:
		return Status.success
	
	if child_status != Status.running:
		if max_tries > 0:
			_tried += 1
			if _tried == max_tries:
				return Status.success
			else:
				# next tick
				_active_child.exit(false)
				_active_child.enter()
	
	return Status.running

func _validate_property(property : Dictionary):
	if stop_on_status == false && property["name"] == "status":
		property.usage = PROPERTY_USAGE_NO_EDITOR
