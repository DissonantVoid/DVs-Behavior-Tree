@tool
extends EditorDebuggerPlugin

const _debugger_ui_scene : PackedScene = preload("res://addons/DVs_behavior_tree/debug/debugger_ui.tscn")
var _debugger_ui : Control

const _message_prefix : String = "DVBehaviorTree"
var _session_id : int

func _setup_session(session_id : int):
	_session_id = session_id
	_debugger_ui = _debugger_ui_scene.instantiate()
	_debugger_ui.name = "Behavior Trees"
	
	var session : EditorDebuggerSession = get_session(session_id)
	session.add_session_tab(_debugger_ui)
	#session.remove_session_tab(_debugger_ui)
	session.started.connect(_on_session_started)
	session.stopped.connect(_on_session_stopped)
	
	_debugger_ui.setup(self)

func _has_capture(capture : String) -> bool:
	# this makes it so that _capture only receives messages with this prefix
	return capture == _message_prefix

func _on_session_started():
	_debugger_ui.start_monitoring()

func _on_session_stopped():
	_debugger_ui.stop_monitoring()

# TODO: a way to document data (using sub-classes perhaps)
#       so that both the sender and receiver know what to expect
#       minimizing bugs. or just do unit tests
func _capture(message : String, data : Array, session_id : int) -> bool:
	message = message.split(":")[1] # remove prefix
	
	if message == "tree_added":
		_debugger_ui.tree_added(data[0]["id"], data[0]["name"], data[0]["scene"])
		return true
	elif message == "tree_removed":
		_debugger_ui.tree_removed(data[0]["id"])
		return true
	elif message == "sending_tree_structure":
		_debugger_ui.active_tree_structure_received(
			data[0]["nodes"], data[0]["relations"]
		)
		return true
	elif message == "node_entered":
		_debugger_ui.active_tree_node_entered(data[0]["id"])
		return true
	elif message == "node_exited":
		_debugger_ui.active_tree_node_exited(data[0]["id"])
		return true
	elif message == "node_status_set":
		_debugger_ui.active_tree_node_status_set(
			data[0]["id"], data[0]["status"], data[0]["main_path"]
		)
		return true
	elif message == "composite_attachment_ticked":
		_debugger_ui.active_tree_comp_attachment_ticked(data[0]["name"], data[0]["composite_id"])
		return true
	elif message == "sending_blackboard_data":
		_debugger_ui.active_tree_blackboard_received(data[0]["blackboard"])
		return true
	elif message == "sending_global_blackboard_data":
		_debugger_ui.active_tree_blackboard_received(data[0]["blackboard"])
		return true
	
	return false

func send_debugger_ui_request(message : String, data : Dictionary):
	get_session(_session_id).send_message(_message_prefix + ":" + message, [data])
