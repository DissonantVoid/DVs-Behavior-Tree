@tool
class_name BtComposite
extends "res://behavior_tree/bt_node.gd"

enum InterruptTarget {none, low_priority, self_, both}

@export var interrupt_target : InterruptTarget = InterruptTarget.none
var _services : Array[BtService]

var _active_child : BtNode = null

func enter():
	# assign child here so tree can be dynamic at run-time
	# TODO: first child might not be a bt_node, maybe update _get_next_child_index to take care of this
	#       same for decorator base class
	if get_child_count() > 0:
		_active_child = get_child(0)
		_active_child.enter()
	
	for child : Node in get_children():
		if child is BtService:
			_services.append(child)
		else: break
	
	for service : BtService in _services:
		service.parent_entered()

func exit(is_interrupted : bool):
	if _active_child:
		_active_child.exit(is_interrupted)
		_active_child = null
	
	for service : BtService in _services:
		service.parent_exiting()
	_services.clear()

func tick(delta : float):
	for service : BtService in _services:
		service.tick(delta)

func _get_configuration_warnings() -> PackedStringArray:
	return []
