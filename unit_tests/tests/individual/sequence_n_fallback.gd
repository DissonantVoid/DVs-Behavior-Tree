extends UTTestBase

const _scene : PackedScene = preload("res://unit_tests/tests/individual/sequence_n_fallback.tscn")

var _scene_node : Node
var _fake_composite : BTComposite

var _sequence : BTSequence
var _seq_fake_action1 : BTAction
var _seq_fake_action2 : BTAction
var _seq_fake_action3 : BTAction

var _fallback : BTFallback
var _fb_fake_action1 : BTAction
var _fb_fake_action2 : BTAction
var _fb_fake_action3 : BTAction

func before_each():
	_scene_node = _scene.instantiate()
	_fake_composite = _scene_node.get_node("BTBehaviorTree/FakeComposite")
	
	_sequence = _scene_node.get_node("BTBehaviorTree/FakeComposite/BTSequence")
	_seq_fake_action1 = _sequence.get_node("FakeAction")
	_seq_fake_action2 = _sequence.get_node("FakeAction2")
	_seq_fake_action3 = _sequence.get_node("FakeAction3")
	
	_fallback = _scene_node.get_node("BTBehaviorTree/FakeComposite/BTFallback")
	_fb_fake_action1 = _fallback.get_node("FakeAction")
	_fb_fake_action2 = _fallback.get_node("FakeAction2")
	_fb_fake_action3 = _fallback.get_node("FakeAction3")
	
	add_child(_scene_node)

func after_each():
	_scene_node.queue_free()

func test_seq_full():
	_fake_composite.pick_child = 0
	await get_tree().process_frame
	
	_seq_fake_action1.tick_status = BTNode.Status.success
	_seq_fake_action2.tick_status = BTNode.Status.success
	_seq_fake_action3.tick_status = BTNode.Status.success
	
	assert_equal(_sequence.get_active_child(), _seq_fake_action1)
	await _sequence.ticking
	await get_tree().process_frame
	
	assert_equal(_sequence.get_active_child(), _seq_fake_action2)
	await _sequence.ticking
	await get_tree().process_frame
	
	assert_equal(_sequence.get_active_child(), _seq_fake_action3)
	await _sequence.ticking
	await get_tree().process_frame
	
	assert_equal(_sequence.get_active_child(), _seq_fake_action1)

func test_seq_child_failure():
	_fake_composite.pick_child = 0
	await get_tree().process_frame
	
	_seq_fake_action1.tick_status = BTNode.Status.success
	_seq_fake_action2.tick_status = BTNode.Status.failure
	
	assert_equal(_sequence.get_active_child(), _seq_fake_action1)
	await _sequence.ticking
	await get_tree().process_frame
	
	assert_equal(_sequence.get_active_child(), _seq_fake_action2)
	await _sequence.ticking
	await get_tree().process_frame
	
	assert_equal(_sequence.get_active_child(), _seq_fake_action1)

func test_fb_full():
	_fake_composite.pick_child = 1
	await get_tree().process_frame
	
	_fb_fake_action1.tick_status = BTNode.Status.failure
	_fb_fake_action2.tick_status = BTNode.Status.failure
	_fb_fake_action3.tick_status = BTNode.Status.failure
	
	assert_equal(_fallback.get_active_child(), _fb_fake_action1)
	await _fallback.ticking
	await get_tree().process_frame
	
	assert_equal(_fallback.get_active_child(), _fb_fake_action2)
	await _fallback.ticking
	await get_tree().process_frame
	
	assert_equal(_fallback.get_active_child(), _fb_fake_action3)
	await _fallback.ticking
	await get_tree().process_frame
	
	assert_equal(_fallback.get_active_child(), _fb_fake_action1)

func test_fb_child_failure():
	_fake_composite.pick_child = 1
	await get_tree().process_frame
	
	_fb_fake_action1.tick_status = BTNode.Status.failure
	_fb_fake_action2.tick_status = BTNode.Status.success
	
	assert_equal(_fallback.get_active_child(), _fb_fake_action1)
	await _fallback.ticking
	await get_tree().process_frame
	
	assert_equal(_fallback.get_active_child(), _fb_fake_action2)
	await _fallback.ticking
	await get_tree().process_frame
	
	assert_equal(_fallback.get_active_child(), _fb_fake_action1)
