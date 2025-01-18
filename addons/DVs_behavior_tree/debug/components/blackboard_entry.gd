@tool
extends MarginContainer

@onready var _panel_style_box : StyleBox = $PanelContainer.get_theme_stylebox("panel")
@onready var _key_label : Label = $PanelContainer/HBoxContainer/Key
@onready var _value_label : Label = $PanelContainer/HBoxContainer/Value

const _even_panel_color : Color = Color("35314a")
const _odd_panel_color : Color = Color("4a4563")

# TODO: spread value over multiple lines if it's too long
#       also look into replacing this class with EditorProperty objects
#       to get something similar to Stack Tace variables
func setup(key : String, value : String):
	_key_label.text = key
	_value_label.text = value
	
	if get_index() % 2 == 0:
		_panel_style_box.bg_color = _even_panel_color
	else:
		_panel_style_box.bg_color = _odd_panel_color

func update_value(new_value : String):
	_value_label.text = new_value
