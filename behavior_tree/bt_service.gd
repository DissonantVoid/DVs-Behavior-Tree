@tool
class_name BtService
extends Node

var behavior_tree : BehaviorTree

func parent_entered():
	pass

func parent_exiting():
	pass

func tick(delta : float):
	pass

func _get_configuration_warnings() -> PackedStringArray:
	var has_previous_node_sibling : bool = false
	for i : int in range(get_index(), 0, -1):
		if get_parent().get_child(i) is BtNode:
			has_previous_node_sibling = true
			break
	
	if get_parent() is BtComposite == false || has_previous_node_sibling:
		return ["Service nodes must be places under a composite node before any other non-service children"]
	
	return []
