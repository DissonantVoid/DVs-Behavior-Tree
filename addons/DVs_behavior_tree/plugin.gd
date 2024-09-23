@tool
extends EditorPlugin

const _tree_debug_plugin_scene := preload("res://addons/DVs_behavior_tree/debug/tree_debug_plugin.gd")
var _tree_debug_plugin : EditorDebuggerPlugin

func _enter_tree():
	_tree_debug_plugin = _tree_debug_plugin_scene.new()
	
	add_debugger_plugin(_tree_debug_plugin)

func _exit_tree():
	remove_debugger_plugin(_tree_debug_plugin)
