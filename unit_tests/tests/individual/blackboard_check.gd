extends UTTestBase

const _scene : PackedScene = preload("res://unit_tests/tests/individual/blackboard_check.tscn")

var _scene_node : Node
var _behavior_tree : BTBehaviorTree
var _blackboard_check : BTBlackboardCheck

func before_each():
	_scene_node = _scene.instantiate()
	_behavior_tree = _scene_node.get_node("BTBehaviorTree")
	_blackboard_check = _behavior_tree.get_node("BTBlackboardCheck")
	add_child(_scene_node)

func after_each():
	_scene_node.queue_free()

func test_conditions():
	_behavior_tree.blackboard["test_str"] = "test"
	_behavior_tree.blackboard["test_num"] = 1
	_behavior_tree.global_blackboard["test_str"] = "test"
	_behavior_tree.global_blackboard["test_num"] = 1
	
	await _test_local_n_global_bb("test_str", BTBlackboardCheck.ConditionType.equal, '"test"')
	await _test_local_n_global_bb("test_str", BTBlackboardCheck.ConditionType.not_equal, '"nothing"')
	await _test_local_n_global_bb("test_num", BTBlackboardCheck.ConditionType.less_or_equal, "1")
	await _test_local_n_global_bb("test_num", BTBlackboardCheck.ConditionType.less_than, "2")
	await _test_local_n_global_bb("test_num", BTBlackboardCheck.ConditionType.more_or_equal, "1")
	await _test_local_n_global_bb("test_num", BTBlackboardCheck.ConditionType.more_than, "0")
	
	# test object
	_behavior_tree.blackboard["test_obj"] = self
	_behavior_tree.global_blackboard["test_obj"] = self
	_blackboard_check.set_meta("test_obj", self) # also set object as meta for the BTBlackboardCheck to have access to it
	_blackboard_check.set_meta("test_obj2", get_tree())
	await _test_local_n_global_bb("test_obj", BTBlackboardCheck.ConditionType.equal, 'get_meta("test_obj")')
	await _test_local_n_global_bb("test_obj", BTBlackboardCheck.ConditionType.not_equal, 'get_meta("test_obj2")')

func _test_local_n_global_bb(key : String, cond : BTBlackboardCheck.ConditionType, exp : String):
	_blackboard_check.key = key
	_blackboard_check.condition = cond
	_blackboard_check.value_expression = exp
	
	# local
	_blackboard_check.use_global_blackboard = false
	_behavior_tree.custom_tick()
	await get_tree().process_frame
	assert_equal(_blackboard_check.get_status(), BTNode.Status.success)
	
	# global
	_blackboard_check.use_global_blackboard = true
	_behavior_tree.custom_tick()
	await get_tree().process_frame
	assert_equal(_blackboard_check.get_status(), BTNode.Status.success)
