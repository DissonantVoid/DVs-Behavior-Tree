@warning_ignore("redundant_await")

class_name UTTestRunner
extends Node

# TODO: UI to control what to run and visualize results better

@export_dir var _directory : String
@export var _report_failure_only : bool = false

const _test_method_prefix : String = "test_"

var _scripts_by_folder : Dictionary # {folder:[_ScriptData, ..]}
var _curr_script_data : _ScriptData

class _ScriptData:
	var script_ : Script
	
	var _methods : Array[String]
	var _failures : Dictionary # {method:[stack, ..], ..}
	
	var _curr_method : String
	
	func add_method(method_name : String):
		_methods.append(method_name)
		_failures[method_name] = []
	
	func get_methods() -> Array[String]:
		return _methods
	
	func set_active_method(method : String):
		_curr_method = method
	
	func active_method_failed(stack : Array[Dictionary]):
		_failures[_curr_method].append(stack[-3])
	
	func report(failure_only : bool):
		for method : String in _failures.keys():
			if _failures[method].is_empty():
				if failure_only == false:
					# no failures reported, assume success by default
					print("[success] #:#".format(
						[script_.resource_path.get_file(), method], "#")
					)
			else:
				# failures
				print("[failure] #:#".format(
					[script_.resource_path.get_file(), method], "#")
				)
				for stack : Dictionary in _failures[method]:
					print("\tat line: " + str(stack["line"]))

func _ready():
	# get all scripts in _directory
	var script_paths : Array[String]
	var get_scripts_recursive : Callable = func(dir : String, func_ : Callable):
		var directory := DirAccess.open(dir)
		assert(directory, "invalid directory")
		
		directory.list_dir_begin()
		var file_name : String = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				func_.call(dir + "/" + file_name, func_)
			else:
				if file_name.ends_with(".gd"):
					script_paths.append(dir + "/" + file_name)
			
			file_name = directory.get_next()
	get_scripts_recursive.call(_directory, get_scripts_recursive)
	
	# setup scripts data
	for path : String in script_paths:
		var script : Script = load(path)
		# TODO: this assumes that all test scripts will inherite UTTestBase
		#       and not double inherite it, also assumes that the derived
		#       won't declare a class_name. this feels hacky
		if script.get_base_script().get_global_name() == "UTTestBase":
			var dir_name : String = path.get_base_dir().substr(_directory.length()+1) # subtract _directory from the path
			if _scripts_by_folder.has(dir_name) == false:
				_scripts_by_folder[dir_name] = []
			
			var script_data := _ScriptData.new()
			script_data.script_ = script
			_scripts_by_folder[dir_name].append(script_data)
			
			# methods
			var methods : Array[Dictionary] = script.get_script_method_list()
			for method : Dictionary in methods:
				var method_name : String = method["name"]
				if(method_name.begins_with(_test_method_prefix) && method["args"].size() == 0):
					script_data.add_method(method_name)
	
	# run tests
	for folder_entry : String in _scripts_by_folder.keys():
		var scripts_in_folder : Array = _scripts_by_folder[folder_entry]
		for script_data : _ScriptData in scripts_in_folder:
			_curr_script_data = script_data
			var root : Node = Node.new()
			root.set_script(script_data.script_)
			add_child(root)
			
			# setup test node
			root.test_runner = self
			
			await root.before_all()
			
			# test methods
			for method_name : String in script_data.get_methods():
				script_data.set_active_method(method_name)
				await root.before_each()
				await root.call(method_name)
				await root.after_each()
			
			await root.after_all()
			
			# TODO: orphans detection
			
			# cleanup
			root.queue_free()
			_curr_script_data = null
	
	# TODO: stats (how many succeded/failed)
	
	# report
	for folder_entry : String in _scripts_by_folder.keys():
		for script_data : _ScriptData in _scripts_by_folder[folder_entry]:
			script_data.report(_report_failure_only)
	
	await get_tree().create_timer(1).timeout # wait for print() to display before quiting
	get_tree().quit()

func eyo_we_got_problems_chief():
	_curr_script_data.active_method_failed(get_stack())
