@tool
class_name BtComposite
extends "res://behavior_tree/bt_branch.gd"

enum ConditionalAbort {none, low_priority, self_, both}

@export var conditional_abort : ConditionalAbort :
	set(value):
		conditional_abort = value
		if is_node_ready() == false: await self.ready
		update_configuration_warnings()
## if true higher priority composites cannot interrupt this branch even if their interrupt_target is set to low_priority or both
@export var uninterruptible : bool = false

var _services : Array[BtService]

var _has_valid_cond_abort_child : bool
var _cond_abort_parent : BtBranch
var _is_conditional_abort_child_ticking : bool

# TODO: this reacts to self being moved to another parent but
#       we're not checking if child order changes
func _enter_tree():
	super()
	if is_node_ready() == false: await self.ready
	
	var valid_child : BtNode = _get_next_valid_child()
	_has_valid_cond_abort_child = false
	if valid_child && (valid_child is BtConditional || valid_child is BtDecorator):
		_has_valid_cond_abort_child = true
	
	if get_parent() is BtBranch:
		_cond_abort_parent = get_parent()
		_cond_abort_parent.entered.connect(_on_parent_entered)
		_cond_abort_parent.exited.connect(_on_parent_exited)
		_cond_abort_parent.ticking.connect(_on_parent_ticking)

func _exit_tree():
	_has_valid_cond_abort_child = false
	if _cond_abort_parent:
		_cond_abort_parent.entered.disconnect(_on_parent_entered)
		_cond_abort_parent.exited.disconnect(_on_parent_exited)
		_cond_abort_parent.ticking.disconnect(_on_parent_ticking)
		_cond_abort_parent = null
	
	if _is_conditional_abort_child_ticking:
		_is_conditional_abort_child_ticking = false
		var cond_abort_child : BtNode = _get_next_valid_child()
		cond_abort_child.exit(true)

func enter():
	super()
	# find first valid child
	var valid_child : BtNode = _get_next_valid_child()
	if valid_child:
		_active_child = valid_child
		_active_child.enter()
	
	# services
	for child : Node in get_children():
		if child is BtService:
			_services.append(child)
		else:
			# ignore serviced placed after other nodes
			break
	
	for service : BtService in _services:
		service.parent_entered()

func exit(is_interrupted : bool):
	super(is_interrupted)
	for service : BtService in _services:
		service.parent_exiting()
	_services.clear()

func tick(delta : float) -> Status:
	super(delta)
	if ((conditional_abort == ConditionalAbort.self_ ||
	conditional_abort == ConditionalAbort.both) && _has_valid_cond_abort_child):
		var cond_abort_child : BtNode = _get_next_valid_child()
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
	
	var valid_children : int = 0
	for child : Node in get_children():
		if child is BtNode: valid_children += 1
	if valid_children < 2:
		warnings.append("Composites must have at least 2 child nodes to work properly")
	
	var first_valid_child : BtNode = _get_next_valid_child()
	if (conditional_abort != ConditionalAbort.none &&
	first_valid_child is not BtConditional && first_valid_child is not BtDecorator):
		warnings.append("For a conditional abort to work the first child of a composite (not including services) must be a conditional")
	
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
	
	var running_sibling : BtNode = null
	running_sibling = _cond_abort_parent.get_active_child()
	
	# child is us
	if running_sibling == self: return
	# child is higher priority than us because it's to the left
	if running_sibling.get_index() < self.get_index(): return
	# child is low priority but uninterruptible
	# TODO: also check the uninterruptible flag of all its children and chilren of children etc...
	#       if one of the composites in the chain is uninterruptible we return
	if running_sibling.uninterruptible: return
	
	# tick first child
	var cond_abort_child : BtNode = _get_next_valid_child()
	if _is_conditional_abort_child_ticking == false:
		_is_conditional_abort_child_ticking = true
		cond_abort_child.enter()
	
	var status : Status = cond_abort_child.tick(delta)
	if status == Status.success:
		cond_abort_child.exit(false)
		_is_conditional_abort_child_ticking = false
		behavior_tree.force_tick_node(self)
