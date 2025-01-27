extends UTTestBase

const _scene : PackedScene = preload("res://unit_tests/tests/individual/repeat.tscn")

var _scene_node : Node
var _repeat : BTRepeat
var _fake_action : BTAction

func before_each():
	_scene_node = _scene.instantiate()
	_repeat = _scene_node.get_node("BTBehaviorTree/BTRepeat")
	_fake_action = _scene_node.get_node("BTBehaviorTree/BTRepeat/FakeAction")
	
	add_child(_scene_node)

func after_each():
	_scene_node.queue_free()

func test_stop_on_status():
	_repeat.stop_on_status = true
	
	# stop on success #
	_repeat.status = BTNode.StatusBinary.success
	
	_fake_action.tick_status = BTNode.Status.failure
	await _repeat.ticking # tick called in base class
	await get_tree().process_frame # tick called in repeat.gd
	assert_equal(_repeat.get_status(), BTNode.Status.running)
	
	_fake_action.tick_status = BTNode.Status.success
	await _repeat.ticking
	await get_tree().process_frame
	assert_equal(_repeat.get_status(), BTNode.Status.success)
	
	# stop on failure #
	_repeat.status = BTNode.StatusBinary.failure
	
	_fake_action.tick_status = BTNode.Status.success
	await _repeat.ticking
	await get_tree().process_frame
	assert_equal(_repeat.get_status(), BTNode.Status.running)
	
	_fake_action.tick_status = BTNode.Status.failure
	await _repeat.ticking
	await get_tree().process_frame
	assert_equal(_repeat.get_status(), BTNode.Status.success)

func test_max_tries():
	const tries : int = 5
	
	_repeat.max_tries = tries
	_fake_action.tick_status = BTNode.Status.success
	
	for i in tries:
		await _repeat.ticking
		await get_tree().process_frame
		
		if i != tries-1:
			assert_equal(_repeat.get_status(), BTNode.Status.running)
		else:
			assert_equal(_repeat.get_status(), BTNode.Status.success)
