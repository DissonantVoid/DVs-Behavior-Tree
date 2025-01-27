extends UTTestBase

const _scene : PackedScene = preload("res://unit_tests/tests/individual/behavior_tree.tscn")

var _scene_node : Node
var _behavior_tree : BTBehaviorTree
var _fake_action : BTNode

# TODO: replace await get_tree().create_timer() with awaiting frames so the tests don't take too long

func before_each():
	# create scene and setup references before each test
	_scene_node = _scene.instantiate()
	_behavior_tree = _scene_node.get_node("BTBehaviorTree")
	_fake_action = _behavior_tree.get_node("FakeAction")
	add_child(_scene_node)

func after_each():
	_scene_node.queue_free()

func test_custom_tick():
	_behavior_tree.tick_type = BTBehaviorTree.TickType.custom
	
	# make sure ticking doesn't happen
	await get_tree().create_timer(1).timeout
	assert_equal(_fake_action.get_ticks(), 0)
	
	# make sure 1 tick happens when calling custom_tick
	_behavior_tree.custom_tick()
	assert_equal(_fake_action.get_ticks(), 1)

func test_frames_per_tick():
	const frames_per_tick : int = 4
	const frames : int = 6
	
	_behavior_tree._randomize_first_tick = false
	_behavior_tree.frames_per_tick = frames_per_tick
	
	# tick type idle
	_fake_action.reset_ticks()
	_behavior_tree.tick_type = BTBehaviorTree.TickType.idle
	
	for i in frames:
		await get_tree().process_frame
		assert_equal(_fake_action.get_ticks(), (i+1) / _behavior_tree.frames_per_tick)
	
	# tick type physics
	await get_tree().physics_frame
	_fake_action.reset_ticks()
	_behavior_tree.tick_type = BTBehaviorTree.TickType.physics
	_behavior_tree.frames_per_tick = frames_per_tick # trigger counter reset
	
	for i in frames:
		await get_tree().physics_frame
		assert_equal(_fake_action.get_ticks(), (i+1) / _behavior_tree.frames_per_tick)
	
	# tick type custom
	await get_tree().process_frame
	_fake_action.reset_ticks()
	_behavior_tree.tick_type = BTBehaviorTree.TickType.custom
	_behavior_tree.frames_per_tick = frames_per_tick
	
	for i in frames:
		_behavior_tree.custom_tick()
		assert_equal(_fake_action.get_ticks(), (i+1) / _behavior_tree.frames_per_tick)

func test_runtime_active_toggle():
	_behavior_tree.is_active = false
	
	await get_tree().create_timer(1).timeout
	assert_equal(_fake_action.get_ticks(), 0)
	
	await get_tree().process_frame # wait for idle frame before activating
	_behavior_tree.is_active = true
	
	const frames : int = 10
	for i : int in frames:
		await get_tree().process_frame
	assert_equal(_fake_action.get_ticks(), frames)
	
	_fake_action.reset_ticks()
	_behavior_tree.is_active = false
	for i : int in 10:
		await get_tree().process_frame
	assert_equal(_fake_action.get_ticks(), 0)
