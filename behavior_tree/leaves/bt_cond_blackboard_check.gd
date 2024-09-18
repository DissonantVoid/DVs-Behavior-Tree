extends "res://behavior_tree/leaves/bt_conditional.gd"

enum ConditionType {
	equal, less_than, less_or_equal, more_than,
	more_or_equal, not_equal
}

@export var key : String
@export var condition : ConditionType
@export var value_expression : String

func tick(_delta : float) -> Status:
	if behavior_tree.blackboard.has(key) == false:
		return Status.failure
	
	var exp : Expression = Expression.new()
	exp.parse(value_expression)
	var result : Variant = exp.execute()
	
	if exp.has_execute_failed():
		return Status.failure
	
	if condition == ConditionType.equal && behavior_tree.blackboard[key] == result:
		return Status.success
	if condition == ConditionType.less_than && behavior_tree.blackboard[key] < result:
		return Status.success
	if condition == ConditionType.less_or_equal && behavior_tree.blackboard[key] <= result:
		return Status.success
	if condition == ConditionType.more_than && behavior_tree.blackboard[key] > result:
		return Status.success
	if condition == ConditionType.more_or_equal && behavior_tree.blackboard[key] >= result:
		return Status.success
	if condition == ConditionType.not_equal && behavior_tree.blackboard[key] != result:
		return Status.success
	
	return Status.undefined
