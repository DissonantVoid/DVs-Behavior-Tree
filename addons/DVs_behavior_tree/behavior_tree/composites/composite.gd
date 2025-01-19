@tool
@icon("res://addons/DVs_behavior_tree/icons/composite.svg")
class_name BTComposite
extends "res://addons/DVs_behavior_tree/behavior_tree/branch.gd"

## Base class for Composites.
## Composites tick their children in a certain order, typically from left to right.

enum ConditionalAbort {
	none,         ## No conditional abort.
	low_priority, ## If first child is a condition, as long as a lower priority node is ticking (a node that comes after self in the tree and all its offsprings), this will tick its first child in parallel. If the condition succeeds the lower priority node will be interrupted and this will run instead.
	self_,        ## If first child is a condition, as long as self is ticking its children it will also tick its first child in parallel, if the condition fails this will interrupt its running child and start over.
	both          ## Same effect as low_priority and self combined.
}

## One of [code]ConditionAbort[/code] values.
@export var conditional_abort : ConditionalAbort :
	set(value):
		conditional_abort = value
		if is_node_ready() == false: await self.ready
		update_configuration_warnings()

var _attachments : Array[BTCompositeAttachment]

var _has_valid_cond_abort_child : bool
var _conditional_abort_child : BTNode

func _ready():
	if Engine.is_editor_hint(): return
	
	# cond abort
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
	
	# attachments
	for child : Node in get_children():
		if child is BTCompositeAttachment:
			_attachments.append(child)
		elif child is BTNode:
			# ignore attachments placed after other behavior nodes, BTCompositeAttachment will handle warnings
			break

func enter():
	super()
	
	# set active child to first child by default
	_active_child = _get_next_valid_child()
	
	# ConditionalAbort.low_priority, abort child in case self was entered naturaly without having had interrupted another branch
	if (conditional_abort == ConditionalAbort.low_priority ||
	conditional_abort == ConditionalAbort.both) && _conditional_abort_child:
		_exit_cond_abort_child_if_running(true)
	
	# ConditionalAbort.self_, get conditional
	if (conditional_abort == ConditionalAbort.self_ ||
	conditional_abort == ConditionalAbort.both) && _has_valid_cond_abort_child:
		_conditional_abort_child = _active_child
	
	# run attachments
	for attachment : BTCompositeAttachment in _attachments:
		attachment.parent_entered()

func exit(is_interrupted : bool):
	super(is_interrupted)
	
	# stop self abort child if it's still running
	if (conditional_abort == ConditionalAbort.self_ ||
	conditional_abort == ConditionalAbort.both) && _conditional_abort_child:
		_exit_cond_abort_child_if_running(is_interrupted)
	
	# stop attachments
	for attachment : BTCompositeAttachment in _attachments:
		attachment.parent_exiting(is_interrupted)

func tick(delta : float):
	super(delta)
	
	for attachment : BTCompositeAttachment in _attachments:
		attachment.parent_tick(delta)
	
	# ConditionalAbort.self_ check
	if ((conditional_abort == ConditionalAbort.self_ ||
	conditional_abort == ConditionalAbort.both) && _has_valid_cond_abort_child):
		if _active_child == _conditional_abort_child:
			# don't tick cond abort child if it's the current active child
			return
		
		if _conditional_abort_child == null:
			_conditional_abort_child = _get_next_valid_child()
			_conditional_abort_child.is_main_path = false
			_conditional_abort_child.enter()
		
		_conditional_abort_child.tick(delta)
		var status : Status = _conditional_abort_child.get_status()
		if status == Status.failure:
			_exit_cond_abort_child_if_running(false)
			# interrupt self and start over
			self.exit(true)
			self.enter()

func get_attachments() -> Array[BTCompositeAttachment]:
	return _attachments

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super()
	
	var valid_children : Array[BTNode] = get_valid_children()
	if valid_children.size() < 2:
		warnings.append("Composites should have at least 2 child nodes to work properly")
	
	if (conditional_abort != ConditionalAbort.none && valid_children &&
	valid_children[0] is not BTCondition && valid_children[0] is not BTDecorator):
		warnings.append("For a conditional abort to work the first child of a Composite (not including composite attachments) must be a Condition or a Decorator")
	
	return warnings

func _exit_cond_abort_child_if_running(is_interrupted : bool):
	if _conditional_abort_child:
		_conditional_abort_child.exit(is_interrupted)
		_conditional_abort_child.is_main_path = self.is_main_path # cond abort node runs in parallel to main path
		_conditional_abort_child = null

func _active_child_changed():
	if ((conditional_abort == ConditionalAbort.self_ ||
	conditional_abort == ConditionalAbort.both) && _has_valid_cond_abort_child):
		if _active_child == _conditional_abort_child:
			# active child just changed to the same node as _conditional_abort_child
			# disable conditional abort
			_exit_cond_abort_child_if_running(true)

# conditional abort (low_priority) #

func _on_parent_entered():
	return

func _on_parent_exited():
	_exit_cond_abort_child_if_running(true)

# TODO: what if self is not in the main path, for example self is a child of the second child of a parallel
#       node, if it interrupts its sibling force_pick_child would break the parallel node
#       we should make nodes that support parallel running acount for that
func _on_parent_ticking(delta : float):
	var running_sibling : BTNode = get_parent().get_active_child()
	
	# sibling is self
	if running_sibling == self:
		# NOTE: the signal that calls this (BTNode.ticking) is received before parent ticks self, so we don't have to worry
		#       about derived self entering cond child right as we're trying to make it exit
		_exit_cond_abort_child_if_running(true)
		return
	# sibling is higher priority than us because it's to the left
	if running_sibling.get_index() < self.get_index():
		_exit_cond_abort_child_if_running(true)
		return
	
	# check if one of the branches along the path to active node is uninterruptible
	var path_to_active : Array[BTNode] = behavior_tree.get_path_to_active_node()
	for i : int in range(path_to_active.find(get_parent())+1, path_to_active.size()):
		var node : BTNode = path_to_active[i]
		if node is BTBranch && node.uninterruptible:
			# uninterruptible
			_exit_cond_abort_child_if_running(true)
			return
	
	# tick our conditional child
	if _conditional_abort_child == null:
		_conditional_abort_child = _get_next_valid_child()
		_conditional_abort_child.is_main_path = false
		_conditional_abort_child.enter()
	
	_conditional_abort_child.tick(delta)
	var status : Status = _conditional_abort_child.get_status()
	if status == Status.success:
		_exit_cond_abort_child_if_running(false)
		# interrupt and redirect flow to self
		behavior_tree.force_tick_node(self)
