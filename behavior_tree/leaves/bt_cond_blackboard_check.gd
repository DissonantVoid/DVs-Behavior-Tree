@tool
class_name BtCondBlackboardCheck
extends "res://behavior_tree/leaves/bt_conditional.gd"

enum ConditionType {
	equal, less_than, less_or_equal, more_than,
	more_or_equal, not_equal
}

@export var use_global_blackboard : bool = false
@export var key : String :
	set(value):
		key = value
		update_configuration_warnings()
@export var condition : ConditionType
@export var value_expression : String :
	set(value):
		value_expression = value
		update_configuration_warnings()

func tick(delta : float) -> Status:
	super(delta)
	if _are_variables_valid() == false:
		return Status.failure
	
	var blackboard : Dictionary =\
		behavior_tree.global_blackboard if use_global_blackboard else behavior_tree.blackboard
	
	if blackboard.has(key) == false:
		return Status.failure
	
	var exp : Expression = Expression.new()
	exp.parse(value_expression)
	var result : Variant = exp.execute()
	
	if exp.has_execute_failed():
		return Status.failure
	
	if condition == ConditionType.equal && blackboard[key] == result:
		return Status.success
	if condition == ConditionType.less_than && blackboard[key] < result:
		return Status.success
	if condition == ConditionType.less_or_equal && blackboard[key] <= result:
		return Status.success
	if condition == ConditionType.more_than && blackboard[key] > result:
		return Status.success
	if condition == ConditionType.more_or_equal && blackboard[key] >= result:
		return Status.success
	if condition == ConditionType.not_equal && blackboard[key] != result:
		return Status.success
	
	return Status.undefined

func _get_configuration_warnings() -> PackedStringArray:
	if _are_variables_valid() == false:
		return ["Not all variables are set"]
	return []

func _are_variables_valid() -> bool:
	if key.is_empty() || value_expression.is_empty():
		return false
	return true
