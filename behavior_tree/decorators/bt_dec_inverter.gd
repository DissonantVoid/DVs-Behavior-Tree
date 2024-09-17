class_name BtDecInverter
extends "res://behavior_tree/decorators/bt_decorator.gd"

func tick(delta : float) -> Status:
	if _active_child == null: return Status.failure
	
	var status : Status = _active_child.tick(delta)
	if status == Status.running:
		return Status.running
	elif status == Status.success:
		return Status.failure
	elif status == Status.failure:
		return Status.success
	
	# NoT aLl PaThS rEtUrN a VaLuE
	return Status.running
