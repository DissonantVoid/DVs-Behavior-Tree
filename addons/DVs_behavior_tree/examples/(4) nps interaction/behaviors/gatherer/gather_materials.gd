extends BTAction

var _target_materials : Node2D

func enter():
	super()
	
	_target_materials = get_tree().current_scene.materials_container.get_child(0)

func tick(delta : float):
	super(delta)
	
	var agent := behavior_tree.agent
	var direction : Vector2 =\
		(_target_materials.global_position - agent.global_position).normalized()
	agent.position += direction * agent.speed * delta
	
	if agent.global_position.distance_to(_target_materials.global_position) <= agent.min_distance_to_target:
		_target_materials.queue_free()
		_set_status(Status.success)
	else:
		_set_status(Status.running)
