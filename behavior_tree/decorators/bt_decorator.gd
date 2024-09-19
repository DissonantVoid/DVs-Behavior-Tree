@tool
class_name BtDecorator
extends "res://behavior_tree/bt_branch.gd"

func enter():
	super()
	# find first valid child
	var valid_child : BtNode = _get_next_valid_child()
	if valid_child:
		_active_child = valid_child
		_active_child.enter()

func _get_configuration_warnings() -> PackedStringArray:
	if _get_valid_children().size() != 1:
		return ["Decorators must have exactly one BtNode child"]
	return []
