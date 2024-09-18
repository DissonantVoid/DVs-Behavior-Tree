@tool
class_name BtDecorator
extends "res://behavior_tree/bt_node.gd"

var _active_child : BtNode = null

func enter():
	super()
	# find first valid child
	var first_child : Node = get_child(0)
	if get_child_count() > 0 && first_child is BtLeaf:
		_active_child = first_child
		_active_child.enter()

func exit(is_interrupted : bool):
	super(is_interrupted)
	if _active_child:
		_active_child.exit(is_interrupted)
		_active_child = null

func _get_configuration_warnings() -> PackedStringArray:
	if get_child_count() != 1 || get_child(0) is not BtLeaf:
		return ["Decorators must have exactly one leaf child, any other children will be ignored"]
	return []
