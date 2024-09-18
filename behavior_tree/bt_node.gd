@tool
class_name BtNode
extends Node

signal entered
signal exited
signal ticking(delta)

enum Status {undefined, running, success=3, failure=4}
enum StatusBinary               {success=3, failure=4}

var behavior_tree : BehaviorTree

func _enter_tree():
	if Engine.is_editor_hint(): return
	
	if self is BehaviorTree:
		behavior_tree = self
	elif get_parent() is BtNode:
		get_parent().behavior_tree.register_node(self)

func _exit_tree():
	if Engine.is_editor_hint(): return
	behavior_tree.unregister_node(self)

func enter():
	entered.emit()

func exit(is_interrupted : bool):
	exited.emit()

func tick(delta : float) -> Status:
	ticking.emit(delta)
	return Status.undefined

func _get_configuration_warnings() -> PackedStringArray:
	if get_parent() is not BtNode:
		return ["Behavior tree nodes must be parented to other behavior nodes"]
	return []

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
