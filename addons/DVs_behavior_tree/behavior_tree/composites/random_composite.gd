@tool
@icon("res://addons/DVs_behavior_tree/icons/random_composite.svg")
class_name BTRandomComposite
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/composite.gd"

## Base class for RNG based composites.

## If true the last picked node will no be picked again next time.
@export var no_repeat : bool = false
## If true each child can have a weight that determins how likely it is to be picked.
## Weights can be any float value, possitive or negative.
@export var custom_weights : bool = false :
	set(value):
		custom_weights = value
		_recalculate_weights()

const _default_weight : float = 1.0
const _editor_weights_group : String = "Weights/"
var _internal_weights : Dictionary # godot doesn't seem to keep track of custom properties so we do it ourselves
var _previous_child : BTNode = null

func _ready():
	super()
	if Engine.is_editor_hint():
		child_entered_tree.connect(_on_child_entered)

func enter():
	super()
	# running super will calculate active_child as the first valid child just
	# for us to override that, kinda inefficient but not a big deal for now
	_active_child = _pick_rand_child()

func _pick_rand_child() -> BTNode:
	var children : Array[BTNode] = get_valid_children()
	if children.size() == 0: return null
	if children.size() == 1: return children[0]
	
	if no_repeat && _previous_child:
		children.erase(_previous_child)
		_previous_child = null
		if children.size() == 1: return children[0]
	
	var rand : BTNode = null
	if custom_weights:
		var total_weight : float = 0.0
		var most_negative_weight : float = 0.0
		for child : BTNode in children:
			var internal_weight : float =\
				_internal_weights[_editor_weights_group + child.name]
			total_weight += internal_weight
			most_negative_weight = min(most_negative_weight, internal_weight)
		
		# use negative weight as offset to ensure all weights are > 0 for the accumulation to work
		most_negative_weight = abs(most_negative_weight)
		
		var rand_position : float = randf_range(0.0, total_weight + most_negative_weight)
		var accumulation : float = 0.0
		for child : BTNode in children:
			var internal_weight : float =\
				_internal_weights[_editor_weights_group + child.name]
			var weight_offseted : float = internal_weight + most_negative_weight
			accumulation += weight_offseted
			if accumulation >= rand_position:
				rand = child
				break
	
	else:
		rand = children.pick_random()
	
	_previous_child = rand
	return rand

func _recalculate_weights():
	if is_node_ready() == false: await ready
	
	var new_internal_weights : Dictionary
	for child : BTNode in get_valid_children():
		var full_name : String = _editor_weights_group + child.name
		if _internal_weights.has(full_name):
			new_internal_weights[full_name] = _internal_weights[full_name]
		else:
			# child is new, give default weight
			new_internal_weights[full_name] = _default_weight
	_internal_weights = new_internal_weights
	
	notify_property_list_changed()

func _get_property_list() -> Array[Dictionary]:
	if custom_weights == false: return []
	
	var properties : Array[Dictionary]
	for node_name : StringName in _internal_weights:
		properties.append({
			"name": node_name,
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_NONE,
			"usage": PROPERTY_USAGE_DEFAULT
		})
	return properties

func _property_can_revert(property : StringName) -> bool:
	for node_name : StringName in _internal_weights:
		if property == node_name:
			return true
	return false

func _property_get_revert(property : StringName) -> Variant:
	for node_name : StringName in _internal_weights:
		if property == node_name:
			return _default_weight
	return null

func _set(property : StringName, value : Variant) -> bool:
	if property.begins_with(_editor_weights_group):
		_internal_weights[property] = value
		return true
	return false

func _get(property : StringName) -> Variant:
	if property.begins_with(_editor_weights_group):
		return _internal_weights[property]
	return null

func _on_child_entered(node : Node):
	if Engine.is_editor_hint() && node is BTNode:
		node.renamed.connect(_on_tree_child_renamed.bind(node))
		node.tree_exiting.connect(_on_tree_child_tree_exiting.bind(node))
		_recalculate_weights()

func _on_tree_child_renamed(node : BTNode):
	_recalculate_weights()

func _on_tree_child_tree_exiting(node : BTNode):
	node.renamed.disconnect(_on_tree_child_renamed)
	node.tree_exiting.disconnect(_on_tree_child_tree_exiting)
	await get_tree().process_frame
	_recalculate_weights()
