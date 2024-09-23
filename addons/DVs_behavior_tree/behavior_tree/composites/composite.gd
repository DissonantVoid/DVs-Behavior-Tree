@tool
class_name BTComposite
extends "res://addons/DVs_behavior_tree/behavior_tree/branch.gd"

## Base class for Composites, which are nodes that have 2 or more node children.
## composites tick their children in a certain order depending on certain rules, typically from left to right.

enum ConditionalAbort {none, low_priority, self_, both}

## If set to low priority and the first child is a condition, as long as a lower priority node is ticking
## (a node that comes after self in the tree and all its offsprings) this will tick its first child at the same time,
## if the condition succeeds the lower priority node will be interrupted and this will run instead.
## If set to self and the first child is a condition, as long as this composite is ticking its children
## it will also tick its first child at the same time, if the condition fails this will interrupt its running child and start over.
## Both has the same effect as low_priority and self combined and none means no conditional abort.
@export var conditional_abort : ConditionalAbort :
	set(value):
		conditional_abort = value
		if is_node_ready() == false: await self.ready
		update_configuration_warnings()

var _services : Array[BTService]

var _has_valid_cond_abort_child : bool
var _is_conditional_abort_child_ticking : bool

func _ready():
	if Engine.is_editor_hint(): return
	
	var valid_child : BTNode = _get_next_valid_child()
	_has_valid_cond_abort_child = false
	if valid_child && (valid_child is BTCondition || valid_child is BTDecorator):
		_has_valid_cond_abort_child = true
	
	var parent : Node = get_parent()
	if _has_valid_cond_abort_child && parent is BTBranch:
		parent.entered.connect(_on_parent_entered)
		parent.exited.connect(_on_parent_exited)
		parent.ticking.connect(_on_parent_ticking)
	
	# services
	for child : Node in get_children():
		if child is BTService:
			_services.append(child)
		else:
			# ignore services placed after other nodes
			break

func enter():
	super()
	# find first valid child
	var valid_child : BTNode = _get_next_valid_child()
	if valid_child:
		_active_child = valid_child
		_active_child.enter()
	
	# run services
	for service : BTService in _services:
		service.parent_entered()

func exit(is_interrupted : bool):
	super(is_interrupted)
	# stop services
	for service : BTService in _services:
		service.parent_exiting()

func tick(delta : float) -> Status:
	super(delta)
	if ((conditional_abort == ConditionalAbort.self_ ||
	conditional_abort == ConditionalAbort.both) && _has_valid_cond_abort_child):
		var cond_abort_child : BTNode = _get_next_valid_child()
		if cond_abort_child != _active_child:
			if _is_conditional_abort_child_ticking == false:
				_is_conditional_abort_child_ticking = true
				cond_abort_child.is_main_path = false
				cond_abort_child.enter()
			
			var status : Status = cond_abort_child.tick(delta)
			if status == Status.failure:
				cond_abort_child.exit(false)
				_is_conditional_abort_child_ticking = false
				# interrupt self and start over
				self.exit(true)
				cond_abort_child.is_main_path = self.is_main_path
				self.enter()
	
	return Status.undefined

func _is_main_path_changed():
	super() # update all children
	
	if _has_valid_cond_abort_child && _is_conditional_abort_child_ticking == false:
		var first_condition : BTCondition = _get_next_valid_child()
		first_condition.is_main_path = self.is_main_path

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super()
	
	var valid_children : Array[BTNode] = get_valid_children()
	if valid_children.size() < 2:
		warnings.append("Composites should have at least 2 child nodes to work properly")
	
	if (conditional_abort != ConditionalAbort.none &&
	valid_children[0] is not BTCondition && valid_children[0] is not BTDecorator):
		warnings.append("For a conditional abort to work the first child of a Composite (not including services) must be a Condition or a Decorator")
	
	return warnings

# conditional abort (low_priority)

func _on_parent_entered():
	return

func _on_parent_exited():
	return

func _on_parent_ticking(delta : float):
	if (conditional_abort != ConditionalAbort.low_priority &&
	conditional_abort != ConditionalAbort.both): # _has_valid_cond_abort_child is already checked for in _ready
		return
	
	var running_sibling : BTNode = null
	running_sibling = get_parent().get_active_child()
	if running_sibling ==  null:
		# paren't hasn't picked a sibling yet
		return
	
	# child is us
	if running_sibling == self: return
	# child is higher priority than us because it's to the left
	if running_sibling.get_index() < self.get_index(): return
	
	var path_to_active : Array[BTNode] = behavior_tree.get_path_to_active_node()
	for i : int in range(path_to_active.find(get_parent())+1, path_to_active.size()):
		var node : BTNode = path_to_active[i]
		if node is BTBranch && node.uninterruptible:
			# one of the branches along the path to active node is uninterruptible
			return
	
	# tick our condition child
	var cond_abort_child : BTNode = _get_next_valid_child()
	if _is_conditional_abort_child_ticking == false:
		_is_conditional_abort_child_ticking = true
		cond_abort_child.is_main_path = false
		cond_abort_child.enter()
	
	var status : Status = cond_abort_child.tick(delta)
	if status == Status.success:
		cond_abort_child.exit(false)
		cond_abort_child.is_main_path = self.is_main_path
		_is_conditional_abort_child_ticking = false
		# interrupt and redirect flow to self
		behavior_tree.force_tick_node(self)
