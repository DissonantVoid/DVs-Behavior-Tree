@tool
extends "res://behavior_tree/leaves/bt_action.gd"

enum ActionType {write, erase}

@export var action : ActionType :
	set(value):
		action = value
		notify_property_list_changed()
@export var key : String
@export var value_expression : String
@export var must_exist : bool

func tick(_delta : float) -> Status:
	if action == ActionType.write:
		var exp : Expression = Expression.new()
		exp.parse(value_expression)
		var result : Variant = exp.execute()
		if exp.has_execute_failed():
			return Status.failure
		
		# set value
		behavior_tree.blackboard[key] = result
		return Status.success
		
	elif action == ActionType.erase:
		if behavior_tree.blackboard.has(key) == false:
			# key doesn't exist, proceed based on must_exist
			if must_exist: return Status.failure
			else: return Status.success
		else:
			behavior_tree.blackboard.erase(key)
			return Status.success
	
	# NoT aLl PaThS rEtUrN a VaLuE
	return Status.running

func _validate_property(property : Dictionary):
	if property["name"] == "value_expression" && action == ActionType.erase:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property["name"] == "must_exist" && action != ActionType.erase:
		property.usage = PROPERTY_USAGE_NO_EDITOR
