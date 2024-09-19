@tool
class_name BtBranch
extends "res://behavior_tree/bt_node.gd"

var _active_child : BtNode = null

func exit(is_interrupted : bool):
	super(is_interrupted)
	if _active_child:
		_active_child.exit(is_interrupted)

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

# utility

func _get_next_valid_child(index : int = -1) -> BtNode:
	var next_index : int = index+1
	while true:
		if get_child_count() <= next_index:
			return null
		var child : Node = get_child(next_index)
		if child is BtNode:
			return child
		
		next_index += 1
	
	return null

func _get_valid_children() -> Array[BtNode]:
	var children : Array[BtNode]
	var index : int = -1
	while true:
		var child : BtNode = _get_next_valid_child(index)
		if child == null: break
		else: children.append(child)
		
		index = child.get_index()
	
	return children
