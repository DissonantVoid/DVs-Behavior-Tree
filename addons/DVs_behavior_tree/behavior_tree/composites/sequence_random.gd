@tool
@icon("res://addons/DVs_behavior_tree/icons/sequence_random.svg")
class_name BTSequenceRandom
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/random_composite.gd"

## Similar to the normal sequence except children are ticked in a random order, when a child succeeds
## this picks a random next child.

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
		_set_status(Status.running)
	
	elif status == Status.success:
		# run next random child
		_active_child.exit(false)
		_active_child = _pick_rand_child()
		_active_child.enter()
		_set_status(Status.running)
	
	elif status == Status.failure:
		_set_status(Status.failure)
