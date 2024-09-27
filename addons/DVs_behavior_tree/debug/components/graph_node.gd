@tool
extends Control

signal action_pressed(action_type : String)

@onready var _stylebox : StyleBox = get_theme_stylebox("panel")
@onready var _connection_line : Line2D = $ConnectionLine
@onready var _name_label : Label = $MarginContainer/VBoxContainer/Top/Name/Name
@onready var _icon : TextureRect = $MarginContainer/VBoxContainer/Top/Name/Icon
@onready var _description_container : PanelContainer = $MarginContainer/VBoxContainer/PanelContainer
@onready var _description_text : RichTextLabel = $MarginContainer/VBoxContainer/PanelContainer/Description
@onready var _services_container : MarginContainer = $MarginContainer/VBoxContainer/ServicesContainer
@onready var _services_labels_container : VBoxContainer = $MarginContainer/VBoxContainer/ServicesContainer/VBoxContainer/VBoxContainer

@onready var _action_btn_open_blackboard : Button = $MarginContainer/VBoxContainer/ActionsContainer/Actions/OpenBlackboard

var _is_leaf : bool

const _off_color : Color = Color("4a4563")
const _on_main_path_color : Color = Color.WHITE
const _on_parallel_path_color : Color = Color("af9dd9")

var _tick_tween : Tween
const _tick_tween_time : float = 0.15
const _tick_tween_max_scale : float = 1.02

func setup(
node_name : String, class_name_ : String,
description : String, icon_path : String, is_leaf : bool,
services : Array[String]
):
	_name_label.text = node_name
	_is_leaf = is_leaf
	
	if description:
		_description_text.text = "[center]" + description + "[/center]"
	else:
		_description_container.hide()
	
	if icon_path:
		_icon.texture = load(icon_path)
	
	if class_name_ != "BTBehaviorTree": # NOTE: this works as long as user doesn't inherite BehaviorTree and adds class_name
		_action_btn_open_blackboard.hide()
	
	_services_container.visible = services.size() > 0
	for service_name : String in services:
		var label : Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = service_name
		_services_labels_container.add_child(label)

func set_graph_parent(parent : Control):
	await get_tree().process_frame # wait for positioning to finish
	
	var start : Vector2 = Vector2(size.x/2.0, 0.0)
	var end : Vector2 = parent.position + Vector2(parent.size.x/2.0, parent.size.y) - position
	
	_connection_line.add_point(start)
	_connection_line.add_point(Vector2(start.x, (end.y-start.y) / 2.0))
	_connection_line.add_point(Vector2(end.x, (end.y-start.y) / 2.0))
	_connection_line.add_point(end)

func enter(is_main_path : bool):
	if is_main_path:
		_connection_line.default_color = _on_main_path_color
		_stylebox.border_color = _on_main_path_color
	else:
		# TODO: if conditional abort condition node is entered naturally (entered by tree flow rather than ran in parallel by parent)
		#       it will not use parallel color. could be due a bug in the composite node itself
		_connection_line.default_color = _on_parallel_path_color
		_stylebox.border_color = _on_parallel_path_color

func exit(is_main_path : bool):
	_connection_line.default_color = _off_color
	_stylebox.border_color = _off_color

# TODO PRIORITY: a way to update status label, one way is to have branches
#       send their children's status before returning.
#       another is to have a func like set_last_status() that is called by nodes instead of returning the status
func tick(is_main_path : bool):
	if _is_leaf == false: return
	if _tick_tween && _tick_tween.is_running(): return
	
	_tick_tween = create_tween()
	_tick_tween.tween_property(
		self, "scale", Vector2.ONE * _tick_tween_max_scale, _tick_tween_time
	)
	_tick_tween.tween_property(
		self, "scale", Vector2.ONE, _tick_tween_time
	)

func _on_force_tick_pressed():
	action_pressed.emit("force_tick")

func _on_open_blackboard_pressed():
	action_pressed.emit("open_blackboard")

func _on_resized():
	# forces node's height to change in case a child was hidden
	await get_tree().process_frame
	reset_size()
