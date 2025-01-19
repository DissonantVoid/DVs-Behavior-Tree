@tool
extends Control

signal action_pressed(action_type : String)

@onready var _stylebox : StyleBox = get_theme_stylebox("panel")
@onready var _connection_line : Line2D = $ConnectionLine
@onready var _name_label : Label = $MarginContainer/VBoxContainer/Top/Name/Name
@onready var _icon : TextureRect = $MarginContainer/VBoxContainer/Top/Name/Icon
@onready var _status_label : Label = $MarginContainer/VBoxContainer/Top/Status
@onready var _status_label_line : HSeparator = $MarginContainer/VBoxContainer/Top/Status/HSeparator
@onready var _description_container : PanelContainer = $MarginContainer/VBoxContainer/PanelContainer
@onready var _description_text : RichTextLabel = $MarginContainer/VBoxContainer/PanelContainer/Description
@onready var _attachments_container : MarginContainer = $MarginContainer/VBoxContainer/AttachmentsContainer
@onready var _attachments_container_panel : Panel = $MarginContainer/VBoxContainer/AttachmentsContainer/Panel
@onready var _attachments_labels_container : VBoxContainer = $MarginContainer/VBoxContainer/AttachmentsContainer/VBoxContainer/VBoxContainer

@onready var _action_btn_open_blackboard : Button = $MarginContainer/VBoxContainer/ActionsContainer/Actions/OpenBlackboard

var _last_status : BTNode.Status = BTNode.Status.undefined
var _is_leaf : bool

const _undefined_color : Color = Color("4a4563")
const _success_color : Color = Color("269e34")
const _failure_color : Color = Color("972738")
const _running_color : Color = Color("aa662e")
const _parallel_color : Color = Color("696775")
const _interrupted_color : Color = Color("8f688d")

const _line_off_color : Color = _undefined_color
const _line_on_color : Color = Color("d6c9ab")
const _attachment_blink_color : Color = Color("999999")

var _tick_tween : Tween
const _tick_tween_time : float = 0.2
const _tick_tween_max_scale : float = 1.05

var _stylebox_tween : Tween
const _stylebox_tween_time : float = 1.8

var _attachment_tweens : Array[Tween]
const _attachment_tween_time : float = 0.2

func setup(
node_name : String, class_name_ : String, status : BTNode.Status,
description : String, icon_path : String, is_leaf : bool,
attachments : Array[String]
):
	_name_label.text = node_name
	_is_leaf = is_leaf
	
	_last_status = status
	if _last_status == BTNode.Status.running:
		enter()
	set_status(_last_status, true)
	
	if description:
		_description_text.text = "[center]" + description + "[/center]"
	else:
		_description_container.hide()
	
	if icon_path:
		_icon.texture = load(icon_path)
	
	if class_name_ != "BTBehaviorTree": # NOTE: this works as long as user doesn't inherite BehaviorTree and adds class_name
		_action_btn_open_blackboard.hide()
	
	_attachments_container.visible = attachments.size() > 0
	_attachment_tweens.resize(attachments.size())
	for attachment_name : String in attachments:
		var label : Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.name = attachment_name # used as identifier
		label.text = attachment_name
		_attachments_labels_container.add_child(label)

func _ready():
	_status_label.pivot_offset = _status_label.size / 2.0 # center pivot for scaling effect

func set_graph_parent(parent : Control):
	var start : Vector2 = Vector2(size.x/2.0, 0.0)
	var end : Vector2 = parent.position + Vector2(parent.size.x/2.0, parent.size.y) - position
	
	_connection_line.add_point(start)
	_connection_line.add_point(Vector2(start.x, (end.y-start.y) / 2.0))
	_connection_line.add_point(Vector2(end.x, (end.y-start.y) / 2.0))
	_connection_line.add_point(end)

func enter():
	if _attachments_container.visible:
		_attachments_container_panel.get_theme_stylebox("panel").draw_center = true

func exit():
	if _attachments_container.visible:
		_attachments_container_panel.get_theme_stylebox("panel").draw_center = false

func set_status(status : BTNode.Status, is_main_path : bool):
	_last_status = status
	
	# line
	if status == BTNode.Status.running:
		_connection_line.default_color = _line_on_color if is_main_path else _parallel_color
		# display line above other lines
		_connection_line.z_index = 1
	else:
		_connection_line.default_color = _line_off_color
		_connection_line.z_index = 0
	
	# pick colors
	var status_color : Color
	var style_color : Color
	match _last_status:
		BTNode.Status.undefined:   status_color = _undefined_color
		BTNode.Status.running:     status_color = _running_color
		BTNode.Status.success:     status_color = _success_color
		BTNode.Status.failure:     status_color = _failure_color
		BTNode.Status.interrupted: status_color = _interrupted_color
	
	if is_main_path:
		style_color = status_color
	else:
		style_color = _parallel_color
	
	# status text
	_status_label.text = "- " + BTNode.Status.find_key(_last_status) + " -"
	_status_label.get_theme_stylebox("normal").bg_color = status_color
	_status_label_line.get_theme_stylebox("separator").color = status_color
	
	# stylebox border
	if _stylebox_tween && _stylebox_tween.is_valid():
		_stylebox_tween.kill()
	_stylebox.border_color = style_color
	_stylebox_tween = create_tween()
	_stylebox_tween.tween_property(_stylebox, "border_color", _undefined_color, _stylebox_tween_time)
	
	# scale animation for leaves
	if _is_leaf:
		if _tick_tween == null || _tick_tween.is_valid() == false:
			_tick_tween = create_tween()
			_tick_tween.tween_property(
				_status_label, "scale", Vector2.ONE * _tick_tween_max_scale, _tick_tween_time/2.0
			)
			_tick_tween.tween_property(
				_status_label, "scale", Vector2.ONE, _tick_tween_time/2.0
			)

func attachment_ticked(attachment_name : String):
	var label : Label = _attachments_labels_container.get_node(attachment_name)
	
	var prev_tween : Tween = _attachment_tweens[label.get_index()]
	if prev_tween == null || prev_tween.is_valid() == false:
		var new_tween : Tween = create_tween()
		new_tween.tween_method(
			_tween_label_color.bind(label),
			Color.WHITE, _attachment_blink_color, _attachment_tween_time/2.0
		)
		new_tween.tween_method(
			_tween_label_color.bind(label),
			_attachment_blink_color, Color.WHITE, _attachment_tween_time/2.0
		)
		_attachment_tweens[label.get_index()] = new_tween

func _on_force_tick_pressed():
	action_pressed.emit("force_tick")

func _on_open_blackboard_pressed():
	action_pressed.emit("open_blackboard")

func _on_resized():
	# without this, when we hide a child, graph node will not shrink its height automatically
	# godot moment...
	await get_tree().process_frame
	reset_size()

func _tween_label_color(color : Color, label : Label):
	label.add_theme_color_override("font_color", color)
