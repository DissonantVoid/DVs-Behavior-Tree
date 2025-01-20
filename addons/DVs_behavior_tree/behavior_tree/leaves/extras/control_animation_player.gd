@tool
@icon("res://addons/DVs_behavior_tree/icons/control_animation_player.svg")
class_name BTControlAnimPlayer
extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/action.gd"

## Calls different animation player functions and optionally waits for it to finish.

enum Action {
	play, ## Corresponds to animation_player.play().
	play_backwards, ## Corresponds to animation_player.play_backwards().
	pause, ## Corresponds to animation_player.pause().
	stop ## Corresponds to animation_player.stop().
}

## Path to the animation player node.
@export var animation_player : AnimationPlayer
## Determines what function of the animation player to call.
@export var action : Action :
	set(value):
		action = value
		notify_property_list_changed()
## If true, waits for the animation to finish before setting status to success.
@export var wait_for_finish : bool

@export_category("Arguments")
@export var animation_name : StringName
@export var custom_blend : float = -1.0
@export var custom_speed : float = 1.0
@export var from_end : bool = false
@export var keep_state : bool = false

var _is_waiting_for_finish : bool
var _is_animation_finished : bool

func enter():
	super()
	
	_is_waiting_for_finish = false
	_is_animation_finished = false

func exit(is_interrupted : bool):
	super(is_interrupted)
	
	if is_interrupted:
		if animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.disconnect(_on_animation_finished)

func tick(delta : float):
	super(delta)
	
	if (animation_player == null ||
	((action == Action.play || action == Action.play_backwards) && animation_player.has_animation(animation_name) == false)):
		_set_status(Status.failure)
		return
	
	if _is_waiting_for_finish:
		if _is_animation_finished:
			_set_status(Status.success)
			return
		else:
			_set_status(Status.running)
			return
	
	match action:
		Action.play:
			animation_player.play(animation_name, custom_blend, custom_speed, from_end)
			if wait_for_finish == false:
				_set_status(Status.success)
			else:
				_is_waiting_for_finish = true
				animation_player.animation_finished.connect(_on_animation_finished)
				_set_status(Status.running)
		Action.play_backwards:
			animation_player.play_backwards(animation_name, custom_blend)
			if wait_for_finish == false:
				_set_status(Status.success)
			else:
				_is_waiting_for_finish = true
				animation_player.animation_finished.connect(_on_animation_finished)
				_set_status(Status.running)
			
		Action.pause:
			animation_player.pause()
			_set_status(Status.success)
		Action.stop:
			animation_player.stop(keep_state)
			_set_status(Status.success)

func _on_animation_finished(anim_name : StringName):
	_is_animation_finished = true

func _validate_property(property : Dictionary):
	var prop_name : String = property["name"]
	var visible : bool = true
	
	if action == Action.play:
		if prop_name == "keep_state":
			visible = false
	elif action == Action.play_backwards:
		if prop_name in ["custom_speed", "from_end", "keep_state"]:
			visible = false
	elif  action == Action.pause:
		if prop_name in [
			"wait_for_finish", "animation_name", "custom_blend", "custom_speed", "from_end", "keep_state"
		]:
			visible = false
	elif action == Action.stop:
		if prop_name in [
			"wait_for_finish", "animation_name", "custom_blend", "custom_speed", "from_end"
		]:
			visible = false
	
	if visible == false:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super()
	
	if animation_player == null:
		warnings.append("No animation player node set")
	else:
		if action == Action.play || action == Action.play_backwards:
			if animation_name.is_empty():
				warnings.append("No animation name provided")
			else:
				if animation_player.has_animation(animation_name) == false:
					# NOTE: this assumes that animations will not be added/removed
					#       from animation player at run-time
					warnings.append("Animation player has no animation with the name " + animation_name)
				elif wait_for_finish && animation_player.get_animation(animation_name).loop_mode != Animation.LOOP_NONE:
					warnings.append("Animation " + animation_name + " is looping which means wait_for_finish will cause this node to wait forever")
	
	return warnings
