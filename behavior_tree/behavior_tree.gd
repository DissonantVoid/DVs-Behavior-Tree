@tool
class_name BehaviorTree
extends "res://behavior_tree/bt_branch.gd"

enum TickType {idle, physics}

@export var is_active : bool : # TODO: changing most of these vars at run time isn't handled properly
	set(value):
		is_active = value
		_root_tree_setup()
@export var agent : Node
## If true a behavior tree that is a sub-tree of another behavior tree will use its own blackboard separate from
## its parent tree. If false a behavior tree will share the same blackboard with all sub-trees
@export var force_local_blackboard : bool = false :
	set(value):
		if Engine.is_editor_hint() == false && is_node_ready():
			push_error("force_local_blackboard cannot be changed while the game is running")
		else:
			force_local_blackboard = value
@export var tick_type : TickType :
	set(value):
		tick_type = value
		_root_tree_setup()
@export var frames_per_tick : int :
	set(value):
		frames_per_tick = max(value, 1)
		if Engine.is_editor_hint(): return
		
		_frames_counter = 0
		if randomize_tick_start && frames_per_tick > 1:
			_frames_counter = randi_range(0, frames_per_tick-1)

## If true and frames_per_tick > 1, the frame counter will start at a random value between 1 and frames_per_tick
## this is meant to spread the CPU load when having multiple instances of the scene this tree belongs to
@export var randomize_tick_start : bool = true

var blackboard : Dictionary
static var global_blackboard : Dictionary

var _frames_counter : int = 0
var _is_subtree : bool

func _ready():
	_check_if_subtree()
	
	if Engine.is_editor_hint(): return

func _process(delta : float):
	if Engine.is_editor_hint(): return
	tick(delta)

func _physics_process(delta : float):
	if Engine.is_editor_hint(): return
	tick(delta)

func _notification(what : int):
	if Engine.is_editor_hint(): return
	
	if _is_subtree == false:
		if what == NOTIFICATION_PAUSED:
			# interrupt flow
			if _active_child:
				_active_child.exit(true)
		elif what == NOTIFICATION_UNPAUSED:
			_root_tree_setup()

# we could take advantage of this later when we implement dynamic trees
# and debug graph
func register_node(node):
	if node is BehaviorTree:
		# TODO: check for further sub-trees and set them up
		push_warning("Sub-trees not fully supported yet")
	elif node is BtNode || node is BtService:
		# provide reference to tree
		node.behavior_tree = self

func unregister_node(node):
	pass

func enter():
	super()
	_active_child = _get_next_valid_child()
	if _active_child:
		_active_child.enter()

func exit(is_interrupted : bool):
	super(is_interrupted)

func tick(delta : float) -> Status:
	super(delta)
	if _is_subtree == false:
		_frames_counter += 1
		if _frames_counter >= frames_per_tick:
			_frames_counter = 0
		else:
			return Status.running
	
	if _active_child:
		var status : Status = _active_child.tick(delta)
		if status == Status.success || status == Status.failure:
			_active_child.exit(false)
			_active_child.enter()
		return status
	
	return Status.failure

func force_tick_node(target : BtNode):
	# TODO: ensure that target is a child of this tree
	#       if not then warn users that they should call this func
	#       on a higher level tree otherwise path_to_target won't work
	
	# step1, find deepest running node #
	# TODO: should cache deepest running node instead of calculating on demand
	var deepest_running_node : BtNode
	var path_to_drn : Array[BtNode]
	var get_deepest_running_child : Callable = func(node : BtBranch, func_ : Callable) -> BtNode:
		path_to_drn.append(node)
		var active_child : BtNode = node.get_active_child()
		if active_child == null:
			# a branch is the deepest child, this shouldn't be the case but since
			# this system is designed to send warnings and work around user error rather
			# than asserting and crashing we have to account for this
			return node
		
		if active_child is BtBranch:
			return func_.call(active_child, func_)
		else:
			path_to_drn.append(active_child)
			return active_child
	
	deepest_running_node = get_deepest_running_child.call(self, get_deepest_running_child)
	if deepest_running_node == target:
		push_error("Cannot force tick target because it's already the deepest running child")
		return
	
	# step2, get path to target
	var path_to_target : Array[BtNode]
	var parent : BtNode = target
	while parent != self:
		path_to_target.append(parent)
		parent = parent.get_parent()
	path_to_target.append(parent) # append self as well
	path_to_target.reverse() # reverse so it's a path to target rather than from target
	
	# step3, find last common ancestor between target and deepest node #
	# now that we have both path, both starting from self we can compare ancestors down until we find the last common ancestor
	var shortest_path : Array[BtNode] =\
		path_to_drn if path_to_drn.size() <= path_to_target.size() else path_to_target
	var longest_path : Array[BtNode] =\
		path_to_drn if path_to_drn.size() >= path_to_target.size() else path_to_target
	
	var last_common_ancestor : BtNode = null
	var ancestor_idx : int = 0
	while ancestor_idx < shortest_path.size():
		if longest_path[ancestor_idx] == shortest_path[ancestor_idx]:
			last_common_ancestor = longest_path[ancestor_idx]
		else: break
		ancestor_idx += 1
	
	# step4, interrupt common ancestor and force it to pick path leading down to target #
	#        continue to force branches to pick nodes leading down towards target
	last_common_ancestor.exit(true)
	last_common_ancestor.enter()
	
	for i : int in range(ancestor_idx, path_to_target.size()-1):
		var node : BtBranch = path_to_target[i]
		node.force_pick_child(path_to_target[i+1])

func _root_tree_setup():
	if Engine.is_editor_hint(): return
	if is_node_ready() == false: await self.ready
	
	if _is_subtree && force_local_blackboard == false:
		blackboard = get_parent().behavior_tree.blackboard
	
	# if this isn't a sub-tree of another tree, we run things ourselves
	if _is_subtree == false && is_active:
		_active_child = _get_next_valid_child()
		if _active_child:
			_active_child.enter()
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
