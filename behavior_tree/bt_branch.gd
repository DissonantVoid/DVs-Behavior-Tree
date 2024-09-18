@tool
class_name BtBranch
extends "res://behavior_tree/bt_node.gd"

var _active_child : BtNode = null

func exit(is_interrupted : bool):
	super(is_interrupted)
	if _active_child:
		_active_child.exit(is_interrupted)
		_active_child = null

func get_active_child() -> BtNode:
	return _active_child

func force_pick_child(child : BtNode):
	# called by tree, must be called after enter() and before tick()
	# forces branch to pick one of its children instead of letting it do its thing
	# used for conditional abort support but has potential to be used
	# for future debugging and unit testing
	if child.get_parent() != self:
		push_error("She says I am the one🎵 but the kid is not my son🎵")
		return
	
	if _active_child:
		_active_child.exit(true)
		_active_child = null
	
	_active_child = child
	child.enter()
