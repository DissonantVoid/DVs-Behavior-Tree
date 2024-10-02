@tool
extends MarginContainer

# TODO: improve trees menu so monitoring and navigation multiple trees is easier

@onready var _graph_panel : Panel = $HSplitContainer/TreeGraph
@onready var _graph_container : Control = $HSplitContainer/TreeGraph/GraphContainer
@onready var _tree_menu_panel : PanelContainer = $HSplitContainer/TreesMenu
@onready var _tree_menu_container : VBoxContainer = $HSplitContainer/TreesMenu/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
@onready var _blackboard_data_panel : PanelContainer = $HSplitContainer/BlackboardData
@onready var _blackboard_data_container : VBoxContainer = $HSplitContainer/BlackboardData/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/VBoxContainer
@onready var _blackboard_data_name_label : Label = $HSplitContainer/BlackboardData/MarginContainer/VBoxContainer/HBoxContainer/Name
@onready var _blackboard_data_empty_label : Label = $HSplitContainer/BlackboardData/MarginContainer/Empty
@onready var _blackboard_update_timer : Timer = $BlackboardUpdateTimer
@onready var _options_panel : MarginContainer = $HSplitContainer/TreeGraph/OptionsPanel
@onready var _no_selected_tree_label : Label = $HSplitContainer/TreeGraph/NoSelectedTree

const _graph_node_scene : PackedScene = preload("res://addons/DVs_behavior_tree/debug/components/graph_node.tscn")
const _blackboard_entry_scene : PackedScene = preload("res://addons/DVs_behavior_tree/debug/components/blackboard_entry.tscn")

var _debugger : EditorDebuggerPlugin
var _existing_tree_ids : PackedInt64Array
var _active_tree_id : int = -1
var _id_to_graph_node_map : Dictionary # id:graph node
var _key_to_bb_entry_map : Dictionary # key(string):blackboard entry node
var _is_tracking_global_blackboard : bool

const _node_spacing : Vector2 = Vector2(70.0, 50.0)
const _group_x_spacing : float = _node_spacing.x * 2.2

const _max_zoom_in : float = 1.4
const _max_zoom_out : float = 0.1
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

func tree_added(id : int, name_ : String):
	# NOTE: can't pass nodes between the editor and running game :(
	var btn : Button = Button.new()
	btn.text = name_
	btn.toggle_mode = true
	btn.set_meta("id", id)
	_tree_menu_container.add_child(btn)
	btn.toggled.connect(_on_tree_list_btn_toggled.bind(btn))
	
	_existing_tree_ids.append(id)

func tree_removed(id : int):
	_remove_tree_menu_entry(id)

# see: https://williamyaoh.com/posts/2023-04-22-drawing-trees-functionally.html
func active_tree_structure_received(nodes : Dictionary, relations : Dictionary):
	# WARNING: let there be known that only the bravest and most battle hardened of programmers may enter
	#          this demonic realm. this place has already taken the life energy of the poor soul
	#          that made it, he was broken, twisted and shattered into a thousand pieces, and he
	#          will never be the same again. if you value your sanity you shall take back the road
	#          that lead you here and live your life to the fullest, knowing that you didn't have to
	#          witness what's bellow. that you were one of thoese who got to keep all their brain cells.
	#          if you wish to modify the inner workings of this hellish code or fix a bug, you would
	#          do best to live with that bug rather than take a single peek at this. YOU. Have. Been. Warned.
	
	var ids_by_depth : Dictionary # depth:[ids]
	
	# Step1: spawn graph nodes
	for node_id : int in nodes:
		var graph_node : Control = _graph_node_scene.instantiate()
		_graph_container.add_child(graph_node)
		_id_to_graph_node_map[node_id] = graph_node
		graph_node.action_pressed.connect(_on_graph_node_action_pressed.bind(graph_node))
		
		var node_data : Dictionary = nodes[node_id]
		var depth : int = node_data["depth"]
		if ids_by_depth.has(depth) == false: ids_by_depth[depth] = []
		ids_by_depth[depth].append(node_id)
		
		graph_node.setup(
			node_data["name"], node_data["class_name"],
			node_data["status"], node_data["description"],
			node_data["icon_path"], node_data["is_leaf"],
			node_data["attachments"]
		)
		graph_node.reset_size()
	
	# Step2: positioning
	var height_of_prev_depth : float
	for depth : int in ids_by_depth:
		if depth == 0:
			var root_graph_node : Control = _id_to_graph_node_map[ids_by_depth[0][0]]
			height_of_prev_depth = root_graph_node.size.y
			continue # keep root at 0,0
		
		var height_of_this_depth : float
		for parent_id : int in ids_by_depth[depth-1]:
			if relations.has(parent_id) == false:
				# parent in previous depth may not have any children
				continue
			
			var children_ids : PackedInt64Array = relations[parent_id]
			
			# calculate total width of all children in a group
			# NOTE: a group is all children in a specific depth that share the same parent
			var spacing_sum : float = (children_ids.size()-1) * _node_spacing.x # sum of all empty space between nodes
			var total_width : float = spacing_sum
			for i : int in children_ids.size():
				var graph_node : Control = _id_to_graph_node_map[children_ids[i]]
				total_width += graph_node.size.x
			
			# space out nodes in group and position group's center under parent's center
			var parent_graph_node : Control = _id_to_graph_node_map[parent_id]
			for i : int in children_ids.size():
				var child_id : int = children_ids[i]
				var graph_node : Control = _id_to_graph_node_map[child_id]
				height_of_this_depth = max(height_of_this_depth, graph_node.size.y)
				
				var parent_x_center : float = parent_graph_node.position.x + parent_graph_node.size.x / 2.0
				graph_node.position.x =\
					(parent_x_center + (graph_node.size.x + _node_spacing.x) * i) - total_width / 2.0
				graph_node.position.y =\
					parent_graph_node.position.y + height_of_prev_depth + _node_spacing.y
				graph_node.set_graph_parent(parent_graph_node)
		
		height_of_prev_depth = height_of_this_depth
	
	var get_parent_graph_node : Callable = func(child_id : int) -> Control:
		for parent_id : int in relations:
			if relations[parent_id].has(child_id):
				return _id_to_graph_node_map[parent_id]
		return null
	
	# Step3: eliminating intersections
	for depth : int in ids_by_depth:
		if depth == 0: continue
		
		var last_parent_graph_node : Control = null
		for i : int in ids_by_depth[depth].size():
			var id : int = ids_by_depth[depth][i]
			var parent_graph_node : Control = get_parent_graph_node.call(id)
			
			# detect if we've entered a new group
			var is_new_group : bool = false
			if parent_graph_node != last_parent_graph_node && i > 1:
				is_new_group = true
			
			if is_new_group:
				# lm=left most node of new group. rm=right most node of past group
				var lm_node : Control = _id_to_graph_node_map[id]
				var rm_node : Control = _id_to_graph_node_map[ids_by_depth[depth][i-1]]
				
				# check if leftmost node of new group group is colliding or past rightmost of prev group
				var rm_end : float = rm_node.position.x + rm_node.size.x
				if rm_end + _group_x_spacing >= lm_node.position.x:
					var x_distance : float =\
						(rm_end + _group_x_spacing - lm_node.position.x) / 2.0
					
					var lm_parent : Control = parent_graph_node
					var rm_parent : Control = last_parent_graph_node
					if lm_parent == rm_parent:
						lm_node.position.x += x_distance
						rm_node.position.x -= x_distance
					else:
						# iterate back up the tree until we reach common ancestor
						var iteration_depth : int = depth-1
						while true:
							var lm_parent_id : int = _id_to_graph_node_map.find_key(lm_parent)
							var lm_grandparent : Control =\
								get_parent_graph_node.call(lm_parent_id)
							var rm_parent_id : int = _id_to_graph_node_map.find_key(rm_parent)
							var rm_grandparent : Control =\
								get_parent_graph_node.call(rm_parent_id)
							
							# TODO: use godot's parent/child system for this so we only need to push the ancestor
							#       for all children to move
							if lm_grandparent == rm_grandparent:
								# common ancestor found. push all nodes below the ancestor to the left or right
								# TODO: this seems to cause issues where the common ancestor isn't the CA of other nodes in the same depth
								#       so not all nodes at the lm and rm depth get pushed
								var push_nodes_recursive : Callable = func(graph_node_id : int, x_offset : float, func_ : Callable):
									_id_to_graph_node_map[graph_node_id].position.x += x_offset
									if relations.has(graph_node_id):
										for child_id : int in relations[graph_node_id]:
											func_.call(child_id, x_offset, func_)
								
								var ids_in_iter_depth : PackedInt64Array = ids_by_depth[iteration_depth]
								var lm_furthest_parent_idx : int = ids_in_iter_depth.find(lm_parent_id)
								
								for j : int in ids_in_iter_depth.size():
									# push node and its children to the right if it's the ancestor of the lm node
									# or to the right of it. otherwise push to the left
									var offset : float = x_distance if j >= lm_furthest_parent_idx else -x_distance
									push_nodes_recursive.call(ids_in_iter_depth[j], offset, push_nodes_recursive)
								
								break 
							
							lm_parent = lm_grandparent
							rm_parent = rm_grandparent
							iteration_depth -= 1
			
			last_parent_graph_node = parent_graph_node
	
	_center_view_around_graph()
	_debugger.send_debugger_ui_request("debugger_display_started", {"id":_active_tree_id})

func active_tree_node_entered(id : int):
	_id_to_graph_node_map[id].enter()

func active_tree_node_exited(id : int):
	_id_to_graph_node_map[id].exit()

func active_tree_node_ticked(id : int, main_path : bool):
	_id_to_graph_node_map[id].tick(main_path)

func active_tree_node_status_changed(id : int, status : BTNode.Status, main_path : bool):
	_id_to_graph_node_map[id].update_status(status, main_path)

func active_tree_blackboard_received(blackboard : Dictionary):
	if _is_tracking_global_blackboard:
		_blackboard_data_name_label.text = "Global Blackboard"
	else:
		_blackboard_data_name_label.text = "Blackboard"
	
	_blackboard_data_empty_label.visible = blackboard.is_empty()
	# check for deleted keys (in cache but not in blackboard var) and delete their entry
	for i : int in range(_key_to_bb_entry_map.size()-1, -1, -1):
		var key : String = _key_to_bb_entry_map.keys()[i]
		if blackboard.has(key) == false:
			_key_to_bb_entry_map[key].queue_free()
			_key_to_bb_entry_map.erase(key)
	
	for key : Variant in blackboard:
		var key_str : String = str(key)
		var value_str : String = str(blackboard[key])
		
		if _key_to_bb_entry_map.has(key_str):
			# update cache
			_key_to_bb_entry_map[key_str].update_value(value_str)
		else:
			# key is new, create new entry
			var black_board_entry : MarginContainer = _blackboard_entry_scene.instantiate()
			_blackboard_data_container.add_child(black_board_entry)
			black_board_entry.setup(key_str, value_str)
			
			_key_to_bb_entry_map[key_str] = black_board_entry
	
	_tree_menu_panel.hide()
	_blackboard_data_panel.show()

func _clear_graph():
	if _active_tree_id == -1: return
	
	if _is_panning: _is_panning = false
	_active_tree_id = -1
	_no_selected_tree_label.show()
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
		_no_selected_tree_label.hide()
		_options_panel.show()
		
		# request full tree structure and wait for response
		_debugger.send_debugger_ui_request("requesting_tree_structure", {"id":id})

func _clear_blackboard():
	for child : Node in _blackboard_data_container.get_children():
		child.queue_free()
	_key_to_bb_entry_map.clear()

func _center_view_around_graph():
	if _active_tree_id == -1: return
	
	var average_pos : Vector2 = Vector2.ZERO
	for graph_node : Control in _graph_container.get_children():
		average_pos += graph_node.position + graph_node.size / 2.0
	average_pos /= _graph_container.get_child_count()
	
	_graph_container.pivot_offset = Vector2.ZERO
	var panel_center : Vector2 = (_graph_panel.size / 2.0)
	_graph_container.position = panel_center - average_pos * _graph_container.scale

func _on_graph_node_action_pressed(action_type : String, graph_node : Control):
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
			_request_blackboard_content()

func _on_graph_panel_gui_input(event : InputEvent):
	if _active_tree_id == -1: return
	
	# graph navigation
	if event is InputEventMouseButton:
		if (event.pressed &&
		(event.button_index == MOUSE_BUTTON_WHEEL_UP || event.button_index == MOUSE_BUTTON_WHEEL_DOWN)):
			var zoom : float
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				# zoom in
				zoom = min(_graph_container.scale.x + _zoom_increment, _max_zoom_in)
			else:
				# zoom out
				zoom = max(_graph_container.scale.x - _zoom_increment, _max_zoom_out)
			
			if is_equal_approx(_graph_container.scale.x, zoom) == false:
				var prev_pos : Vector2 = _graph_container.global_position
				_graph_container.pivot_offset =\
					_graph_container.get_local_mouse_position() * _graph_container.scale
				# reset pos because changing pivot offsets position for some hecking reason
				_graph_container.global_position = prev_pos
				
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
	_center_view_around_graph()

func _request_blackboard_content():
	_debugger.send_debugger_ui_request(
		"requesting_blackboard_data", {"id":_active_tree_id, "global":_is_tracking_global_blackboard}
	)
	_blackboard_update_timer.start()

func _on_open_global_blackboard_pressed():
	_is_tracking_global_blackboard = true
	_request_blackboard_content()

func _on_blackboard_update_timer_timeout():
	_request_blackboard_content()
