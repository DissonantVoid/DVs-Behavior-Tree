@tool
extends EditorPlugin

const _debugger_plugin_script : Script = preload("res://addons/DVs_behavior_tree/debug/debugger_plugin.gd")
var _debugger_plugin : EditorDebuggerPlugin

func _enter_tree():
	_debugger_plugin = _debugger_plugin_script.new()
	add_autoload_singleton("BTDebuggerListener", "res://addons/DVs_behavior_tree/debug/debugger_listener_autoload.gd")
	add_debugger_plugin(_debugger_plugin)

func _exit_tree():
	remove_debugger_plugin(_debugger_plugin)
	remove_autoload_singleton("BTDebuggerListener")
