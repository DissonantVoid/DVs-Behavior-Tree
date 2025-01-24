@warning_ignore("redundant_await")

class_name UTTestRunner
extends Node

# settings
## Root directory.
@export_dir var _directory : String

@onready var _test_container : Node = $TestContainer

# components
@onready var _interface : PanelContainer = $CanvasLayer/MarginContainer/PanelContainer
var files_handler := UTFilesHandler.new()

const _test_method_prefix : String = "test_"

var _script_data : Dictionary # {script_path:script_data}
var _curr_script_data : _ScriptData = null

class _ScriptData:
	var script_ : Script
	
	var _methods : Array[String]
	var _failures : Dictionary # {method:[line, ..], ..}
	
	var _curr_method : String
	
	func add_method(method_name : String):
		_methods.append(method_name)
		_failures[method_name] = []
	
	func get_methods() -> Array[String]:
		return _methods
	
	func set_current_test_method(method : String):
		_curr_method = method
	
	func active_method_failed(stack : Array[Dictionary]):
		# TODO: line number is wrong
		_failures[_curr_method].append(stack[-3]["line"])
	
	func cleanup():
		_curr_method = ""
		for method_name : String in _failures:
			_failures[method_name].clear()
	
	func report() -> Dictionary:
		return _failures.duplicate(true) # duplicate to avoid cleanup() wipping array

class ResultEntry:
	var script_ : String
	var results : Dictionary # {method:[line, line...]}
	
	func _init(script : String, results : Dictionary):
		script_ = script
		self.results = results

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
	var result : Array[ResultEntry]
	
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
		for method_name : String in script_data.get_methods():
			script_data.set_current_test_method(method_name)
			await root.before_each()
			await root.call(method_name)
			await root.after_each()
		
		await root.after_all()
		
		# TODO: orphans detection
		#       also error if root has no children after before_all and before_each
		
		# report
		result.append(ResultEntry.new(script_path, script_data.report()))
		
		# cleanup
		script_data.cleanup()
		root.queue_free()
		_curr_script_data = null
	
	_interface.tests_completed(result)

func on_active_test_error():
	_curr_script_data.active_method_failed(get_stack())
