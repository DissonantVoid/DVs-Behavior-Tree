@tool
class_name BTComposite
extends "res://addons/DVs_behavior_tree/behavior_tree/branch.gd"

enum ConditionalAbort {none, low_priority, self_, both}

@export var conditional_abort : ConditionalAbort :
	set(value):
		conditional_abort = value
		if is_node_ready() == false: await self.ready
		update_configuration_warnings()
## if true higher priority composites cannot interrupt this branch even if their interrupt_target is set to low_priority or both
@export var uninterruptible : bool = false

var _services : Array[BTService]

var _has_valid_cond_abort_child : bool
var _cond_abort_parent : BTBranch
var _is_conditional_abort_child_ticking : bool

func _ready():
	if Engine.is_editor_hint(): return
	
	var valid_child : BTNode = _get_next_valid_child()
	_has_valid_cond_abort_child = false
	if valid_child && (valid_child is BTConditional || valid_child is BTDecorator):
		_has_valid_cond_abort_child = true
	
	if get_parent() is BTBranch:
		_cond_abort_parent = get_parent()
		_cond_abort_parent.entered.connect(_on_parent_entered)
		_cond_abort_parent.exited.connect(_on_parent_exited)
		_cond_abort_parent.ticking.connect(_on_parent_ticking)
	
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
				cond_abort_child.enter()
			
			var status : Status = cond_abort_child.tick(delta)
			if status == Status.failure:
				cond_abort_child.exit(false)
				_is_conditional_abort_child_ticking = false
				# interrupt self and start over
				self.exit(true)
				self.enter()
	
	return Status.undefined

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = []
	
	var valid_children : Array[BTNode] = _get_valid_children()
	
	if valid_children.size() < 2:
		warnings.append("Composites should have at least 2 child nodes to work properly")
	
	if (conditional_abort != ConditionalAbort.none &&
	valid_children[0] is not BTConditional && valid_children[0] is not BTDecorator):
		warnings.append("For a conditional abort to work the first child of a Composite (not including services) must be a Conditional or a Decorator")
	
	return warnings

# conditional abort (low_priority)

func _on_parent_entered():
	return

func _on_parent_exited():
	return

func _on_parent_ticking(delta : float):
	if (conditional_abort != ConditionalAbort.low_priority &&
	conditional_abort != ConditionalAbort.both):
		return
	
	var running_sibling : BTNode = null
	running_sibling = _cond_abort_parent.get_active_child()
	if running_sibling ==  null:
		# paren't hasn't picked a sibling yet
		return
	
	# child is us
	if running_sibling == self: return
	# child is higher priority than us because it's to the left
	if running_sibling.get_index() < self.get_index(): return
	# child is low priority but uninterruptible
	# TODO: also check the uninterruptible flag of all its children and chilren of children etc...
	#       if one of the composites in the chain is uninterruptible we return
	if running_sibling.uninterruptible: return
	
	# tick first child
	var cond_abort_child : BTNode = _get_next_valid_child()
	if _is_conditional_abort_child_ticking == false:
		_is_conditional_abort_child_ticking = true
		cond_abort_child.enter()
	
	var status : Status = cond_abort_child.tick(delta)
	if status == Status.success:
		cond_abort_child.exit(false)
		_is_conditional_abort_child_ticking = false
		behavior_tree.force_tick_node(self)
