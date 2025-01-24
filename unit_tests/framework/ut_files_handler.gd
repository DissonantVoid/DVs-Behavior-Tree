class_name UTFilesHandler
extends RefCounted

# NOTE: paths are absolute (relative to res://)
var folders : Dictionary # {folder_path:[child_folders]}
var scripts : Dictionary # {script_path:folder}

func setup(directory_path : String):
	# get all scripts in _directory
	var get_scripts_recursive : Callable = func(dir : String, func_ : Callable):
		var directory := DirAccess.open(dir)
		assert(directory, "invalid directory")
		
		folders[dir] = []
		directory.list_dir_begin()
		var file_name : String = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				var child_folder_path : String = dir + "/" + file_name
				folders[dir].append(child_folder_path)
				func_.call(child_folder_path, func_)
			elif file_name.ends_with(".gd"):
				var script_path : String = dir + "/" + file_name
				var script : Script = load(script_path)
				# TODO: this assumes that UTTestBase is the base class and not the base of the base etc...
				#       feels hacky
				var base_script : Script = script.get_base_script()
				if base_script && base_script.get_global_name() == "UTTestBase":
					scripts[script_path] = dir
			
			file_name = directory.get_next()
	
	get_scripts_recursive.call(directory_path, get_scripts_recursive)

func get_scripts_in_folder(folder_path : String, include_subfolders : bool) -> Array[String]:
	var ret : Array[String]
	for script_path : String in scripts.keys():
		if scripts[script_path] == folder_path:
			ret.append(script_path)
	
	if include_subfolders:
		var sub_folders : Array = folders[folder_path]
		for folder : String in sub_folders:
			ret.append_array(get_scripts_in_folder(folder, true))
	
	return ret
