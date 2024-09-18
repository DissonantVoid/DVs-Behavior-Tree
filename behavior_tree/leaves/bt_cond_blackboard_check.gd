@tool
extends "res://behavior_tree/leaves/bt_conditional.gd"

enum ConditionType {
	equal, less_than, less_or_equal, more_than,
	more_or_equal, not_equal
}

@export var use_global_blackboard : bool = false
@export var key : String
@export var condition : ConditionType
@export var value_expression : String

func tick(delta : float) -> Status:
	super(delta)
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
