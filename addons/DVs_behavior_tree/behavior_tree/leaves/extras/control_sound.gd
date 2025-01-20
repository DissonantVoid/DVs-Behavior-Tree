@tool
@icon("res://addons/DVs_behavior_tree/icons/control_sound.svg")
class_name BTControlSound
extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/action.gd"

## Calls different audio stream functions and optionally waits for it to finish.

enum StreamType {
	node, ## AudioStreamPlayer.
	_2d, ## AudioStreamPlayer2D.
	_3d ## AudioStreamPlayer3D.
}
enum Action {
	play, ## Play stream.
	pause, ## Pause stream.
	# do we need unpause?
	stop ## Stop stream.
}

## Stream type.
@export var stream_type : StreamType :
	set(value):
		stream_type = value
		notify_property_list_changed()
## Stream node for stream type of node.
@export var stream_node : AudioStreamPlayer
## Stream node for stream type of 2d.
@export var stream_2d : AudioStreamPlayer2D
## Stream node for stream type of 3d.
@export var stream_3d : AudioStreamPlayer3D
## Action to perform on stream.
@export var action : Action :
	set(value):
		action = value
		notify_property_list_changed()
## If true, waits for the stream to finish before setting status to success.
@export var wait_for_finish : bool

@export_category("Arguments")
@export var from_position : float = 0.0

var _is_waiting_for_finish : bool
var _is_stream_finished : bool

func enter():
	super()
	
	_is_waiting_for_finish = false
	_is_stream_finished = false

func exit(is_interrupted : bool):
	super(is_interrupted)
	
	if is_interrupted:
		var stream = _get_target_stream()
		if stream.finished.is_connected(_on_stream_finished):
			stream.finished.disconnect(_on_stream_finished)

func tick(delta : float):
	super(delta)
	var stream = _get_target_stream()
	
	if stream == null:
		_set_status(Status.failure)
		return
	
	if _is_waiting_for_finish:
		if _is_stream_finished:
			_set_status(Status.success)
			return
		else:
			_set_status(Status.running)
			return
	
	match action:
		Action.play:
			stream.play(from_position)
			if wait_for_finish == false:
				_set_status(Status.success)
			else:
				_is_waiting_for_finish = true
				stream.finished.connect(_on_stream_finished)
				_set_status(Status.running)
		Action.pause:
			stream.stream_paused = true
			_set_status(Status.success)
		Action.stop:
			stream.stop()
			_set_status(Status.success)

func _on_stream_finished():
	_is_stream_finished = true

func _get_target_stream() -> Variant:
	return stream_node if stream_type == StreamType.node else stream_2d if stream_type == StreamType._2d else stream_3d # abrakadabra madafakas!

func _validate_property(property : Dictionary):
	if property["name"] in ["wait_for_finish", "from_position"] && action != Action.play:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property["name"] == "stream_node" && stream_type != StreamType.node:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property["name"] == "stream_2d" && stream_type != StreamType._2d:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property["name"] == "stream_3d" && stream_type != StreamType._3d:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super()
	
	if _get_target_stream() == null:
		warnings.append("No stream node set")
	
	# no clean way to check if stream is loopable so we can push
	# warning if wait_for_finish is true but stream loops
	
	return warnings
