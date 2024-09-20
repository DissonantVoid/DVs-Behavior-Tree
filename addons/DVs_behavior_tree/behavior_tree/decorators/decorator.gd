@tool
class_name BTDecorator
extends "res://addons/DVs_behavior_tree/behavior_tree/branch.gd"

func enter():
	super()
	# find first valid child
	var valid_child : BTNode = _get_next_valid_child()
	if valid_child:
		_active_child = valid_child
		_active_child.enter()

func _get_configuration_warnings() -> PackedStringArray:
	if _get_valid_children().size() != 1:
		return ["Decorators must have exactly one BTNode child"]
	return []
