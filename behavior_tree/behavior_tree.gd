@tool
class_name BehaviorTree
extends "res://behavior_tree/bt_branch.gd"

enum TickType {idle, physics}

@export var is_active : bool :
	set(value):
		is_active = value
		_set_root_process()
@export var agent : Node :
	set(value):
		agent = value
		update_configuration_warnings()
## If true a behavior tree that is a sub-tree of another behavior tree will use its own blackboard separate from
## its parent tree. If false a behavior tree will share the same blackboard with all sub-trees
@export var _force_local_blackboard : bool = false :
	set(value):
		_force_local_blackboard = value
		if is_node_ready() == false: await self.ready
		
		if _is_subtree && _force_local_blackboard == false:
			blackboard = get_parent().behavior_tree.blackboard
@export var tick_type : TickType :
	set(value):
		if tick_type == value: return
		tick_type = value
		_set_root_process()
@export var frames_per_tick : int :
	set(value):
		frames_per_tick = max(value, 1)
		if Engine.is_editor_hint(): return
		
		_frames_counter = 0
		if _randomize_first_tick && frames_per_tick > 1:
			_frames_counter = randi_range(0, frames_per_tick-1)
## If true and frames_per_tick > 1, the frame counter will start at a random value between 1 and frames_per_tick
## this is meant to spread the CPU load when having multiple instances of the scene this tree belongs to
## only turn off if you think all agents must tick at the same time
@export var _randomize_first_tick : bool = true

var blackboard : Dictionary
static var global_blackboard : Dictionary

var _frames_counter : int = 0
var _is_subtree : bool
var _is_paused : bool

func _enter_tree():
	await get_tree().process_frame
	_is_subtree = get_parent() is BtNode
	notify_property_list_changed()

func _ready():
	if Engine.is_editor_hint(): return
	
	_set_root_process()
	if _is_subtree == false:
		behavior_tree = self
	
	_active_child = _get_next_valid_child()
	
	# setup children
	var setup_recursive : Callable = func(node : Node, func_ : Callable):
		if node is BehaviorTree && node != self:
			node.behavior_tree = self
			# stop here and let the sub-tree handle its nodes
			return
		elif node is BtNode || node is BtService:
			# provide reference to tree
			node.behavior_tree = self
			
			for child : Node in node.get_children():
				func_.call(child, func_)
	
	setup_recursive.call(self, setup_recursive)

# NOTE: _process and _ph_process will only run if this is the root tree
func _process(delta : float):
	if Engine.is_editor_hint(): return
	tick(delta)

func _physics_process(delta : float):
	if Engine.is_editor_hint(): return
	tick(delta)

func _notification(what : int):
	if Engine.is_editor_hint(): return
	
	if what == NOTIFICATION_PAUSED:
		_is_paused = true
	elif what == NOTIFICATION_UNPAUSED:
		_is_paused = false
	
	if _is_subtree == false:
		_set_root_process()

func tick(delta : float) -> Status:
	super(delta)
	if _is_subtree == false:
		_frames_counter += 1
		if _frames_counter >= frames_per_tick:
			_frames_counter = 0
		else:
			return Status.running
	
	if is_active && _active_child:
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

func _set_root_process():
	if Engine.is_editor_hint(): return
	if is_node_ready() == false: await self.ready
	
	var was_ticking : bool = is_processing() || is_physics_processing()
	var is_ticking : bool
	if _is_subtree == false && is_active && _is_paused == false:
		set_process(tick_type == TickType.idle)
		set_physics_process(tick_type == TickType.physics)
		is_ticking = true
	else:
		set_process(false)
		set_physics_process(false)
		is_ticking = false
	
	# only change child state if ticking state changes
	# if we switch from TickType.idle to TickType.physics just keep child ticking
	if _active_child:
		if was_ticking && is_ticking == false:
			_active_child.exit(true)
		elif was_ticking == false && is_ticking:
			_active_child.enter()

func _validate_property(property : Dictionary):
	var p_name : String = property["name"]
	if ((p_name == "tick_type" || p_name == "frames_per_tick" || p_name == "_randomize_first_tick")
	&& _is_subtree):
		# tick related variables if this is a sub-tree
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif p_name == "_force_local_blackboard" && _is_subtree == false:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray
	var valid_children_count : int = _get_valid_children().size()
	if valid_children_count != 1:
		warnings.append("Behavior tree must have a single BtNode child")
	if valid_children_count == 1 && _get_next_valid_child() is BtBranch == false:
		warnings.append("Tree is useless if first child isn't a branch")
	if agent == null:
		warnings.append("Agent is null")
		
	return warnings
