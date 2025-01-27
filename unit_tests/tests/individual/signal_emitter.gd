extends UTTestBase

const _scene : PackedScene = preload("res://unit_tests/tests/individual/signal_emitter.tscn")

var _scene_node : Node
var _agent : Node
var _behavior_tree : BTBehaviorTree
var _signal_emitter : BTSignalEmitter

func before_each():
	_scene_node = _scene.instantiate()
	_agent = _scene_node.get_node("Agent")
	_behavior_tree = _agent.get_node("BTBehaviorTree")
	_signal_emitter = _behavior_tree.get_node("BTSignalEmitter")
	add_child(_scene_node)

func after_each():
	_scene_node.queue_free()

func test_signals():
	await get_tree().process_frame
	
	# signal without args
	_signal_emitter.signal_name = &"a"
	_signal_emitter.arguments = []
	_behavior_tree.force_tick_node(_behavior_tree) # ensure enter() is called on signal_emitter to validate variables
	_behavior_tree.custom_tick()
	await get_tree().process_frame
	assert_equal(_agent.a_count, 1)
	
	# signal with args (wrong)
	_signal_emitter.signal_name = &"b"
	_signal_emitter.arguments = ["wrong", "args"]
	_behavior_tree.force_tick_node(_behavior_tree)
	_behavior_tree.custom_tick()
	await get_tree().process_frame
	assert_equal(_agent.b_count, 0)
	
	# signal with args (correct)
	_signal_emitter.signal_name = &"b"
	_signal_emitter.arguments = ["", 0, {}]
	_behavior_tree.force_tick_node(_behavior_tree)
	_behavior_tree.custom_tick()
	await get_tree().process_frame
	assert_equal(_agent.b_count, 1)
