extends "res://behavior_tree/composites/bt_composite.gd"

# NOTE: intended to be inherited rather than used directly
# TODO: how will this handle interrupt target?

## if true the last picked node will no be picked again
@export var no_repeat : bool = false
@export var weight : Dictionary # TODO: wait for 4.4 and use typed dicts Dictionary[BtNode, float]

var _weigt_format_valid : bool
var _last_child : BtNode = null

func enter():
	super()
	_active_child = _pick_rand_child()
	
	_weigt_format_valid = true
	for key in weight.keys():
		if key is not BtNode || weight[key] is not float:
			_weigt_format_valid = false
			push_warning("Weight dictionary must contain pairs of BtNode:float representing a node and its weight relative to other nodes, weight will be ignored")
			break

func _pick_rand_child() -> BtNode:
	var children : Array[BtNode] = _get_valid_children()
	if no_repeat && _last_child && children.size() > 1:
		children.erase(_last_child)
	
	var rand : BtNode = null
	if _weigt_format_valid:
		# TODO: account for weight
		pass
	else:
		rand = children.pick_random()
	
	_last_child = rand
	return rand
