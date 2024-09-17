@tool
class_name BehaviorTree
extends "res://behavior_tree/bt_node.gd"

enum _TickType {idle, physics}

@export var is_active : bool :
	set(value):
		is_active = value
		_update_tick_type()
# TODO: hide if sub-tree
@export var tick_type : _TickType :
	set(value):
		tick_type = value
		_update_tick_type()
@export var frames_per_tick : int = 1 :
	set(value):
		frames_per_tick = max(value, 1)
@export var agent : Node

var blackboard : Dictionary

var _first_child : BtNode = null
var _frames_counter : int = 0
var _is_subtree : bool

func _ready():
	if Engine.is_editor_hint(): return
	
	_is_subtree = get_parent() is BtNode
	_first_child = _get_next_valid_child()
	
	var setup_recursive : Callable = func(node : Node, func_ : Callable):
		for child : Node in node.get_children():
			if child is BehaviorTree:
				# TODO: check for further sub-trees and set them up
				pass
			else:
				if child is BtNode || child is BtService:
					# provide reference to tree
					child.behavior_tree = self
				if child is BtNode:
					# monitor dynamic changes in the tree
					child.child_entered_tree.connect(_on_node_entered_tree)
					child.child_exiting_tree.connect(_on_node_exiting_from_tree)
			
			func_.call(child, func_)
	setup_recursive.call(self, setup_recursive)
	
	if _first_child:
		_first_child.enter()

func _process(delta : float):
	if Engine.is_editor_hint(): return
	# NOTE: no need to run additional checks since _update_tick_type takes care of that
	tick(delta)

func _physics_process(delta : float):
	if Engine.is_editor_hint(): return
	tick(delta)

func enter():
	if _first_child:
		_first_child.enter()

func exit(is_interrupted : bool):
	if _first_child:
		_first_child.exit(is_interrupted)

func tick(delta : float) -> Status:
	_frames_counter += 1
	if _frames_counter == frames_per_tick:
		_frames_counter = 0
	else:
		return Status.running
	
	if _first_child:
		var status : Status = _first_child.tick(delta)
		if status == Status.success || status == Status.failure:
			_first_child.exit(false)
			_first_child.enter()
		return status
	
	return Status.failure

func _update_tick_type():
	if Engine.is_editor_hint(): return
	
	if is_node_ready() == false: await self.ready
	
	# if this isn't a sub-tree of another tree, we run things ourselves
	if _is_subtree == false && is_active && _first_child:
		set_process(tick_type == _TickType.idle)
		set_physics_process(tick_type == _TickType.physics)

func _on_node_entered_tree(node : Node):
	pass

func _on_node_exiting_from_tree(node : Node):
	pass


func _get_configuration_warnings() -> PackedStringArray:
	if _get_valid_children().size() != 1:
		return ["Behavior tree must have a single BtNode child"]
	return []
