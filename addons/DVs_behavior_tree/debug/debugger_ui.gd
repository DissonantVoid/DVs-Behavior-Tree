@tool
extends MarginContainer

@onready var _graph_panel : Panel = $HBoxContainer/Panel
@onready var _graph_container : Control = $HBoxContainer/Panel/GraphContainer
@onready var _tree_list_container : VBoxContainer = $HBoxContainer/TreesMenu/MarginContainer/VBoxContainer

const _graph_node_scene : PackedScene = preload("res://addons/DVs_behavior_tree/debug/components/graph_node.tscn")

var _debugger : EditorDebuggerPlugin
var _existing_tree_ids : PackedInt64Array
var _active_tree_id : int = -1
var _id_to_graph_node_map : Dictionary # id:graph node

const _node_spacing : Vector2 = Vector2(300.0, 200.0)

const _max_zoom_in : float = 1.5
const _max_zoom_out : float = 0.2
const _zoom_increment : float = 0.1

var _is_panning : bool
const _pan_sensitivity : float = 0.7

func setup(debugger : EditorDebuggerPlugin):
	_debugger = debugger

func start_monitoring():
	# nothing to do here, behavior tree nodes will not send any messages unless debugger is active
	pass

func stop_monitoring():
	# session ended, clear everything
	for btn : Button in _tree_list_container.get_children():
		_remove_tree_data(btn.get_meta("id"))
	_existing_tree_ids.clear()

func tree_added(data : Dictionary):
	# NOTE: can't pass nodes between sessions :( I hate everything
	var btn : Button = Button.new()
	btn.text = str(data["name"])
	btn.toggle_mode = true
	btn.set_meta("id", data["id"])
	_tree_list_container.add_child(btn)
	btn.toggled.connect(_on_tree_list_btn_toggled.bind(btn))
	
	_existing_tree_ids.append(data["id"])

func tree_removed(data : Dictionary):
	_remove_tree_data(data["id"])

func _remove_tree_data(tree_id : int):
	var button : Button = null
	for btn : Button in _tree_list_container.get_children():
		if btn.get_meta("id") == tree_id:
			button = btn; break
	
	if _active_tree_id == tree_id:
		_clear_graph()
	
	_existing_tree_ids.remove_at(_existing_tree_ids.find(tree_id))
	button.queue_free()

func _on_tree_list_btn_toggled(toggled_on : bool, button : Button):
	if toggled_on == false:
		# prevent toggling off
		button.set_pressed_no_signal(true)
	else:
		_clear_graph()
		
		var id : int = button.get_meta("id")
		_active_tree_id = id
		
		# request full tree structure and wait for response
		_debugger.send_debugger_ui_request("requesting_tree_structure", {"id":id})

func active_tree_structure_received(data : Dictionary):
	# construct graph
	var ids_by_depth : Dictionary # array of ids
	for node_id : int in data["nodes"]:
		var graph : PanelContainer = _graph_node_scene.instantiate()
		_graph_container.add_child(graph)
		_id_to_graph_node_map[node_id] = graph
		
		var node_data : Dictionary = data["nodes"][node_id]
		var depth : int = node_data["depth"]
		if ids_by_depth.has(depth) == false: ids_by_depth[depth] = []
		ids_by_depth[depth].append(node_id)
		
		graph.setup(node_data["name"])
	
	# graph positioning
	for relation_parent_id : int in data["relations"]:
		for child_id : int in data["relations"][relation_parent_id]:
			var depth : int = data["nodes"][child_id]["depth"]
			#var depth_nodes_count : int = ids_by_depth[depth].size()
			var index_in_depth : int = ids_by_depth[depth].find(child_id)
			
			# TODO: this isn't accurate because we can't guarentee that all nodes in previous
			#       depth have been positioned
			var average_xpos_of_prev_depth : float = 0.0
			if depth > 0:
				for id : int in ids_by_depth[depth-1]:
					average_xpos_of_prev_depth += _id_to_graph_node_map[id].position.x
				average_xpos_of_prev_depth /= ids_by_depth[depth-1].size()
			
			var parent_graph_node : PanelContainer = _id_to_graph_node_map[relation_parent_id]
			var child_graph_node : PanelContainer = _id_to_graph_node_map[child_id]
			
			child_graph_node.position.x =\
				average_xpos_of_prev_depth + _node_spacing.x * index_in_depth
			child_graph_node.position.y =\
				parent_graph_node.position.y + _node_spacing.y # TODO: should take height of the highest sibling, and of parent into account
	
	# connect nodes
	for relation_parent_id : int in data["relations"]:
		for child_id : int in data["relations"][relation_parent_id]:
			var parent_graph_node : PanelContainer = _id_to_graph_node_map[relation_parent_id]
			var child_graph_node : PanelContainer = _id_to_graph_node_map[child_id]
			
			child_graph_node.draw_connection_line(parent_graph_node.global_position)
	
	_center_view_around_nodes()

func _clear_graph():
	if _is_panning: _is_panning = false
	_active_tree_id = -1
	_id_to_graph_node_map.clear()
	for child : Node in _graph_container.get_children():
		child.queue_free()

func _center_view_around_nodes():
	if _active_tree_id == -1: return
	
	var average_pos : Vector2 = Vector2.ZERO
	for graph_node : PanelContainer in _graph_container.get_children():
		average_pos += graph_node.position
	average_pos /= _graph_container.get_child_count()
	# TODO: broken
	_graph_container.position = average_pos - _graph_panel.size / 2.0# * _graph_container.scale

func _on_graph_panel_gui_input(event : InputEvent):
	if _active_tree_id == -1: return
	
	if event is InputEventMouseButton:
		# TODO: zoom from mouse position
		if event.pressed && event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# zoom in
			var zoom : float = min(_graph_container.scale.x + _zoom_increment, _max_zoom_in)
			_graph_container.pivot_offset = _graph_panel.get_local_mouse_position() + _graph_container.position
			_graph_container.scale = Vector2.ONE * zoom
		elif event.pressed && event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# zoom out
			var zoom : float = max(_graph_container.scale.x - _zoom_increment, _max_zoom_out)
			_graph_container.pivot_offset = _graph_panel.get_local_mouse_position() + _graph_container.position
			_graph_container.scale = Vector2.ONE * zoom
		
		# panning
		# TODO: panning should be limited around the tree
		elif event.pressed && event.button_index == MOUSE_BUTTON_LEFT && _is_panning == false:
			_is_panning = true
			_graph_panel.mouse_default_cursor_shape = Control.CURSOR_MOVE
		elif event.pressed == false && event.button_index == MOUSE_BUTTON_LEFT && _is_panning:
			_graph_panel.mouse_default_cursor_shape = Control.CURSOR_ARROW
			_is_panning = false
	
	elif event is InputEventMouseMotion && _is_panning:
		_graph_container.position += event.relative * _pan_sensitivity
