@tool
class_name BTBlackboardCheck
extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/condition.gd"

## Checks if a blackboard key is equal, less_than etc...

enum ConditionType {
	equal, less_than, less_or_equal, more_than,
	more_or_equal, not_equal
}

## If true, this will check the global blackboard instead of the tree blackboard.
@export var use_global_blackboard : bool = false
## The blackboard key.
@export var key : String :
	set(value):
		key = value
		update_configuration_warnings()
## One of [code]ConditionType[/code] to use when comparing key and expression.
@export var condition : ConditionType
## An expression string, can be a simple value (1+1, "hello world", sin(PI)),
## or a function/variable access in self (behavior_tree.agent.get_health()).
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
	var result := exp.execute([], self)
	
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
	
	return Status.failure

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super()
	if _are_variables_valid() == false:
		warnings.append("Not all variables are set")
	return warnings

func _are_variables_valid() -> bool:
	if key.is_empty() || value_expression.is_empty():
		return false
	return true
