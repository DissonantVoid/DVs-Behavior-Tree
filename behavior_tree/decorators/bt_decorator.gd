@tool
class_name BtDecorator
extends "res://behavior_tree/bt_node.gd"

var _active_child : BtNode = null

func enter():
	if get_child_count() > 0:
		_active_child = get_child(0)
		_active_child.enter()

func exit(is_interrupted : bool):
	if _active_child:
		_active_child.exit(is_interrupted)
		_active_child = null

func _get_configuration_warnings() -> PackedStringArray:
	if get_child_count() != 1 || get_child(0) is not BtNode:
		return ["Decorators must have exactly one child"]
	return []
