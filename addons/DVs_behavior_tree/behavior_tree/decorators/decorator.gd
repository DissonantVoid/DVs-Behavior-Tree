@tool
@icon("res://addons/DVs_behavior_tree/icons/decorator.svg")
class_name BTDecorator
extends "res://addons/DVs_behavior_tree/behavior_tree/branch.gd"

## Base class for decorators, which are nodes that take a single node child and modify its status.

func enter():
	super()
	# find first valid child
	var valid_child : BTNode = _get_next_valid_child()
	if valid_child:
		_active_child = valid_child

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super()
	if get_valid_children().size() != 1:
		warnings.append("Decorators must have exactly one BTNode child")
	return warnings
