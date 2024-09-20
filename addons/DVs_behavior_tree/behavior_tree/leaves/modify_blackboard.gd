@tool
class_name BTModifyBlackboard
extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/action.gd"

enum ActionType {write, erase}

@export var use_global_blackboard : bool = false
@export var action : ActionType :
	set(value):
		action = value
		notify_property_list_changed()
		update_configuration_warnings()
@export var key : String :
	set(value):
		key = value
		update_configuration_warnings()
@export var value_expression : String :
	set(value):
		value_expression = value
		update_configuration_warnings()
@export var must_exist : bool

func tick(delta : float) -> Status:
	super(delta)
	if _are_variables_valid() == false:
		return Status.failure
	
	var blackboard : Dictionary =\
		behavior_tree.global_blackboard if use_global_blackboard else behavior_tree.blackboard
	
	if action == ActionType.write:
		var exp : Expression = Expression.new()
		exp.parse(value_expression)
		var result : Variant = exp.execute()
		if exp.has_execute_failed():
			return Status.failure
		
		# set value
		blackboard[key] = result
		return Status.success
		
	elif action == ActionType.erase:
		if blackboard.has(key) == false:
			# key doesn't exist, proceed based on must_exist
			if must_exist: return Status.failure
			else: return Status.success
		else:
			blackboard.erase(key)
			return Status.success
	
	return Status.undefined

func _get_configuration_warnings() -> PackedStringArray:
	if _are_variables_valid() == false:
		return ["Not all variables are set"]
	return []

func _validate_property(property : Dictionary):
	if property["name"] == "value_expression" && action == ActionType.erase:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property["name"] == "must_exist" && action != ActionType.erase:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _are_variables_valid() -> bool:
	if key.is_empty(): return false
	if action == ActionType.write && value_expression.is_empty():
		return false
	return true
