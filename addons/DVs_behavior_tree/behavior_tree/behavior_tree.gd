@tool
@icon("res://addons/DVs_behavior_tree/icons/behavior_tree.svg")
class_name BTBehaviorTree
extends "res://addons/DVs_behavior_tree/behavior_tree/branch.gd"

## The starting point of a behavior tree, can also be a sub-tree if its
## parent is a Branch node.

enum TickType {idle, physics}

## Determines if the tree can run or not.
@export var is_active : bool :
	set(value):
		is_active = value
		_set_root_process()
## The node that this tree belongs to, usually an enemy or an NPC.
## Allows nodes to access the agent by calling [code]behavior_tree.agent[/code].
@export var agent : Node :
	set(value):
		agent = value
		update_configuration_warnings()
## If true a behavior tree that is a sub-tree of another behavior tree will use its own blackboard separate.
## If false it will share the same blackboard as the parent tree.
@export var _force_local_blackboard : bool = false :
	set(value):
		_force_local_blackboard = value
		if is_node_ready() == false: await self.ready
		
		if _is_subtree && _force_local_blackboard == false:
			blackboard = get_parent().behavior_tree.blackboard
## Determines if the tree should tick on idle frames (process), or physics frames (physics process).
@export var tick_type : TickType :
	set(value):
		if tick_type == value: return
		tick_type = value
		_set_root_process()
## How many frames must pass before the tree ticks once, can be used as optimization if there are too many
## agents at once or as a form of LOD where agents far away are ticked less often.
## If tree is a sub-tree, this variable represents how many ticks it must receive from parent to tick once.
@export var frames_per_tick : int :
	set(value):
		frames_per_tick = max(value, 1)
		if Engine.is_editor_hint(): return
		
		_frames_counter = 0
		if _randomize_first_tick && frames_per_tick > 1:
			_frames_counter = randi_range(0, frames_per_tick-1)
## If true and frames_per_tick > 1, the frame counter will start at a random value between 1 and frames_per_tick,
## this is meant to spread the CPU load when having multiple instances of the same agent to minimize lag spikes.
@export var _randomize_first_tick : bool = true

var _is_displayed_in_debugger : bool = false

var blackboard : Dictionary
static var global_blackboard : Dictionary

var _frames_counter : int = 0
var _is_subtree : bool
var _is_paused : bool

var _last_active_node : BTNode = null
var _cached_path_to_last_active_node : Array[BTNode]


func _enter_tree():
	await get_tree().process_frame
	_is_subtree = get_parent() is BTBranch
	notify_property_list_changed()
	
	if _is_subtree == false:
		if EngineDebugger.is_active():
			EngineDebugger.register_message_capture(_debugger_message_prefix, _on_debugger_message_received)
		
		var name_ : String = name
		if get_parent().scene_file_path:
			name_ = get_parent().scene_file_path.split("/")[-1] + "/" + name_
		
		_send_debbuger_message(
			_debugger_message_prefix + ":tree_added",
			{"id":self.get_instance_id(), "name":name_}
		)

func _exit_tree():
	if _is_subtree == false:
		_send_debbuger_message(_debugger_message_prefix + ":tree_removed", {"id":self.get_instance_id()})
		
		if EngineDebugger.is_active():
			EngineDebugger.unregister_message_capture(_debugger_message_prefix)

func _ready():
	if Engine.is_editor_hint(): return
	
	_set_root_process()
	if _is_subtree == false:
		behavior_tree = self
	
	_active_child = _get_next_valid_child()
	
	# setup children, tree is static so this only needs to happen once
	var setup_recursive : Callable = func(node : Node, func_ : Callable):
		if node is BTNode:
			# track current active node
			node.entered.connect(_on_node_entered.bind(node))
		if node is BTBehaviorTree && node != self:
			node.behavior_tree = self
			# stop here and let the sub-tree handle its nodes
			return
		elif node is BTNode || node is BTService:
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
	if is_active == false:
		# this happens when self is sub-tree and parents ticks it
		return Status.failure
	
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
			
			if _is_subtree == false:
				# no parent, re-enter
				_active_child.enter()
				return Status.success
		
		return status
	
	return Status.failure

func force_tick_node(target : BTNode):
	# ensure that target is a child of this tree, or a lower sub-tree
	if target.behavior_tree != self:
		var next_tree : BTBehaviorTree = target.behavior_tree.behavior_tree
		while true:
			if next_tree == null:
				# reached root tree without passing self, target is higher level
				push_error("Cannot force tick to target because target doesn't belong to this tree or any of its sub-tree")
				return
			elif next_tree == self:
				break
			next_tree = next_tree.behavior_tree
	
	# step1, get path to deepest running node #
	var path_to_drn : Array[BTNode] = get_path_to_active_node()
	var deepest_running_node : BTNode = path_to_drn[-1]
	if deepest_running_node == target:
		# the target is the same as the the already running deepest node
		deepest_running_node.exit(true)
		deepest_running_node.enter()
		return
	
	# step2, get path to target
	var path_to_target : Array[BTNode]
	var parent : BTNode = target
	while parent != self:
		path_to_target.append(parent)
		parent = parent.get_parent()
	path_to_target.append(parent) # append self as well
	path_to_target.reverse() # reverse so it's a path to target rather than from target
	
	# step3, find last common ancestor between target and deepest node #
	# now that we have both paths, both starting from self we can compare ancestors down until we find the last common ancestor
	var smallest_path : Array[BTNode] =\
		path_to_drn if path_to_drn.size() <= path_to_target.size() else path_to_target
	var biggest_path : Array[BTNode] =\
		path_to_drn if path_to_drn.size() >= path_to_target.size() else path_to_target
	
	var last_common_ancestor : BTNode = null
	var last_common_ancestor_idx : int = 0
	while last_common_ancestor_idx < smallest_path.size():
		if biggest_path[last_common_ancestor_idx] == smallest_path[last_common_ancestor_idx]:
			last_common_ancestor = biggest_path[last_common_ancestor_idx]
			break
		last_common_ancestor_idx += 1
	
	# step4, interrupt common ancestor and force it to pick path leading down to target #
	#        continue to force branches to pick nodes leading down towards target
	last_common_ancestor.exit(true)
	
	for i : int in range(last_common_ancestor_idx, path_to_target.size()-1):
		var node : BTBranch = path_to_target[i]
		node.enter()
		node.force_pick_child(path_to_target[i+1])

func get_path_to_active_node() -> Array[BTNode]:
	# NOTE: first node is the tree (self), last is the last active node
	if _cached_path_to_last_active_node.is_empty() == false:
		return _cached_path_to_last_active_node
	
	var get_next_running_child : Callable = func(node : BTBranch, arr : Array[BTNode], func_ : Callable) -> Array[BTNode]:
		arr.append(node)
		var active_child : BTNode = node.get_active_child()
		if active_child == null:
			# a branch is the deepest child, this shouldn't be the case but since
			# this system is designed to send warnings and work around user error rather
			# than asserting and crashing we have to account for this
			return arr
		
		if active_child is BTBranch:
			return func_.call(active_child, arr, func_)
		else:
			arr.append(active_child)
			return arr
	
	_cached_path_to_last_active_node = get_next_running_child.call(
		self, [] as Array[BTNode], get_next_running_child
	)
	return _cached_path_to_last_active_node

func is_tree_displayed_in_debugger() -> bool:
	if _is_subtree:
		return behavior_tree.is_tree_displayed_in_debugger()
	else:
		return _is_displayed_in_debugger

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
	var warnings : PackedStringArray = super()
	var valid_children : Array[BTNode] = get_valid_children()
	
	if valid_children.size() != 1:
		warnings.append("Behavior tree must have a single BTNode child")
	if valid_children.size() == 1 && valid_children[0] is BTBranch == false:
		warnings.append("Tree is useless if child isn't a BTBranch")
	if agent == null:
		warnings.append("Agent is null")
	
	return warnings

func _on_node_entered(node : BTNode):
	if node.is_main_path:
		if _last_active_node:
			_last_active_node.exited.disconnect(_on_last_active_node_exited)
		
		_last_active_node = node
		node.exited.connect(_on_last_active_node_exited.bind(node))

func _on_last_active_node_exited(node : BTNode):
	_cached_path_to_last_active_node.clear()
	_last_active_node = null
	node.exited.disconnect(_on_last_active_node_exited)

func _on_debugger_message_received(message : String, data : Array) -> bool:
	if data[0]["id"] != get_instance_id(): return false
	
	# NOTE: message capture received by the game side doesn't include prefix
	if message == "requesting_tree_structure":
		var nodes : Dictionary # id : {name, depth, class_name, description, icon_path, is_leaf}
		var relations : Dictionary # parent id : [children ids]
		var services : Dictionary # composite id : [service names]
		
		var global_class_list : Array[Dictionary] = ProjectSettings.get_global_class_list()
		var get_children_recursive : Callable = func(node : BTNode, depth : int, func_ : Callable):
			var script : Script = node.get_script()
			# get base class name if class isn't named for example if user inherites BTAction
			# without declaring a class_name this should return "BTAction"
			while script.get_global_name() == "":
				script = script.get_base_script()
			var class_name_ : String = script.get_global_name()
			
			var icon_path : String
			while true:
				for global_class : Dictionary in global_class_list:
					if global_class["class"] == script.get_global_name():
						icon_path = global_class["icon"]; break
				if icon_path.is_empty() == false: break
				
				# class with class_name doesn't have an icon, fallback to the icon of parent class
				script = script.get_base_script()
			
			nodes[node.get_instance_id()] = {
				"name":node.name, "depth":depth, "class_name":class_name_,
				"description":node.description,
				"icon_path":icon_path, "is_leaf":node is BTLeaf,
			}
			
			if node is BTBranch:
				relations[node.get_instance_id()] = []
				for child : BTNode in node.get_valid_children():
					relations[node.get_instance_id()].append(child.get_instance_id())
					func_.call(child, depth+1, func_)
				
				if node is BTComposite:
					services[node.get_instance_id()] = [] as Array[String]
					for service : BTService in node.get_services():
						services[node.get_instance_id()].append(service.name)
		
		get_children_recursive.call(self, 0, get_children_recursive)
		
		_send_debbuger_message(_debugger_message_prefix + ":sending_tree_structure", {"nodes":nodes, "relations":relations, "services":services})
		return true
	
	elif message == "debugger_display_started":
		# TODO PRIORITY: send info about active nodes so debugger can know the initial tree state
		_is_displayed_in_debugger = true
		return true
	
	elif message == "debugger_display_ended":
		_is_displayed_in_debugger = false
		return true
	
	elif message == "requesting_force_tick":
		force_tick_node(instance_from_id(data[0]["target_id"]))
		return true
	
	elif message == "requesting_blackboard_data":
		var bb : Dictionary
		if data[0]["global"]:
			bb = global_blackboard
		else:
			bb = blackboard
		_send_debbuger_message(_debugger_message_prefix + ":sending_blackboard_data", {"data":bb})
		return true
	
	return false
