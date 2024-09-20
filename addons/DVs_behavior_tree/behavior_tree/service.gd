@tool
class_name BTService
extends Node

## if set to 0 it will use the same tick rate as its tree
@export var frames_per_tick : int = 0 :
	set(value):
		frames_per_tick = max(value, 0)

var behavior_tree : BTBehaviorTree
var _frames_counter : int = 0


func _ready():
	set_process(false)
	set_physics_process(false)

func _process(delta : float):
	var real_frames_per_tick : int =\
		frames_per_tick if frames_per_tick != 0 else behavior_tree.frames_per_tick
	_frames_counter += 1
	if _frames_counter == real_frames_per_tick:
		_frames_counter = 0
		_tick(delta)

func _physics_process(delta : float):
	var real_frames_per_tick : int =\
		frames_per_tick if frames_per_tick != 0 else behavior_tree.frames_per_tick
	_frames_counter += 1
	if _frames_counter == real_frames_per_tick:
		_frames_counter = 0
		_tick(delta)

func parent_entered():
	if behavior_tree.tick_type == BTBehaviorTree.TickType.idle:
		set_process(true)
	else:
		set_physics_process(true)

func parent_exiting():
	_frames_counter = 0
	set_process(false)
	set_physics_process(false)

func _tick(delta : float):
	return

func _get_configuration_warnings() -> PackedStringArray:
	var has_previous_node_sibling : bool = false
	for i : int in range(get_index(), 0, -1):
		if get_parent().get_child(i) is BTNode:
			has_previous_node_sibling = true
			break
	
	if get_parent() is BTComposite == false || has_previous_node_sibling:
		return ["Service nodes must be a child of a Composite node before any non-service children"]
	
	return []
