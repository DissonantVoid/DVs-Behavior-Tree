@tool
class_name BtCompSimpleParallel
extends "res://behavior_tree/composites/bt_composite.gd"

## if false, the second child will be interrupted as soon as the first child finishes
## if truee, this will wait for the second child to finish after the first child finishes
@export var _is_delayed : bool

var _parallel_child : BtNode
var _is_first_child_ticking : bool

func enter():
	super()
	if _active_child:
		_parallel_child = _get_next_valid_child(_active_child.get_index())
		if _parallel_child:
			_parallel_child.enter()
	
	_is_first_child_ticking = true

func exit(is_interrupted : bool):
	super(is_interrupted)
	if _parallel_child:
		_parallel_child.exit(is_interrupted)
		_parallel_child = null

func tick(delta : float) -> Status:
	super(delta)
	if _active_child == null || _parallel_child == null:
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
				return Status.running
			else:
				_parallel_child.exit(true)
				return status
		else:
			return status
	return status

func get_active_child() -> BtNode:
	if _is_delayed && _is_first_child_ticking == false:
		return _parallel_child
	return _active_child

func _get_configuration_warnings() -> PackedStringArray:
	var valid_children : int = 0
	for child : Node in get_children():
		if child is BtNode: valid_children += 1
	if valid_children != 2:
		return ["Simple parallel will not work unless it has exactly 2 BtNode children"]
	
	return []
