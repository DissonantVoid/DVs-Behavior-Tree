extends UTTestBase

const _scene : PackedScene = preload("res://unit_tests/tests/individual/behavior_tree.tscn")

var scene : Node2D
var behavior_tree : BTBehaviorTree

func before_each():
	# create scene and setup references before each test
	scene = _scene.instantiate()
	behavior_tree = scene.get_node("BTBehaviorTree")
	add_child(scene)

func after_each():
	scene.queue_free()
	behavior_tree.queue_free()

func test_custom_tick():
	behavior_tree.tick_type = BTBehaviorTree.TickType.custom
	var tick_counter : Array[int] = [0] # array to pass as reference
	behavior_tree.ticking.connect(func(delta : float):
		tick_counter[0] += 1
	)
	# make sure ticking doesn't happen
	await get_tree().create_timer(1).timeout
	assert_equal(tick_counter[0], 0)
	
	# make sure 1 tick happens when calling custom_tick
	behavior_tree.custom_tick()
	assert_equal(tick_counter[0], 1)
	
	# TEMP
	assert_equal(true, false)

func test_frames_per_tick():
	behavior_tree._randomize_first_tick = false
	behavior_tree.frames_per_tick = 4
	
	var tick_counter : Array[int] = [0] # array to pass as reference
	behavior_tree.ticking.connect(func(delta):
		tick_counter[0] += 1
	)
	
	# tick type idle
	#tick_counter[0] = 0
	#behavior_tree.tick_type = BTBehaviorTree.TickType.idle
	#for i in 6:
		#await get_tree().process_frame
	#test_assert(behavior_tree._ticks_counter == 6 % behavior_tree.frames_per_tick)
	#test_assert(tick_counter[0] == 6)
	
	# tick type physics
	#tick_counter[0] = 0
	#...
	
	# tick type custom
	tick_counter[0] = 0
	behavior_tree.tick_type = BTBehaviorTree.TickType.custom
	
	for i in 6:
		behavior_tree.custom_tick()
		assert_equal(behavior_tree._ticks_counter, (i+1) % behavior_tree.frames_per_tick)
		assert_equal(tick_counter[0], i+1)

func test_runtime_active_toggle():
	var tick_counter : Array[int] = [0] # array to pass as reference
	behavior_tree.ticking.connect(func(delta):
		tick_counter[0] += 1
	)
	behavior_tree.is_active = false
	
	await get_tree().create_timer(1).timeout
	assert_equal(tick_counter[0], 0)
	
	await get_tree().process_frame # wait for idle frame before activating
	behavior_tree.is_active = true
	
	const frames : int = 10
	for i : int in frames:
		await get_tree().process_frame
	assert_equal(tick_counter[0], frames)
	
	tick_counter[0] = 0
	behavior_tree.is_active = false
	for i : int in 10:
		await get_tree().process_frame
	assert_equal(tick_counter[0], 0)
