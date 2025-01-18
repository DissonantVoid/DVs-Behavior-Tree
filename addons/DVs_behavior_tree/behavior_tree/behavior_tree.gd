@tool
@icon("res://addons/DVs_behavior_tree/icons/behavior_tree.svg")
class_name BTBehaviorTree
extends "res://addons/DVs_behavior_tree/behavior_tree/branch.gd"

## The root of a behavior tree.

enum TickType {
	idle, ## Ticks happen on idle frames (process)
	physics, ## Ticks happen on physics frames (physics process)
	custom ## Ticks happen manually by calling custom_tick()
}

## Determines if the tree can run or not.
@export var is_active : bool :
	set(value):
		var was_active : bool = is_active
		is_active = value
		_setup_tick(was_active)
## The node that this tree belongs to, usually an enemy or an NPC.
## Allows nodes to access the agent by calling [code]behavior_tree.agent[/code].
@export var agent : Node :
	set(value):
		agent = value
		update_configuration_warnings()
## Determines when the tree should tick.
@export var tick_type : TickType :
	set(value):
		if tick_type == value: return
		tick_type = value
		_setup_tick(is_active)
## How many frames must pass before the tree ticks once, can be used as optimization if there are too many
## agents at once or as a form of LOD where less important agents are ticked less often.
@export var frames_per_tick : int :
	set(value):
		frames_per_tick = max(value, 1)
		if Engine.is_editor_hint(): return
		
		_ticks_counter = 0
		if _randomize_first_tick && frames_per_tick > 1:
			_ticks_counter = randi_range(0, frames_per_tick-1)
## If true and frames_per_tick > 1, the tick counter will start at a random value between 0 and frames_per_tick.
## This is meant to spread the CPU load when having multiple instances of the same agent to minimize lag spikes.
@export var _randomize_first_tick : bool = true

var _is_displayed_in_debugger : bool = false

var blackboard : Dictionary
static var global_blackboard : Dictionary

var _ticks_counter : int = 0

var _last_active_node : BTNode = null
var _cached_path_to_last_active_node : Array[BTNode]


func _ready():
	if Engine.is_editor_hint(): return
	
	BTDebuggerListener.debugger_message_received.connect(_on_debugger_message_received)
	
	# debugger message
	var name_in_debugger : String =\
		agent.name if agent else name
	BTDebuggerListener.send_message(
		"tree_added",
		{
			"id":self.get_instance_id(), "name":name_in_debugger,
			"scene":owner.scene_file_path.split("/")[-1]
		}
	)
	
	# setup children, tree is static so this only needs to happen once
	var setup_recursive : Callable = func(node : Node, func_ : Callable):
		if node is BTNode:
			# track current active node
			node.entered.connect(_on_node_entered.bind(node))
		if node is BTNode || node is BTCompositeAttachment:
			# provide reference to tree
			node.behavior_tree = self
			
			for child : Node in node.get_children():
				func_.call(child, func_)
	
	setup_recursive.call(self, setup_recursive)
	
	self.enter()

func _exit_tree():
	if Engine.is_editor_hint(): return
	
	BTDebuggerListener.send_message("tree_removed", {"id":self.get_instance_id()})

func _process(delta : float):
	if Engine.is_editor_hint(): return
	tick(delta)

func _physics_process(delta : float):
	if Engine.is_editor_hint(): return
	tick(delta)

func enter():
	super()
	_active_child = _get_next_valid_child()
	_setup_tick(is_active)

func exit(is_interrupted : bool):
	super(is_interrupted)

func tick(delta : float):
	super(delta)
	
	if _active_child == null:
		_set_status(Status.failure)
		return
	
	_ticks_counter += 1
	if _ticks_counter >= frames_per_tick:
		_ticks_counter = 0
	else:
		_set_status(Status.failure)
		return
	
	_active_child.tick(delta)
	var status : Status = _active_child.get_status()
	if status == Status.success || status == Status.failure:
		_active_child.exit(false)
		# re-enter
		_active_child.enter()
		_set_status(Status.success)
		return
	
	_set_status(status)

func custom_tick(delta : float = 1.0):
	if Engine.is_editor_hint(): return
	
	if tick_type != TickType.custom:
		push_error("custom_tick() can only be called if tick_type is set to custom")
		return
	
	tick(delta)

func force_tick_node(target : BTNode):
	if target == self:
		exit(true)
		enter()
		return
	
	# ensure that target is a child of this tree
	if target.behavior_tree != self:
		push_error("Cannot force tick to target because it doesn't belong to this tree")
		return
	
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
	
	# step3, find first common ancestor between target and deepest node #
	# now that we have both paths, both starting from self we can compare ancestors down until we find the first common ancestor
	var shortest_path_size : int = min(path_to_drn.size(), path_to_target.size())
	
	var first_common_ancestor : BTNode = null
	var first_common_ancestor_idx : int = shortest_path_size-1
	while first_common_ancestor_idx >= 0:
		if path_to_drn[first_common_ancestor_idx] == path_to_target[first_common_ancestor_idx]:
			first_common_ancestor = path_to_drn[first_common_ancestor_idx]
			break
		first_common_ancestor_idx -= 1
	
	# step4, interrupt common ancestor and force it to pick path leading down to target #
	#        continue to force branches to pick nodes leading down towards target
	first_common_ancestor.exit(true)
	
	for i : int in range(first_common_ancestor_idx, path_to_target.size()-1):
		var node : BTBranch = path_to_target[i]
		node.force_pick_child(path_to_target[i+1])

func get_path_to_active_node() -> Array[BTNode]:
	# NOTE: first node is the root (self), last is the last active node
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

func is_active_tree_in_debugger() -> bool:
	return _is_displayed_in_debugger

func _setup_tick(was_active : bool):
	if Engine.is_editor_hint(): return
	
	if is_node_ready() == false: await self.ready
	
	if is_active:
		set_process(tick_type == TickType.idle)
		set_physics_process(tick_type == TickType.physics)
	else:
		set_process(false)
		set_physics_process(false)
	
	# only change child state if active state changes
	# if we switch from one tick type to another just keep child ticking
	if _active_child:
		if was_active && is_active == false:
			_active_child.exit(true)
		elif was_active == false && is_active:
			_active_child.enter()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super()
	var valid_children : Array[BTNode] = get_valid_children()
	
	if get_parent() is BTNode:
		warnings.append("Behavior tree node must be the root of the tree")
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
		
		# keep track of last active node in the tree
		_last_active_node = node
		node.exited.connect(_on_last_active_node_exited.bind(node))

func _on_last_active_node_exited(node : BTNode):
	_cached_path_to_last_active_node.clear()
	_last_active_node = null
	node.exited.disconnect(_on_last_active_node_exited)

func _on_debugger_message_received(message : String, data : Array) -> bool:
	# NOTE: message capture received by the game side doesn't include prefix
	
	if data[0]["id"] != get_instance_id():
		return false
	
	if message == "requesting_tree_structure":
		var nodes : Dictionary # id : {name, depth, class_name, status, description, icon_path, is_leaf}
		var relations : Dictionary # parent id : [children ids]
		
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
			
			var attachments : Array[String]
			if node is BTComposite:
				for attachment : BTCompositeAttachment in node.get_attachments():
					attachments.append(attachment.name)
			
			nodes[node.get_instance_id()] = {
				"name":node.name, "depth":depth, "class_name":class_name_,
				"status":node.get_status(), "description":node.description,
				"icon_path":icon_path, "is_leaf":node is BTLeaf, "attachments":attachments
			}
			
			if node is BTBranch:
				relations[node.get_instance_id()] = []
				for child : BTNode in node.get_valid_children():
					relations[node.get_instance_id()].append(child.get_instance_id())
					func_.call(child, depth+1, func_)
		
		get_children_recursive.call(self, 0, get_children_recursive)
		
		BTDebuggerListener.send_message(
			"sending_tree_structure", {"nodes":nodes, "relations":relations}
		)
		return true
	
	elif message == "debugger_display_started":
		_is_displayed_in_debugger = true
		return true
	
	elif message == "debugger_display_ended":
		_is_displayed_in_debugger = false
		return true
	
	elif message == "requesting_force_tick":
		force_tick_node(instance_from_id(data[0]["target_id"]))
		return true
	
	elif message == "requesting_blackboard_data":
		BTDebuggerListener.send_message(
			"sending_blackboard_data", {"blackboard":blackboard}
		)
		return true
	
	return false
