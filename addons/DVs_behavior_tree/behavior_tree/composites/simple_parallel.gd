@tool
class_name BTSimpleParallel
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/composite.gd"

## Runs exactly 2 nodes at the same time, one that is a leaf node and the second that can be any tree node.
## When the first child returns success or failure the second child is interrupted,
## unless [code]_is_delayed[/code] is true in which case
## this waits for the second child to finish after the first one has finished and returns the second
## child's status.

## If false, the second child will be interrupted as soon as the first child finishes.
## If truee, this will wait for the second child to finish after the first child finishes.
@export var _is_delayed : bool

var _parallel_child : BTNode
var _is_first_child_ticking : bool

func enter():
	super()
	if _active_child:
		_parallel_child = _get_next_valid_child(_active_child.get_index())
		if _parallel_child:
			_parallel_child.is_main_path = false
			_parallel_child.enter()
	
	_is_first_child_ticking = true

func exit(is_interrupted : bool):
	super(is_interrupted)
	if _parallel_child:
		_parallel_child.exit(is_interrupted)
		_parallel_child = null

func tick(delta : float) -> Status:
	super(delta)
	if _active_child == null || _active_child is not BTLeaf || _parallel_child == null:
		# can't do my job
		return Status.failure
	
	var status : Status
	if _is_first_child_ticking:
		status = _active_child.tick(delta)
		_parallel_child.tick(delta)
	else:
		status = _parallel_child.tick(delta)
	
	if status == Status.success || status == Status.failure:
		if _is_delayed:
			if _is_first_child_ticking:
				_is_first_child_ticking = false
				_active_child.exit(false)
				_parallel_child.is_main_path = true
				return Status.running
			else:
				_parallel_child.exit(true)
				_parallel_child.is_main_path = false
				return status
		else:
			return status
	return status

func get_active_child() -> BTNode:
	if _is_delayed && _is_first_child_ticking == false:
		return _parallel_child
	return _active_child

func _is_first_child_valid() -> bool:
	var first_child : BTNode = _get_next_valid_child()
	if first_child && first_child is BTLeaf:
		return true
	return false

func _is_main_path_changed():
	if _active_child == null || _active_child is not BTLeaf || _parallel_child == null:
		return
	
	if is_main_path == false:
		_active_child.is_main_path = false
		_parallel_child.is_main_path = false
	else:
		_active_child.is_main_path = true
		_parallel_child.is_main_path = _is_delayed && _is_first_child_ticking == false

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray
	
	var valid_children : Array[BTNode] = get_valid_children()
	if valid_children.size() != 2:
		warnings.append("Simple parallel will not work unless it has exactly 2 BTNode children")
	if valid_children.size() > 1 && valid_children[0] is not BTLeaf:
		warnings.append("Simple parallel first child must be a BTLeaf")
	
	return warnings
