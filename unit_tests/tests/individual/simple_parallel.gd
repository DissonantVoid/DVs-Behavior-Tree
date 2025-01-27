extends UTTestBase

const _scene : PackedScene = preload("res://unit_tests/tests/individual/simple_parallel.tscn")

var _scene_node : Node
var _simple_parallel : BTSimpleParallel
var _fake_action : BTAction
var _fake_composite : BTComposite
var _facke_composite_action : BTAction

func before_each():
	_scene_node = _scene.instantiate()
	_simple_parallel = _scene_node.get_node("BTBehaviorTree/BTSimpleParallel")
	_fake_action = _simple_parallel.get_node("FakeAction")
	_fake_composite = _simple_parallel.get_node("FakeComposite")
	_facke_composite_action = _fake_composite.get_node("FakeAction")
	add_child(_scene_node)

func after_each():
	_scene_node.queue_free()

func test_delayed_off():
	_simple_parallel._is_delayed = false
	_fake_action.tick_status = BTNode.Status.running
	await get_tree().process_frame
	
	# check that both nodes ticked
	assert_equal(_fake_action.get_ticks(), 1)
	assert_equal(_fake_composite.get_ticks(), 1)
	
	# stop main child and check that parallel child was interrupted
	_fake_action.tick_status = BTNode.Status.failure
	_fake_action.reset_ticks()
	_fake_composite.reset_ticks()
	await get_tree().process_frame
	
	assert_equal(_fake_action.get_ticks(), 1)
	assert_equal(_fake_composite.get_status(), BTNode.Status.interrupted)
	
	assert_equal(_simple_parallel.get_status(), _fake_action.tick_status)

func test_delayed_on():
	_simple_parallel._is_delayed = true
	_fake_action.tick_status = BTNode.Status.running
	await get_tree().process_frame
	
	# check that both nodes ticked
	assert_equal(_fake_action.get_ticks(), 1)
	assert_equal(_fake_composite.get_ticks(), 1)
	
	# stop main child and check that parallel child is ticking
	_fake_action.tick_status = BTNode.Status.failure
	_fake_action.reset_ticks()
	_fake_composite.reset_ticks()
	await get_tree().process_frame
	
	assert_equal(_fake_action.get_status(), BTNode.Status.failure)
	assert_equal(_fake_composite.get_ticks(), 1)
	
	# fail parallel child and check that simple_parallel fails
	_facke_composite_action.tick_status = BTNode.Status.failure
	await get_tree().process_frame
	
	assert_equal(_simple_parallel.get_status(), _facke_composite_action.tick_status)
