extends Node2D

@onready var target : Sprite2D = $Target

const _dog_scene : PackedScene = preload("dog.tscn")

func _input(event : InputEvent):
	if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		var dawg := _dog_scene.instantiate()
		add_child(dawg)
		dawg.global_position = get_global_mouse_position()
