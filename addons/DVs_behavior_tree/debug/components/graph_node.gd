@tool
extends Control

signal action_pressed(action_type : String)

@onready var _stylebox : StyleBox = get_theme_stylebox("panel")
@onready var _connection_line : Line2D = $ConnectionLine
@onready var _name_label : Label = $MarginContainer/VBoxContainer/Top/Name/Name
@onready var _icon : TextureRect = $MarginContainer/VBoxContainer/Top/Name/Icon
@onready var _status_label : Label = $MarginContainer/VBoxContainer/Top/Status
@onready var _description_container : PanelContainer = $MarginContainer/VBoxContainer/PanelContainer
@onready var _description_text : RichTextLabel = $MarginContainer/VBoxContainer/PanelContainer/Description
@onready var _services_container : MarginContainer = $MarginContainer/VBoxContainer/ServicesContainer
@onready var _services_labels_container : VBoxContainer = $MarginContainer/VBoxContainer/ServicesContainer/VBoxContainer/VBoxContainer

@onready var _action_btn_open_blackboard : Button = $MarginContainer/VBoxContainer/ActionsContainer/Actions/OpenBlackboard

var _last_status : BTNode.Status = BTNode.Status.undefined
var _is_leaf : bool

const _undefined_color : Color = Color("4a4563")
const _success_color : Color = Color.GREEN
const _failure_color : Color = Color.RED
const _running_color : Color = Color.ORANGE
const _parallel_overlay : Color = Color.BLACK
const _fadout_lerp_value : float = 1.8

const _line_off_color : Color = _undefined_color
const _line_on_color : Color = Color.WHITE
const _line_parallel_on_color : Color = Color.GRAY

var _tick_tween : Tween
const _tick_tween_time : float = 0.15
const _tick_tween_max_scale : float = 1.02

func setup(
node_name : String, class_name_ : String, status : BTNode.Status,
description : String, icon_path : String, is_leaf : bool,
services : Array[String]
):
	_name_label.text = node_name
	_is_leaf = is_leaf
	
	_last_status = status
	_calc_stylebox_color()
	
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

func _ready():
	set_process(false)

func _process(delta : float):
	_stylebox.border_color = lerp(
		_stylebox.border_color, _undefined_color, _fadout_lerp_value * delta
	)
	if _stylebox.border_color == _undefined_color:
		set_process(false)

func set_graph_parent(parent : Control):
	await get_tree().process_frame # wait for positioning to finish
	
	var start : Vector2 = Vector2(size.x/2.0, 0.0)
	var end : Vector2 = parent.position + Vector2(parent.size.x/2.0, parent.size.y) - position
	
	_connection_line.add_point(start)
	_connection_line.add_point(Vector2(start.x, (end.y-start.y) / 2.0))
	_connection_line.add_point(Vector2(end.x, (end.y-start.y) / 2.0))
	_connection_line.add_point(end)

func enter(is_main_path : bool): # TODO: light up services to indicate that they're running
	if is_main_path:
		return
	else:
		# TODO: if conditional abort condition node is entered naturally (entered by tree flow rather than ran in parallel by parent)
		#       it will not use parallel color. could be due a bug in the composite node itself
		return

func exit():
	return

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

func update_status(status : BTNode.Status, is_main_path : bool):
	_last_status = status
	
	var line_color : Color
	if status == BTNode.Status.running:
		line_color =\
			_line_on_color if is_main_path else _line_parallel_on_color
	else:
		line_color = _line_off_color
	_connection_line.default_color = line_color
	
	_calc_stylebox_color()
	_status_label.text = "Last Status: " + BTNode.Status.find_key(status)

func _calc_stylebox_color():
	var style_color : Color
	match _last_status:
		BTNode.Status.undefined:
			style_color = _undefined_color
		BTNode.Status.running:
			style_color = _running_color
		BTNode.Status.success:
			style_color = _success_color
		BTNode.Status.failure:
			style_color = _failure_color
	
	_stylebox.border_color = style_color
	_status_label.add_theme_color_override("font_color", style_color)
	
	set_process(true)

func _on_force_tick_pressed():
	action_pressed.emit("force_tick")

func _on_open_blackboard_pressed():
	action_pressed.emit("open_blackboard")

func _on_resized():
	# without this, when we hide a child, graph node will not shrink its height automatically
	# godot moment...
	await get_tree().process_frame
	reset_size()
