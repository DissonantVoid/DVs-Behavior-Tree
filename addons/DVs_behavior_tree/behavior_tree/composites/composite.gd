@tool
@icon("res://addons/DVs_behavior_tree/icons/composite.svg")
class_name BTComposite
extends "res://addons/DVs_behavior_tree/behavior_tree/branch.gd"

## Base class for Composites, which are nodes that have 2 or more node children.
## composites tick their children in a certain order depending on certain rules, typically from left to right.

enum ConditionalAbort {
	none,         ## No conditional abort.
	low_priority, ## If first child is a condition, as long as a lower priority node is ticking (a node that comes after self in the tree and all its offsprings),
				  ## this will tick its first child in parallel. If the condition succeeds the lower priority node will be interrupted and this will run instead.
	self_,        ## If first child is a condition, as long as self is ticking its children
				  ## it will also tick its first child in parallel, if the condition fails this will interrupt its running child and start over.
	both          ## Same effect as low_priority and self combined.
}

## One of [code]ConditionAbort[/code] values.
@export var conditional_abort : ConditionalAbort :
	set(value):
		conditional_abort = value
		if is_node_ready() == false: await self.ready
		update_configuration_warnings()

var _services : Array[BTService]

var _has_valid_cond_abort_child : bool
var _conditional_abort_child : BTNode

func _ready():
	if Engine.is_editor_hint(): return
	
	var valid_child : BTNode = _get_next_valid_child()
	_has_valid_cond_abort_child = false
	if valid_child && (valid_child is BTCondition || valid_child is BTDecorator):
		_has_valid_cond_abort_child = true
	
	var parent : Node = get_parent()
	if (conditional_abort == ConditionalAbort.low_priority ||
	conditional_abort == ConditionalAbort.both) && _has_valid_cond_abort_child:
		parent.entered.connect(_on_parent_entered)
		parent.exited.connect(_on_parent_exited)
		parent.ticking.connect(_on_parent_ticking)
	
	# services
	for child : Node in get_children():
		if child is BTService:
			_services.append(child)
		else:
			# ignore services placed after other nodes, BTService will handle warnings
			break

func enter():
	super()
	
	# find first valid child
	var valid_child : BTNode = _get_next_valid_child()
	if valid_child:
		_active_child = valid_child
		_active_child.enter()
	
	# ConditionalAbort.low_priority, abort child in case self was entered naturaly without having had interrupted another branch
	if (conditional_abort == ConditionalAbort.low_priority ||
	conditional_abort == ConditionalAbort.both) && _conditional_abort_child:
		_exit_cond_abord_child(true)
	
	# ConditionalAbort.self_, get conditional
	if (conditional_abort == ConditionalAbort.self_ ||
	conditional_abort == ConditionalAbort.both) && _has_valid_cond_abort_child:
		_conditional_abort_child = valid_child
	
	# run services
	for service : BTService in _services:
		service.parent_entered()

func exit(is_interrupted : bool):
	super(is_interrupted)
	
	# interrupt self abort child if it's still running
	if (conditional_abort == ConditionalAbort.self_ ||
	conditional_abort == ConditionalAbort.both) && _conditional_abort_child:
		_exit_cond_abord_child(true)
	
	# stop services
	for service : BTService in _services:
		service.parent_exiting()

func tick(delta : float):
	super(delta)
	
	for service : BTService in _services:
		service.parent_tick(delta)
	
	# ConditionalAbort.self_ check
	if ((conditional_abort == ConditionalAbort.self_ ||
	conditional_abort == ConditionalAbort.both) && _has_valid_cond_abort_child):
		if _active_child == _conditional_abort_child:
			# don't tick cond abort child if it's the current active child
			# TODO: need a way to call _conditional_abort_child.exit right before _active_child
			#       is ticked, so the cond child exits properly before being entered back as active child
			#       for now, we just avoid calling _conditional_abort_child.exit which means that the child
			#       is entered a second time without being exited
			return
		
		if _conditional_abort_child == null:
			_conditional_abort_child = _get_next_valid_child()
			_conditional_abort_child.is_main_path = false
			_conditional_abort_child.enter()
		
		_conditional_abort_child.tick(delta)
		var status : Status = _conditional_abort_child.get_status()
		if status == Status.failure:
			_exit_cond_abord_child(false)
			# interrupt self and start over
			self.exit(true)
			self.enter()

func get_services() -> Array[BTService]:
	return _services

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super()
	
	var valid_children : Array[BTNode] = get_valid_children()
	if valid_children.size() < 2:
		warnings.append("Composites should have at least 2 child nodes to work properly")
	
	if (conditional_abort != ConditionalAbort.none && valid_children &&
	valid_children[0] is not BTCondition && valid_children[0] is not BTDecorator):
		warnings.append("For a conditional abort to work the first child of a Composite (not including services) must be a Condition or a Decorator")
	
	return warnings

func _exit_cond_abord_child(is_interrupted : bool):
	if _conditional_abort_child:
		_conditional_abort_child.exit(is_interrupted)
		_conditional_abort_child.is_main_path = self.is_main_path # cond abort node runs in parallel to main path
		_conditional_abort_child = null

# conditional abort (low_priority)

func _on_parent_entered():
	return

func _on_parent_exited():
	_exit_cond_abord_child(true)

func _on_parent_ticking(delta : float):
	var running_sibling : BTNode = null
	running_sibling = get_parent().get_active_child()
	if running_sibling ==  null:
		# parent hasn't picked a sibling yet
		_exit_cond_abord_child(true)
		return
	
	# sibling is self
	if running_sibling == self:
		# NOTE: the signal that calls this (BTNode.ticking) is received before parent ticks self, so we don't have to worry
		#       about derived self entering cond child right as we're trying to make it exit
		_exit_cond_abord_child(true)
		return
	# sibling is higher priority than us because it's to the left
	if running_sibling.get_index() < self.get_index():
		_exit_cond_abord_child(true)
		return
	
	var path_to_active : Array[BTNode] = behavior_tree.get_path_to_active_node()
	for i : int in range(path_to_active.find(get_parent())+1, path_to_active.size()):
		var node : BTNode = path_to_active[i]
		if node is BTBranch && node.uninterruptible:
			# one of the branches along the path to active node is uninterruptible
			_exit_cond_abord_child(true)
			return
	
	# tick our conditional child
	if _conditional_abort_child == null:
		_conditional_abort_child = _get_next_valid_child()
		_conditional_abort_child.is_main_path = false
		_conditional_abort_child.enter()
	
	_conditional_abort_child.tick(delta)
	var status : Status = _conditional_abort_child.get_status()
	if status == Status.success:
		_exit_cond_abord_child(false)
		# interrupt and redirect flow to self
		behavior_tree.force_tick_node(self)
