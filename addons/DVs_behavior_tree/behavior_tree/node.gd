@tool
@icon("res://addons/DVs_behavior_tree/icons/node.svg")
class_name BTNode
extends Node

## Base class for all behavior tree nodes.

signal entered
signal exited
signal ticking(delta)

enum Status {undefined=0, running=1, success=2, failure=3, interrupted=4}
enum StatusBinary                   {success=2, failure=3}

## Optional description used by the debugger, supports BBCode.
@export_multiline var description : String

var behavior_tree : BTBehaviorTree
var _status : Status = Status.undefined

# used to differentiate between main tick path and parallel paths running due to features like simple parallel and conditional abort, nodes are assumed main path by default unless set otherwise
var is_main_path : bool = true :
	set(value):
		is_main_path = value
		_is_main_path_variable_changed()

func enter():
	if behavior_tree.is_active_tree_in_debugger():
		BTDebuggerListener.send_message(
			"node_entered", {"id":self.get_instance_id()}
		)
	entered.emit()

func exit(is_interrupted : bool):
	if behavior_tree.is_active_tree_in_debugger():
		BTDebuggerListener.send_message(
			"node_exited", {"id":self.get_instance_id()}
		)
	if is_interrupted:
		_set_status(Status.interrupted)
	exited.emit()

func tick(delta : float):
	if behavior_tree.is_active_tree_in_debugger():
		BTDebuggerListener.send_message(
			"node_ticked", {"id":self.get_instance_id(), "main_path":is_main_path}
		)
	ticking.emit(delta)

func get_status() -> Status:
	return _status

func _set_status(status : Status):
	if status == Status.undefined:
		push_error("Status.undefiend is not supposed to be returned by behavior tree nodes")
	
	if behavior_tree.is_active_tree_in_debugger():
		BTDebuggerListener.send_message(
			"node_status_changed", {"id":self.get_instance_id(), "status":status, "main_path":is_main_path}
		)
		
	_status = status

func _is_main_path_variable_changed():
	# used by branches, especially those that support parallel ticking to determine
	# which child is the main one. a branch must have 1 main child.
	return

func _get_configuration_warnings() -> PackedStringArray:
	if get_parent() is not BTBranch && self is not BTBehaviorTree:
		return ["Behavior nodes must be parented to a BTBranch node"]
	return []
