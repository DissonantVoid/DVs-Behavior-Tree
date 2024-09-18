@tool
class_name BtComposite
extends "res://behavior_tree/bt_node.gd"

enum InterruptTarget {none, low_priority, self_, both}

@export var interrupt_target : InterruptTarget = InterruptTarget.none
var _services : Array[BtService]

var _active_child : BtNode = null

func enter():
	super()
	# find first valid child
	var valid_child : BtNode = _get_next_valid_child()
	if valid_child:
		_active_child = valid_child
		_active_child.enter()
	
	# services
	for child : Node in get_children():
		if child is BtService:
			_services.append(child)
		else:
			# ignore serviced placed after other nodes
			break
	
	for service : BtService in _services:
		service.parent_entered()

func exit(is_interrupted : bool):
	super(is_interrupted)
	if _active_child:
		_active_child.exit(is_interrupted)
		_active_child = null
	
	for service : BtService in _services:
		service.parent_exiting()
	_services.clear()

func _get_configuration_warnings() -> PackedStringArray:
	var valid_children : int = 0
	for child : Node in get_children():
		if child is BtNode: valid_children += 1
	
	if valid_children < 2:
		return ["Composites must have at least 2 child nodes to work properly"]
	return []
