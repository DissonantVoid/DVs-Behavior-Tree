@warning_ignore("redundant_await")

class_name UTTestRunner
extends Node

# settings
## Root directory.
@export_dir var _directory : String
## If true, the output will not show success.
@export var _show_errors_only : bool = false

@onready var _test_container : Node = $TestContainer

# components
@onready var _interface : PanelContainer = $CanvasLayer/MarginContainer/PanelContainer
var files_handler := UTFilesHandler.new()

const _test_method_prefix : String = "test_"

var _script_data : Dictionary # {script_path:script_data}
var _curr_script_data : _ScriptData = null

class _ScriptData:
	var script_ : Script
	var _results : Array[MethodResult]
	
	var _curr_method : MethodResult
	
	func add_method(method_name : String):
		var method_result := MethodResult.new(method_name)
		_results.append(method_result)
	
	func get_methods() -> Array[MethodResult]:
		return _results
	
	func set_current_test_method(method : MethodResult):
		_curr_method = method
	
	func active_method_failed(message : String, stack : Array[Dictionary]):
		_curr_method.error_lines.append(stack[2]["line"]) # stack[0] is self, [1] is test base, [2] is derived
		_curr_method.error_messages.append(message)
	
	func cleanup():
		_curr_method = null
		
		for result : MethodResult in _results:
			result.error_lines.clear()
			result.error_messages.clear()
	
	func get_results() -> Array[MethodResult]:
		return _results

class MethodResult:
	func _init(method : String):
		self.method = method
	
	var method : String
	var error_lines : Array[int]
	var error_messages : Array[String]

func _ready():
	files_handler.setup(_directory)
	_interface.setup(self, _directory)
	
	# setup scripts data
	for script_path : String in files_handler.scripts.keys():
		var script : Script = load(script_path)
		var script_data := _ScriptData.new()
		script_data.script_ = script
		_script_data[script_path] = script_data
		
		# methods
		var methods : Array[Dictionary] = script.get_script_method_list()
		for method : Dictionary in methods:
			var method_name : String = method["name"]
			if(method_name.begins_with(_test_method_prefix) && method["args"].size() == 0):
				script_data.add_method(method_name)

func run_tests(scripts : Array[String]):
	var result : Array[Dictionary]
	
	# run tests
	for script_path : String in scripts:
		var script_data : _ScriptData = _script_data[script_path]
		_curr_script_data = script_data
		var root : Node = Node.new()
		root.set_script(script_data.script_)
		_test_container.add_child(root)
		
		root.error.connect(on_active_test_error)
		
		await root.before_all()
		
		# test methods
		for method : MethodResult in script_data.get_methods():
			script_data.set_current_test_method(method)
			await root.before_each()
			await root.call(method.method)
			
			await root.after_each()
			# check for orphans
			await get_tree().process_frame
			if root.get_child_count() > 0:
				# TODO: do something
				breakpoint
		
		await root.after_all()
		# check for orphans
		await get_tree().process_frame
		if root.get_child_count() > 0:
			breakpoint
		
		# report
		result.append({"script_path":script_path, "results":script_data.get_results()})
		
		# cleanup
		root.queue_free()
		_curr_script_data = null
	
	_interface.tests_completed(result, _show_errors_only)
	
	# cleanup script data, can't do this before _interface.tests_completed since results are passed by reference
	for script_path : String in scripts:
		var script_data : _ScriptData = _script_data[script_path]
		script_data.cleanup()

func on_active_test_error(message : String):
	_curr_script_data.active_method_failed(message, get_stack())
