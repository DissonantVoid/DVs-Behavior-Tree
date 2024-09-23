@tool
extends Control

@onready var _name_label : Label = $MarginContainer/VBoxContainer/HBoxContainer/Name

var _connection_line_pos : Vector2

# TODO: pass node type for icon, not sure how to cleanly work around godot not allowing passing types
#       see https://github.com/godotengine/godot-proposals/issues/2270
func setup(node_name : String):
	_name_label.text = node_name

func draw_connection_line(parent_pos : Vector2):
	_connection_line_pos = parent_pos
	queue_redraw()

func _draw():
	if _connection_line_pos:
		draw_line(
			# TODO: fucking broken, everything is broken AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			Vector2.ZERO, _connection_line_pos - global_position,
			Color.WHITE, 5.0
		)
