@tool
extends MarginContainer

@onready var _graph_panel : Panel = $HSplitContainer/Panel
@onready var _graph_container : Control = $HSplitContainer/Panel/GraphContainer
@onready var _tree_menu_panel : PanelContainer = $HSplitContainer/TreesMenu
@onready var _tree_menu_container : VBoxContainer = $HSplitContainer/TreesMenu/MarginContainer/ScrollContainer/VBoxContainer
@onready var _blackboard_data_panel : PanelContainer = $HSplitContainer/BlackboardData
@onready var _blackboard_data_container : VBoxContainer = $HSplitContainer/BlackboardData/MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer
@onready var _blackboard_data_name_label : Label = $HSplitContainer/BlackboardData/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/Name
@onready var _blackboard_update_timer : Timer = $BlackboardUpdateTimer
@onready var _options_panel : MarginContainer = $HSplitContainer/Panel/OptionsPanel
@onready var _no_active_tree_label : Label = $HSplitContainer/Panel/NoActiveTree

const _graph_node_scene : PackedScene = preload("res://addons/DVs_behavior_tree/debug/components/graph_node.tscn")
const _blackboard_entry_scene : PackedScene = preload("res://addons/DVs_behavior_tree/debug/components/blackboard_entry.tscn")

var _debugger : EditorDebuggerPlugin
var _existing_tree_ids : PackedInt64Array
var _active_tree_id : int = -1
var _id_to_graph_node_map : Dictionary # id:graph node
var _key_to_bb_entry_map : Dictionary # key(string):entry node
var _is_tracking_global_blackboard : bool

const _node_spacing : Vector2 = Vector2(100.0, 60.0)

const _max_zoom_in : float = 1.5
const _max_zoom_out : float = 0.2
const _zoom_increment : float = 0.1
var _is_panning : bool
const _pan_sensitivity : float = 0.7

func setup(debugger : EditorDebuggerPlugin):
	_debugger = debugger
	_options_panel.hide()

func start_monitoring():
	# nothing to do here, behavior tree nodes will not send any messages unless debugger is active
	pass

func stop_monitoring():
	# session ended, clear everything
	for btn : Button in _tree_menu_container.get_children():
		_remove_tree_menu_entry(btn.get_meta("id"))
	_existing_tree_ids.clear()

func tree_added(data : Dictionary):
	# NOTE: can't pass nodes between sessions :( I hate everything
	var btn : Button = Button.new()
	btn.text = str(data["name"])
	btn.toggle_mode = true
	btn.set_meta("id", data["id"])
	_tree_menu_container.add_child(btn)
	btn.toggled.connect(_on_tree_list_btn_toggled.bind(btn))
	
	_existing_tree_ids.append(data["id"])

func tree_removed(data : Dictionary):
	_remove_tree_menu_entry(data["id"])

func _remove_tree_menu_entry(tree_id : int):
	for btn : Button in _tree_menu_container.get_children():
		if btn.get_meta("id") == tree_id:
			btn.queue_free(); break
	
	if _active_tree_id == tree_id:
		_clear_graph()
	
	_existing_tree_ids.remove_at(_existing_tree_ids.find(tree_id)) # no .erase?!!

func _on_tree_list_btn_toggled(toggled_on : bool, button : Button):
	if toggled_on == false:
		# prevent toggling off
		button.set_pressed_no_signal(true)
	else:
		_clear_graph()
		
		var id : int = button.get_meta("id")
		_active_tree_id = id
		_no_active_tree_label.hide()
		_options_panel.show()
		
		# request full tree structure and wait for response
		_debugger.send_debugger_ui_request("requesting_tree_structure", {"id":id})

func active_tree_structure_received(data : Dictionary):
	# spawn graph nodes
	var ids_by_depth : Dictionary # depth:[ids]
	for node_id : int in data["nodes"]:
		var graph_node : PanelContainer = _graph_node_scene.instantiate()
		_graph_container.add_child(graph_node)
		_id_to_graph_node_map[node_id] = graph_node
		graph_node.action_pressed.connect(_on_graph_node_action_pressed.bind(graph_node))
		
		var node_data : Dictionary = data["nodes"][node_id]
		var depth : int = node_data["depth"]
		if ids_by_depth.has(depth) == false: ids_by_depth[depth] = []
		ids_by_depth[depth].append(node_id)
		
		graph_node.setup(
			node_data["name"], node_data["class_name"],
			node_data["description"],
			node_data["icon_path"], node_data["is_leaf"]
		)
		graph_node.reset_size()
	
	# graph positioning
	# TODO: the current approach of structuring each depth by equally spacing
	#       all nodes doesn't scale up. once we get to +5 layers it become hard to read
	#       come up with a better solution
	var max_height_of_prev_depth : float
	var max_height_of_this_depth : float
	for depth : int in ids_by_depth:
		if depth == 0:
			var root_graph_node : PanelContainer = _id_to_graph_node_map[ids_by_depth[0][0]]
			max_height_of_prev_depth = root_graph_node.size.y
			continue # keep root at 0,0
		
		var spacing_sum : float = (ids_by_depth[depth].size()-1) * _node_spacing.x # sum of all empty space between nodes
		var total_width : float = spacing_sum
		for i : int in ids_by_depth[depth].size(): 
			if i == 0: continue # don't count width of first node
			var graph_node : PanelContainer = _id_to_graph_node_map[ids_by_depth[depth][i]]
			total_width += graph_node.size.x
		
		for id : int in ids_by_depth[depth]:
			var index_in_depth : int = ids_by_depth[depth].find(id)
			
			# get mid X pos of all nodes in previous depth
			var middle_xpos_of_prev_depth : float = 0.0
			for id_of_prev_depth : int in ids_by_depth[depth-1]:
				middle_xpos_of_prev_depth += _id_to_graph_node_map[id_of_prev_depth].position.x
			middle_xpos_of_prev_depth /= ids_by_depth[depth-1].size()
			
			# get parent graph node
			var parent_graph_node : PanelContainer
			for relation_parent_id : int in data["relations"]:
				if data["relations"][relation_parent_id].has(id):
					parent_graph_node = _id_to_graph_node_map[relation_parent_id]
			
			var graph_node : PanelContainer = _id_to_graph_node_map[id]
			max_height_of_this_depth = max(max_height_of_this_depth, graph_node.size.y)
			
			graph_node.position.x =\
				(middle_xpos_of_prev_depth + (graph_node.size.x + _node_spacing.x) * index_in_depth) - total_width / 2.0
			graph_node.position.y =\
				parent_graph_node.position.y + max_height_of_prev_depth + _node_spacing.y
		
		max_height_of_prev_depth = max_height_of_this_depth
	
	# connect nodes
	for relation_parent_id : int in data["relations"]:
		for child_id : int in data["relations"][relation_parent_id]:
			var parent_graph_node : PanelContainer = _id_to_graph_node_map[relation_parent_id]
			var child_graph_node : PanelContainer = _id_to_graph_node_map[child_id]
			
			child_graph_node.draw_connection_line(
				parent_graph_node.position - child_graph_node.position +
				Vector2(parent_graph_node.size.x / 2.0, parent_graph_node.size.y)
			)
	
	_center_view_around_nodes()
	_debugger.send_debugger_ui_request("debugger_display_started", {"id":_active_tree_id})

func active_tree_node_entered(data : Dictionary):
	_id_to_graph_node_map[data["id"]].enter(data["main_path"])

func active_tree_node_exited(data : Dictionary):
	_id_to_graph_node_map[data["id"]].exit(data["main_path"])

func active_tree_node_ticked(data : Dictionary):
	_id_to_graph_node_map[data["id"]].tick(data["main_path"])

func active_tree_blackboard_received(data : Dictionary):
	if _is_tracking_global_blackboard:
		_blackboard_data_name_label.text = "Global Blackboard"
	else:
		_blackboard_data_name_label.text = "Tree Root Blackboard"
	
	var blackboard : Dictionary = data["data"]
	# check for deleted keys (in cache but not in blackboard var) and delete their entry
	for i : int in range(_key_to_bb_entry_map.size()-1, -1, -1):
		var key : String = _key_to_bb_entry_map.keys()[i]
		if blackboard.has(key) == false:
			_key_to_bb_entry_map[key].queue_free()
			_key_to_bb_entry_map.erase(key)
	
	for key : String in blackboard:
		if _key_to_bb_entry_map.has(key):
			# update cache
			_key_to_bb_entry_map[key].update_value(str(blackboard[key]))
		else:
			# key is new, create new entry
			var black_board_entry : MarginContainer = _blackboard_entry_scene.instantiate()
			_blackboard_data_container.add_child(black_board_entry)
			black_board_entry.setup(key, str(blackboard[key]))
				
			_key_to_bb_entry_map[key] = black_board_entry
	
	_tree_menu_panel.hide()
	_blackboard_data_panel.show()

func _clear_graph():
	if _active_tree_id == -1: return
	
	if _is_panning: _is_panning = false
	_active_tree_id = -1
	_no_active_tree_label.show()
	_options_panel.hide()
	_id_to_graph_node_map.clear()
	
	for child : Node in _graph_container.get_children():
		child.queue_free()
	
	_blackboard_update_timer.stop()
	if _blackboard_data_panel.visible:
		_clear_blackboard()
		_blackboard_data_panel.hide()
		_tree_menu_panel.show()
	
	_debugger.send_debugger_ui_request("debugger_display_ended", {"id":_active_tree_id})

func _clear_blackboard():
	for child : Node in _blackboard_data_container.get_children():
		child.queue_free()
	_key_to_bb_entry_map.clear()

func _center_view_around_nodes():
	if _active_tree_id == -1: return
	
	var average_pos : Vector2 = Vector2.ZERO
	for graph_node : PanelContainer in _graph_container.get_children():
		average_pos += graph_node.position + graph_node.size / 2.0
	average_pos /= _graph_container.get_child_count()
	
	_graph_container.pivot_offset = Vector2.ZERO
	var panel_center : Vector2 = (_graph_panel.size / 2.0)
	_graph_container.position = panel_center - average_pos * _graph_container.scale

func _on_graph_node_action_pressed(action_type : String, graph_node : PanelContainer):
	match action_type:
		"force_tick":
			var graph_id : int
			for id : int in _id_to_graph_node_map:
				if _id_to_graph_node_map[id] == graph_node:
					graph_id = id; break
			
			_debugger.send_debugger_ui_request(
				"requesting_force_tick",
				{"id":_active_tree_id, "target_id":graph_id}
			)
		"open_blackboard":
			_is_tracking_global_blackboard = false
			_request_blackboard_data()

func _on_graph_panel_gui_input(event : InputEvent):
	if _active_tree_id == -1: return
	
	#_graph_container.pivot_offset = Vector2.ZERO
	#var panel_center : Vector2 = (_graph_panel.size / 2.0)
	#_graph_container.position = panel_center - average_pos * _graph_container.scale
	
	if event is InputEventMouseButton:
		# TODO: zoom from mouse position
		if event.pressed && event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# zoom in
			var zoom : float = min(_graph_container.scale.x + _zoom_increment, _max_zoom_in)
			_graph_container.pivot_offset = Vector2.ZERO
			_graph_container.pivot_offset =\
				_graph_container.get_local_mouse_position() * _graph_container.scale
			_graph_container.scale = Vector2.ONE * zoom
		elif event.pressed && event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# zoom out
			var zoom : float = max(_graph_container.scale.x - _zoom_increment, _max_zoom_out)
			_graph_container.pivot_offset = Vector2.ZERO
			_graph_container.pivot_offset =\
				_graph_container.get_local_mouse_position() * _graph_container.scale
			_graph_container.scale = Vector2.ONE * zoom
		
		# panning
		elif event.pressed && event.button_index == MOUSE_BUTTON_LEFT && _is_panning == false:
			_is_panning = true
			_graph_panel.mouse_default_cursor_shape = Control.CURSOR_MOVE
		elif event.pressed == false && event.button_index == MOUSE_BUTTON_LEFT && _is_panning:
			_graph_panel.mouse_default_cursor_shape = Control.CURSOR_ARROW
			_is_panning = false
	
	elif event is InputEventMouseMotion && _is_panning:
		_graph_container.position += event.relative * _pan_sensitivity

func _on_blackboard_panel_close_pressed():
	_blackboard_update_timer.stop()
	_clear_blackboard()
	_blackboard_data_panel.hide()
	_tree_menu_panel.show()

func _on_center_view_pressed():
	_center_view_around_nodes()

func _request_blackboard_data():
	_debugger.send_debugger_ui_request(
		"requesting_blackboard_data", {"id":_active_tree_id, "global":_is_tracking_global_blackboard}
	)
	_blackboard_update_timer.start()

func _on_open_global_blackboard_pressed():
	_is_tracking_global_blackboard = true
	_request_blackboard_data()

func _on_blackboard_update_timer_timeout():
	_request_blackboard_data()
