extends Node2D

@onready var _obstacles_container : Node2D = $Obstacles

const _obstance_scene : PackedScene = preload("obstacle.tscn")

func _input(event : InputEvent):
	if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		var obstacle := _obstance_scene.instantiate()
		obstacle.global_position = get_global_mouse_position()
		_obstacles_container.add_child(obstacle)

func get_obstacles() -> Array:
	return _obstacles_container.get_children()
