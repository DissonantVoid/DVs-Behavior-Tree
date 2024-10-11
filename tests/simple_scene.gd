extends Node2D

func _input(event : InputEvent):
	if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		var agent := preload("res://tests/simple_agent.tscn").instantiate()
		add_child(agent)
		agent.global_position = get_global_mouse_position()
