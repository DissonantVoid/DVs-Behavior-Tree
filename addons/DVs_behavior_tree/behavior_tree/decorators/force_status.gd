@tool
@icon("res://addons/DVs_behavior_tree/icons/force_status.svg")
class_name BTForceStatus
extends "res://addons/DVs_behavior_tree/behavior_tree/decorators/decorator.gd"

## Forces success or failure to be returned.

## The status to force.
@export var status : StatusBinary = StatusBinary.success

func enter():
	super()
	
	if _active_child:
		_active_child.enter()

func tick(delta : float):
	super(delta)
	_set_status(status as Status)
