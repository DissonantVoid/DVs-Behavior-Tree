@tool
@icon("res://addons/DVs_behavior_tree/icons/composite_attachment.svg")
class_name BTCompositeAttachment
extends Node

## Base class for attachments, can be attached to Composite nodes and will tick as long as its parent is ticking,
## mainly used to monitor game state and update the blackboard.

## How many tree ticks must pass before one attachment tick occurs.
@export var tree_ticks_per_tick : int = 1 :
	set(value):
		tree_ticks_per_tick = max(value, 1)

var behavior_tree : BTBehaviorTree
var _frames_counter : int = 0


# override
func parent_entered():
	_frames_counter = 0

# override
func parent_exiting():
	return

func parent_tick(delta : float):
	_frames_counter += 1
	if _frames_counter == tree_ticks_per_tick:
		_frames_counter = 0
		_tick(delta)

# override
func _tick(delta : float):
	return

func _get_configuration_warnings() -> PackedStringArray:
	var has_previous_node_sibling : bool = false
	for i : int in range(get_index(), 0, -1):
		if get_parent().get_child(i) is BTNode:
			has_previous_node_sibling = true
			break
	
	if get_parent() is BTComposite == false || has_previous_node_sibling:
		return ["Attachment node must be a child of a Composite node, and must be positioned before any non-attachment children"]
	
	return []
