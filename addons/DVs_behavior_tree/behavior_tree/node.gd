@tool
class_name BTNode
extends Node

signal entered
signal exited
signal ticking(delta)

enum Status {undefined, running, success=3, failure=4}
enum StatusBinary               {success=3, failure=4}

var behavior_tree : BTBehaviorTree

func enter():
	entered.emit()

func exit(is_interrupted : bool):
	exited.emit()

func tick(delta : float) -> Status:
	ticking.emit(delta)
	return Status.undefined

func _get_configuration_warnings() -> PackedStringArray:
	if get_parent() is not BTBranch:
		return ["Behavior nodes must be parented to a BTBranch node"]
	return []
