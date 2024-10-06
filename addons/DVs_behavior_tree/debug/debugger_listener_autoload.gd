extends Node

# this handles sending and receiving debugger messages on the game side since
# only one capture of the same prefix may exist

signal debugger_message_received(message : String, data : Array)

const _capture_prefix : String = "DVBehaviorTree"

func _enter_tree():
	if EngineDebugger.is_active():
		EngineDebugger.register_message_capture(
			_capture_prefix, _on_debugger_message_received
		)

func _exit_tree():
	if EngineDebugger.is_active():
		EngineDebugger.unregister_message_capture(_capture_prefix)

func send_message(message : String, data : Dictionary):
	if EngineDebugger.is_active():
		EngineDebugger.send_message(_capture_prefix + ":" + message, [data])

func _on_debugger_message_received(message : String, data : Array) -> bool:
	debugger_message_received.emit(message, data)
	return true
