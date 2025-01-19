@tool
@icon("res://addons/DVs_behavior_tree/icons/blackboard_check.svg")
class_name BTBlackboardCheck
extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/condition.gd"

## Checks a key against an expression using a specified condition type.

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

func tick(delta : float):
	super(delta)
	if _are_variables_valid() == false:
		_set_status(Status.failure)
		return
	
	var blackboard : Dictionary =\
		behavior_tree.global_blackboard if use_global_blackboard else behavior_tree.blackboard
	
	if blackboard.has(key) == false:
		_set_status(Status.failure)
		return
	
	var expr := Expression.new()
	expr.parse(value_expression)
	var result : Variant = expr.execute([], self)
	
	if expr.has_execute_failed():
		_set_status(Status.failure)
		return
	
	if condition == ConditionType.equal && blackboard[key] == result:
		_set_status(Status.success)
	elif condition == ConditionType.less_than && blackboard[key] < result:
		_set_status(Status.success)
	elif condition == ConditionType.less_or_equal && blackboard[key] <= result:
		_set_status(Status.success)
	elif condition == ConditionType.more_than && blackboard[key] > result:
		_set_status(Status.success)
	elif condition == ConditionType.more_or_equal && blackboard[key] >= result:
		_set_status(Status.success)
	elif condition == ConditionType.not_equal && blackboard[key] != result:
		_set_status(Status.success)
	else:
		_set_status(Status.failure)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super()
	if _are_variables_valid() == false:
		warnings.append("Not all variables are set")
	return warnings

func _are_variables_valid() -> bool:
	if key.is_empty() || value_expression.is_empty():
		return false
	return true
