@tool
@icon("res://addons/DVs_behavior_tree/icons/node.svg")
class_name BTNode
extends Node

## Base class for all leafs and branches.

signal entered
signal exited
signal ticking(delta)

enum Status {undefined=0, running=1, success=2, failure=3}
enum StatusBinary                   {success=2, failure=3}

var behavior_tree : BTBehaviorTree

# used to differentiate between main tick path and parallel paths running due to features like simple parallel and conditional abort, nodes are assumed main path by default unless set otherwise
var is_main_path : bool = true :
	set(value):
		is_main_path = value
		_is_main_path_changed()

func enter():
	entered.emit()

func exit(is_interrupted : bool):
	exited.emit()

func tick(delta : float) -> Status:
	ticking.emit(delta)
	return Status.undefined

func _is_main_path_changed():
	# used by branches, especially those that support parallel ticking to determine
	# which child is the main one. a branch must have 1 main child.
	return

func _get_configuration_warnings() -> PackedStringArray:
	if get_parent() is not BTBranch && self is not BTBehaviorTree:
		return ["Behavior nodes must be parented to a BTBranch node"]
	return []
