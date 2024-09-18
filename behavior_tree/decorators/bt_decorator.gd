@tool
class_name BtDecorator
extends "res://behavior_tree/bt_branch.gd"

func enter():
	super()
	# find first valid child
	var first_child : Node = get_child(0)
	if get_child_count() > 0 && first_child is BtNode:
		_active_child = first_child
		_active_child.enter()

func exit(is_interrupted : bool):
	super(is_interrupted)

func _get_configuration_warnings() -> PackedStringArray:
	if get_child_count() != 1 || get_child(0) is not BtNode:
		return ["Decorators must have exactly one leaf child, any other children will be ignored"]
	return []
