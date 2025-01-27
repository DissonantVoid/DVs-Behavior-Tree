extends UTTestBase

const _scene : PackedScene = preload("res://unit_tests/tests/individual/blackboard_modify.tscn")

var _scene_node : Node
var _behavior_tree : BTBehaviorTree
var _blackboard_modify : BTBlackboardModify

func before_each():
	_scene_node = _scene.instantiate()
	_behavior_tree = _scene_node.get_node("BTBehaviorTree")
	_blackboard_modify = _behavior_tree.get_node("BTBlackboardModify")
	add_child(_scene_node)

func after_each():
	_scene_node.queue_free()

func test_write():
	# write new variable
	await _write_and_check("float", 1.5)
	await _write_and_check("str", "string")
	await _write_and_check("arr", ["test", 7, {"key":"value"}])
	
	# modify
	await _write_and_check("float", 2.0)
	await _write_and_check("str", "string2")
	await _write_and_check("arr", 'behavior_tree.blackboard["arr"] + ["another one!"]')

func test_erase():
	_behavior_tree.blackboard["modify"] = "hello world"
	_blackboard_modify.action = BTBlackboardModify.ActionType.erase
	
	# delete existing
	_blackboard_modify.key = "modify"
	_behavior_tree.custom_tick()
	await get_tree().process_frame
	assert_equal(_blackboard_modify.get_status(), BTNode.Status.success)
	
	# delete non-existing
	_blackboard_modify.must_exist = false
	_blackboard_modify.key = "not real"
	_behavior_tree.custom_tick()
	await get_tree().process_frame
	assert_equal(_blackboard_modify.get_status(), BTNode.Status.success)
	
	# delete non-existing but must exist
	_blackboard_modify.must_exist = true
	_blackboard_modify.key = "not real"
	_behavior_tree.custom_tick()
	await get_tree().process_frame
	assert_equal(_blackboard_modify.get_status(), BTNode.Status.failure)
	

func _write_and_check(key : String, value):
	_blackboard_modify.action = BTBlackboardModify.ActionType.write
	_blackboard_modify.key = key
	if value is String:
		_blackboard_modify.value_expression = "'" + value + "'"
	else:
		_blackboard_modify.value_expression = str(value)
	
	_blackboard_modify.use_global_blackboard = false
	_behavior_tree.custom_tick()
	await get_tree().process_frame
	assert_equal(_behavior_tree.blackboard[key], value)
	
	_blackboard_modify.use_global_blackboard = true
	_behavior_tree.custom_tick()
	await get_tree().process_frame
	assert_equal(_behavior_tree.blackboard[key], value)
