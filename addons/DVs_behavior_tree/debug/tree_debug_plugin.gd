@tool
extends EditorDebuggerPlugin

const _tree_graph_scene : PackedScene = preload("res://addons/DVs_behavior_tree/debug/debugger_ui.tscn")
var _tree_graph : Control

const _message_prefix : String = "DVBehaviorTree"
var _session_id : int

func _setup_session(session_id : int):
	_session_id = session_id
	_tree_graph = _tree_graph_scene.instantiate()
	_tree_graph.name = "Behavior Trees"
	
	var session : EditorDebuggerSession = get_session(session_id)
	session.add_session_tab(_tree_graph)
	#session.remove_session_tab(_tree_graph)
	#session.send_message()
	session.started.connect(_on_session_started)
	session.stopped.connect(_on_session_stopped)
	
	_tree_graph.setup(self)

func _has_capture(capture : String) -> bool:
	# this makes it so that _capture only receives messages starting with this
	return capture == _message_prefix

func _on_session_started():
	_tree_graph.start_monitoring()

func _on_session_stopped():
	_tree_graph.stop_monitoring()

# TODO: a way to document data (using structs perhaps)
#       so that both the sender and receiver know what to expect
#       minimizing bugs
func _capture(message : String, data : Array, session_id : int) -> bool:
	if message == _message_prefix + ":tree_added":
		_tree_graph.tree_added(data[0])
		return true
	elif message == _message_prefix + ":tree_removed":
		_tree_graph.tree_removed(data[0])
		return true
	elif message == _message_prefix + ":sending_tree_structure":
		_tree_graph.active_tree_structure_received(data[0])
		return true
	
	return false

func send_debugger_ui_request(message : String, data : Dictionary):
	get_session(_session_id).send_message(_message_prefix + ":" + message, [data])
