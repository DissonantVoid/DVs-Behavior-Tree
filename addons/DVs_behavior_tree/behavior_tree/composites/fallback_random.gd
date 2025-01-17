@tool
@icon("res://addons/DVs_behavior_tree/icons/fallback_random.svg")
class_name BTFallbackRandom
extends "res://addons/DVs_behavior_tree/behavior_tree/composites/random_composite.gd"

## Similar to the normal fallback except children are ticked in a random order, when a child fails
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
		_set_status(Status.success)
	
	elif status == Status.failure:
		# run next random child
		_active_child.exit(false)
		_active_child = _pick_rand_child()
		_active_child.enter()
		_set_status(Status.running)
