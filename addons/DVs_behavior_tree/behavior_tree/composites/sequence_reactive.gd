@tool
@icon("res://addons/DVs_behavior_tree/icons/sequence_reactive.svg")
class_name BTSequenceReactive
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/composite.gd"

## Similar to the normal sequence except when a child returns running
## this will start over from the first child and return running. The sequence is reactive
## in the sense that it rechecks previous children if a long running child is active
## reacting to any previous child as soon as its status goes from success to failure.

func enter():
	super()
	
	if _active_child:
		_active_child.enter()

func tick(delta : float):
	super(delta)
	if _active_child == null:
		_set_status(Status.failure)
		return
	
	_active_child.tick(delta)
	var status : Status = _active_child.get_status()
	if status == Status.running:
		# start over
		_active_child.exit(true)
		_active_child = _get_next_valid_child()
		_set_status(Status.running)
		
	elif status == Status.success:
		# run next child
		var next_child : BTNode = _get_next_valid_child(_active_child.get_index())
		if next_child == null:
			# ran all children
			_set_status(Status.success)
		else:
			# next child
			_active_child.exit(false)
			_active_child = next_child
			_active_child.enter()
			_set_status(Status.running)
		
	elif status == Status.failure:
		_set_status(Status.failure)
