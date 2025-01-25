extends UTTestBase

const _scene : PackedScene = preload("res://unit_tests/tests/individual/repeat.tscn")

var scene : Node2D
var repeat : BTRepeat
var test_action : BTAction

func before_each():
	scene = _scene.instantiate()
	repeat = scene.get_node("BTBehaviorTree/BTRepeat")
	test_action = scene.get_node("BTBehaviorTree/BTRepeat/TestAction")
	
	add_child(scene)

func after_each():
	scene.queue_free()

func test_stop_on_status():
	repeat.stop_on_status = true
	
	# stop on success #
	repeat.status = BTNode.StatusBinary.success
	
	test_action.tick_status = BTNode.Status.failure
	await repeat.ticking # tick called in base class
	await get_tree().process_frame # tick called in repeat.gds
	assert_equal(repeat.get_status(), BTNode.Status.running)
	
	test_action.tick_status = BTNode.Status.success
	await repeat.ticking
	await get_tree().process_frame
	assert_equal(repeat.get_status(), BTNode.Status.success)
	
	# stop on failure #
	repeat.status = BTNode.StatusBinary.failure
	
	test_action.tick_status = BTNode.Status.success
	await repeat.ticking
	await get_tree().process_frame
	assert_equal(repeat.get_status(), BTNode.Status.running)
	
	test_action.tick_status = BTNode.Status.failure
	await repeat.ticking
	await get_tree().process_frame
	assert_equal(repeat.get_status(), BTNode.Status.success)

func test_max_tries():
	const tries : int = 5
	
	repeat.max_tries = tries
	test_action.tick_status = BTNode.Status.success
	
	for i in tries:
		await repeat.ticking
		await get_tree().process_frame
		
		if i != tries-1:
			assert_equal(repeat.get_status(), BTNode.Status.running)
		else:
			assert_equal(repeat.get_status(), BTNode.Status.success)
