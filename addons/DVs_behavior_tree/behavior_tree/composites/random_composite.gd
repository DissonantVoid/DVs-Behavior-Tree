@tool
class_name BTRandomComposite
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/composite.gd"

# NOTE: intended to be inherited rather than used directly

## if true the last picked node will no be picked again
@export var no_repeat : bool = false
## ... children with unspecified weight will be given a default weight of 1.0
## the weight can be any value, positive or negative
@export var weight : Dictionary # TODO: wait for 4.4 and use typed dicts Dictionary[BTNode, float]

var _weight_format_valid : bool
var _last_child : BTNode = null

func enter():
	super()
	# running super will calculate active_child as the first valid child just
	# for us to override that, kinda inefficient but not a big deal for now
	_active_child = _pick_rand_child()
	
	_weight_format_valid = _validate_weight_format()

func _pick_rand_child() -> BTNode:
	var children : Array[BTNode] = _get_valid_children()
	if children.size() == 1: return children[0]
	
	if no_repeat && _last_child:
		children.erase(_last_child)
	
	var rand : BTNode = null
	if weight.size() > 0 && _weight_format_valid:
		var weight_full : Dictionary # BTNode : float
		var biggest_weight : float = -INF
		var smallest_weight : float = 0.0
		for child : BTNode in children:
			if weight.has(child):
				weight_full[child] = weight[weight]
			else:
				# default weight of 1 for nodes not in weight
				weight_full[child] = 1.0
			biggest_weight = max(biggest_weight, weight_full[child])
			smallest_weight = min(smallest_weight, weight_full[child])
		
		# use smallest_weight as offset to ensure all weights are > 0 for the accumulation to work
		smallest_weight = abs(smallest_weight)
		
		var rand_position : float = randf_range(0.0, biggest_weight + smallest_weight)
		var accumulation : float = 0.0
		for child : BTNode in weight_full:
			var weight_offseted : float = weight_full[child] + smallest_weight
			accumulation += weight_offseted
			if accumulation >= rand_position:
				rand = child; break
	
	else:
		rand = children.pick_random()
	
	_last_child = rand
	return rand

func _validate_weight_format() -> bool:
	if weight.size() == 0: return true
	
	for key in weight.keys():
		if key is not BTNode || weight[key] is not float:
			return false
	return true

func _get_configuration_warnings() -> PackedStringArray:
	if _validate_weight_format() == false:
		return ["Weight dictionary must contain pairs of BTNode:float representing a node and its weight relative to other nodes, weight will be ignored"]
	
	return []
