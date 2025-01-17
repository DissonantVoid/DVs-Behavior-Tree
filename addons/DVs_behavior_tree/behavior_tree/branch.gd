@tool
@icon("res://addons/DVs_behavior_tree/icons/branch.svg")
class_name BTBranch
extends "res://addons/DVs_behavior_tree/behavior_tree/node.gd"

## Base class for all branches (nodes that can have children).

## If true higher priority composites cannot interrupt this branch even if their interrupt_target is set to low_priority or both.
@export var uninterruptible : bool = false

var _active_child : BTNode = null

func exit(is_interrupted : bool):
	super(is_interrupted)
	# NOTE: since active child cleanup is automatically handled for branches
	#       a branch should either let the active child be handled here
	#       or make sure to set it to null if exited manually
	if _active_child:
		_active_child.exit(is_interrupted)
		_active_child = null

func get_active_child() -> BTNode:
	return _active_child

func force_pick_child(child : BTNode):
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

func _is_main_path_variable_changed():
	# by default branches will reflect their is_main_path on their children
	for child : BTNode in get_valid_children():
		child.is_main_path = is_main_path

# utility

func get_valid_children() -> Array[BTNode]:
	var children : Array[BTNode]
	var index : int = -1
	while true:
		var child : BTNode = _get_next_valid_child(index)
		if child == null: break
		else: children.append(child)
		
		index = child.get_index()
	
	return children

func _get_next_valid_child(index : int = -1) -> BTNode:
	var next_index : int = index+1
	while true:
		if get_child_count() <= next_index:
			return null
		var child : Node = get_child(next_index)
		if child is BTNode:
			return child
		
		next_index += 1
	
	return null
