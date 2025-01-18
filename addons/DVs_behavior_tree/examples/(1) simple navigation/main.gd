extends Node2D

const _agent_scene : PackedScene = preload("agent.tscn")

func _input(event : InputEvent):
	if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		var agent := _agent_scene.instantiate()
		add_child(agent)
		agent.global_position = get_global_mouse_position()
