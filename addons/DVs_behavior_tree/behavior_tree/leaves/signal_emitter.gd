@tool
@icon("res://addons/DVs_behavior_tree/icons/signal_emitter.svg")
class_name BTSignalEmitter
extends BTAction

## Emits a signal defined in the agent script.

## The name of the signal
@export var signal_name : StringName :
	set(value):
		signal_name = value
		update_configuration_warnings()
## Signal arguments
@export var arguments : Array :
	set(value):
		arguments = value
		update_configuration_warnings()

var _is_runtime_valid : bool

func _ready():
	if Engine.is_editor_hint(): return
	
	_is_runtime_valid = _get_setup_warning().is_empty()

func tick(delta : float):
	super(delta)
	
	if _is_runtime_valid:
		var args : Array = [signal_name] + arguments
		behavior_tree.agent.callv("emit_signal", args)
		
		_set_status(Status.success)
	else:
		_set_status(Status.failure)

# TODO: need to call update_configuration_warnings when agent changes in root tree
func _get_configuration_warnings():
	var warnings : PackedStringArray = super()
	
	var warning : String = _get_setup_warning()
	if warning:
		warnings.append(warning)
	
	return warnings

func _get_setup_warning() -> String:
	# self.behavior_tree isn't set until run-time, so we do this manually
	# if we end up needing access to tree in the editor with other nodes in the future
	# we can change how self.behavior_tree is assigned
	var tree_root : BTBehaviorTree = null
	var parent : Node = self
	while true:
		parent = parent.get_parent()
		
		if parent is BTNode == false:
			break
		elif parent is BTBehaviorTree:
			tree_root = parent
			break
	
	if tree_root == null:
		return "Node has no BTBehaviorTree root"
	
	if tree_root.agent == null:
		return "No agent selected in tree root"
	
	if tree_root.agent.has_signal(signal_name) == false:
		return "No signal " + signal_name + " in agent script"
	
	# check that our arguments match signal arguments
	var list : Array[Dictionary] = tree_root.agent.get_signal_list()
	for data : Dictionary in list:
		if data["name"] == signal_name:
			var args : Array[Dictionary] = data["args"]
			# check that we're providing same args count
			if args.size() != arguments.size():
				return "Arguments count (#) doesn't match the expected count of the signal (#)".format([arguments.size(), args.size()], "#")
			
			# check that type of each provided arg match that of the signal
			for arg_i : int in args.size():
				var arg : Dictionary = args[arg_i]
				if arg["type"] == TYPE_NIL:
					# unspecified argument type
					continue
				
				if arg["type"] != typeof(arguments[arg_i]):
					return "Argument at index # (#) doesn't match the expected type of the signal (#)".format([str(arg_i), type_string(typeof(arguments[arg_i])), type_string(arg["type"])],"#")
	
	return ""
