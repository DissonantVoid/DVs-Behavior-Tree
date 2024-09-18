@tool
class_name BehaviorTree
extends "res://behavior_tree/bt_node.gd"

enum TickType {idle, physics}

@export var is_active : bool : # TODO: changing most of these vars at run time isn't handled properly
	set(value):
		is_active = value
		_update_tick_type()
@export var agent : Node
@export var tick_type : TickType :
	set(value):
		tick_type = value
		_update_tick_type()
@export var frames_per_tick : int = 1 :
	set(value):
		frames_per_tick = max(value, 1)
## if true and frames_per_tick > 1, the frame counter will start at a random value between 1 and frames_per_tick
## this is meant to spread the CPU load when having multiple instances of the scene this tree belongs to
@export var randomize_tick_start : bool = true

var blackboard : Dictionary

var _first_child : BtNode = null # TODO: detect first child being added or replaced at run-time
var _frames_counter : int = 0
var _is_subtree : bool

func _ready():
	_check_if_subtree()
	
	if Engine.is_editor_hint(): return
	
	_first_child = _get_next_valid_child()
	if randomize_tick_start && frames_per_tick > 1:
		_frames_counter = randi_range(0, frames_per_tick-1)
	
	child_entered_tree.connect(_on_node_entered_tree)
	child_exiting_tree.connect(_on_node_exiting_from_tree)
	var setup_recursive : Callable = func(node : Node, func_ : Callable):
		for child : Node in node.get_children():
			if child is BehaviorTree:
				# TODO: check for further sub-trees and set them up
				push_warning("Sub-trees not fully supported yet")
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

func _notification(what : int):
	if Engine.is_editor_hint(): return
	
	if what == NOTIFICATION_PAUSED:
		# interrupt flow
		if _first_child:
			_first_child.exit(true)
	elif what == NOTIFICATION_UNPAUSED:
		_update_tick_type()

func enter():
	super()
	if _first_child:
		_first_child.enter()

func exit(is_interrupted : bool):
	super(is_interrupted)
	if _first_child:
		_first_child.exit(is_interrupted)

func tick(delta : float) -> Status:
	super(delta)
	if _is_subtree == false:
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
		_first_child.enter()
		set_process(tick_type == TickType.idle)
		set_physics_process(tick_type == TickType.physics)

func _check_if_subtree():
	_is_subtree = get_parent() is BtNode
	notify_property_list_changed()

func _validate_property(property : Dictionary):
	if ((property["name"] == "tick_type" || property["name"] == "frames_per_tick")
	&& _is_subtree):
		# hide tick_type and frames_per_tick if this is a sub-tree
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _get_configuration_warnings() -> PackedStringArray:
	if _get_valid_children().size() != 1:
		return ["Behavior tree must have a single BtNode child"]
	return []

func _on_tree_entered():
	# subtree moved, reevaluate some variables
	update_configuration_warnings()
	_check_if_subtree()

func _on_node_entered_tree(node : Node):
	push_warning("Dynamic tree support not available yet, please avoid changing tree order at runtime")

func _on_node_exiting_from_tree(node : Node):
	push_warning("Dynamic tree support not available yet, please avoid changing tree order at runtime")
