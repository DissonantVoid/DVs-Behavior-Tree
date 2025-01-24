extends PanelContainer

@onready var _input_blocker : ColorRect = $"../InputBlocker"
@onready var _tree : Tree = $MarginContainer/HSplitContainer/VBoxContainer/Tree
@onready var _run_btn : Button = $MarginContainer/HSplitContainer/MarginContainer/VBoxContainer/Control/VBoxContainer/Run
@onready var _selected_scripts_label : Label = $MarginContainer/HSplitContainer/MarginContainer/VBoxContainer/Control/VBoxContainer/Selected
@onready var _output : RichTextLabel = $MarginContainer/HSplitContainer/MarginContainer/VBoxContainer/Results/Output

var _selected_scripts : Array[String]
var _test_runner : UTTestRunner

func setup(test_runner : UTTestRunner, directory_path : String):
	_test_runner = test_runner
	
	var setup_tree_recursive : Callable = func(folder_path : String, parent : TreeItem, func_ : Callable):
		var folder_item : TreeItem = _tree.create_item(parent)
		folder_item.set_text(0, folder_path.split("/")[-1] + "/")
		folder_item.set_meta("path", folder_path) # NOTE: corresponding file path of each item is stored as meta
		
		var scripts_paths : Array[String] = _test_runner.files_handler.get_scripts_in_folder(folder_path, false)
		for script_path : String in scripts_paths:
			var item : TreeItem = _tree.create_item(folder_item)
			item.set_text(0, script_path.get_file())
			item.set_meta("path", script_path)
		
		var sub_folders : Array = test_runner.files_handler.folders[folder_path]
		for folder : String in sub_folders:
			func_.call(folder, folder_item, func_)
	
	setup_tree_recursive.call(directory_path, null, setup_tree_recursive)

func _ready():
	_tree.cell_selected.connect(_on_tree_cell_selected)

func tests_completed(results : Array[UTTestRunner.ResultEntry]):
	_input_blocker.hide()
	
	var script_count : int = results.size()
	var methods_count : int = 0
	var success : int = 0
	
	for entery : UTTestRunner.ResultEntry in results:
		_output.text += entery.script_ + "\n"
		methods_count += entery.results.size()
		
		for method_name : String in entery.results.keys():
			if entery.results[method_name].is_empty():
				# no failures reported, assume success by default
				_output.text += "\t"
				_output.text += "[color=green][success][/color] #\n".format([method_name], "#")
				success += 1
			else:
				# failures
				_output.text += "\t"
				_output.text += "[color=red][failure][/color] #\n".format([method_name], "#")
				for line_num : int in entery.results[method_name]:
					_output.text += "\t\t"
					_output.text += "at line: #\n".format([str(line_num)], "#")
	
	# summery
	_output.text += "[# methods across # scripts tested, [color=green]#[/color] succeeded, [color=red]#[/color] failed]\n"\
		.format([methods_count, script_count, success, methods_count-success], "#")
	_output.text += "-".repeat(16) + "\n"

func _on_tree_cell_selected():
	if _tree.get_selected() == null:
		_run_btn.disabled = true
		_selected_scripts_label.text = "No scripts selected"
	else:
		_run_btn.disabled = false
		
		var cell_path : String = _tree.get_selected().get_meta("path")
		if cell_path.ends_with(".gd"):
			_selected_scripts = [cell_path]
			_selected_scripts_label.text = "1 script selected (#)".format([cell_path], "#")
		else:
			_selected_scripts = _test_runner.files_handler.get_scripts_in_folder(cell_path, true)
			_selected_scripts_label.text = "# scripts selected inside #".format([_selected_scripts.size(), cell_path], "#")

func _on_run_pressed():
	if _selected_scripts:
		# block input until tests are over
		_input_blocker.show()
		get_viewport().gui_release_focus()
		
		_test_runner.run_tests(_selected_scripts)
