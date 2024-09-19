@tool
class_name BtNode
extends Node

signal entered
signal exited
signal ticking(delta)

enum Status {undefined, running, success=3, failure=4}
enum StatusBinary               {success=3, failure=4}

var behavior_tree : BehaviorTree

func enter():
	entered.emit()

func exit(is_interrupted : bool):
	exited.emit()

func tick(delta : float) -> Status:
	ticking.emit(delta)
	return Status.undefined

func _get_configuration_warnings() -> PackedStringArray:
	if get_parent() is not BtBranch:
		return ["Behavior tree nodes must be parented to a BtBranch node"]
	return []
