@tool
extends MarginContainer

@onready var _graph_panel : Panel = $HSplitContainer/TreeGraph
@onready var _graph_container : Control = $HSplitContainer/TreeGraph/GraphContainer
@onready var _tree_menu_panel : PanelContainer = $HSplitContainer/TreesMenu
@onready var _tree_menu_container : VBoxContainer = $HSplitContainer/TreesMenu/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
@onready var _tree_sort_button : MenuButton = $HSplitContainer/TreesMenu/MarginContainer/VBoxContainer/HBoxContainer/Sort
@onready var _blackboard_data_panel : PanelContainer = $HSplitContainer/BlackboardData
@onready var _blackboard_data_container : VBoxContainer = $HSplitContainer/BlackboardData/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/VBoxContainer
@onready var _blackboard_data_name_label : Label = $HSplitContainer/BlackboardData/MarginContainer/VBoxContainer/HBoxContainer/Name
@onready var _blackboard_data_empty_label : Label = $HSplitContainer/BlackboardData/MarginContainer/Empty
@onready var _blackboard_update_timer : Timer = $BlackboardUpdateTimer
@onready var _no_selected_tree_label : Label = $HSplitContainer/TreeGraph/NoSelectedTree

const _graph_node_scene : PackedScene = preload("res://addons/DVs_behavior_tree/debug/components/graph_node.tscn")
const _blackboard_entry_scene : PackedScene = preload("res://addons/DVs_behavior_tree/debug/components/blackboard_entry.tscn")

var _debugger : EditorDebuggerPlugin
var _existing_tree_ids : PackedInt64Array
var _is_tracking_global_blackboard : bool

# active tree
var _active_tree_id : int = -1
var _active_tree_bounding_box : Rect2
var _id_to_graph_node_map : Dictionary # id:graph node
var _key_to_bb_entry_map : Dictionary # key(string):blackboard entry node
var _tree_menu_btn_to_id_map : Dictionary # btn:id

const _node_spacing : Vector2 = Vector2(30.0, 86.0)
const _group_x_spacing : float = _node_spacing.x * 1.8
const _center_view_graph_margin : float = 64.0

const _max_zoom_in : float = 1.4
const _max_zoom_out : float = 0.1
const _zoom_increment : float = 0.1
var _is_panning : bool
const _pan_sensitivity : float = 0.7

# TODO: button to sort blackboard entries by last modified and alphabetic

func setup(debugger : EditorDebuggerPlugin):
	_debugger = debugger

func _ready():
	_tree_sort_button.get_popup().id_pressed.connect(_on_tree_sort_id_pressed)

func start_monitoring():
	# nothing to do here, behavior tree nodes will not send any messages unless debugger is active
	pass

func stop_monitoring():
	# session ended, clear everything
	for i : int in range(_tree_menu_container.get_child_count()-1, -1, -1):
		_remove_tree_menu_entry(
			_tree_menu_btn_to_id_map[_tree_menu_container.get_child(i)]
		)
	_existing_tree_ids.clear()

func tree_added(id : int, name_ : String, scene : StringName):
	# NOTE: can't pass nodes between the editor and running game :(
	var btn : Button = Button.new()
	btn.text = name_ + " (" + scene + ")"
	btn.toggle_mode = true
	_tree_menu_btn_to_id_map[btn] = id
	btn.set_meta("scene", scene)
	btn.set_meta("instance_creation", Time.get_ticks_msec())
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
	#          witness what's bellow. that you were one of those who got to keep all their brain cells.
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
			# NOTE: a group is all nodes that share the same parent
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
				graph_node.call_deferred("set_graph_parent", parent_graph_node)
		
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
			if parent_graph_node != last_parent_graph_node && i > 0:
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
							
							if lm_grandparent == rm_grandparent:
								# common ancestor found. push all nodes below the ancestor to the left or right
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
	
	# bounding box cache
	_active_tree_bounding_box = Rect2()
	for graph_node : Control in _graph_container.get_children():
		_active_tree_bounding_box = _active_tree_bounding_box.merge(
			Rect2(graph_node.position, graph_node.size)
		)
	_active_tree_bounding_box = _active_tree_bounding_box.grow(_center_view_graph_margin)
	
	_center_view_around_graph()
	_debugger.send_debugger_ui_request("debugger_display_started", {"id":_active_tree_id})

func active_tree_node_entered(id : int):
	if _id_to_graph_node_map: # _id_to_graph_node_map could be empty due to graph construction lagging behind game frames
		_id_to_graph_node_map[id].enter()

func active_tree_node_exited(id : int):
	if _id_to_graph_node_map:
		_id_to_graph_node_map[id].exit()

func active_tree_node_status_set(id : int, status : BTNode.Status, main_path : bool):
	if _id_to_graph_node_map:
		_id_to_graph_node_map[id].set_status(status, main_path)

func active_tree_comp_attachment_ticked(attachment_name : String, composite_id : int):
	if _id_to_graph_node_map:
		_id_to_graph_node_map[composite_id].attachment_ticked(attachment_name)

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
	
	_debugger.send_debugger_ui_request("debugger_display_ended", {"id":_active_tree_id})
	_active_tree_id = -1
	_no_selected_tree_label.show()
	_id_to_graph_node_map.clear()
	
	for graph_node : Control in _graph_container.get_children():
		graph_node.queue_free()
	
	_blackboard_update_timer.stop()
	if _blackboard_data_panel.visible:
		_clear_blackboard()
		_blackboard_data_panel.hide()
		_tree_menu_panel.show()

func _remove_tree_menu_entry(tree_id : int):
	for btn : Button in _tree_menu_container.get_children():
		if _tree_menu_btn_to_id_map[btn] == tree_id:
			_tree_menu_btn_to_id_map.erase(btn)
			btn.queue_free()
			break
	
	if _active_tree_id == tree_id:
		_clear_graph()
	
	_existing_tree_ids.remove_at(_existing_tree_ids.find(tree_id)) # no .erase?!!

func _on_tree_list_btn_toggled(toggled_on : bool, button : Button):
	if toggled_on == false:
		# prevent toggling off so the list behaves like radio buttons
		button.set_pressed_no_signal(true)
	else:
		if _active_tree_id != -1:
			# toggle off previous button
			var prev_button : Button = _tree_menu_btn_to_id_map.find_key(_active_tree_id)
			prev_button.set_pressed_no_signal(false)
		
		_clear_graph()
		
		var id : int = _tree_menu_btn_to_id_map[button]
		_active_tree_id = id
		_no_selected_tree_label.hide()
		
		# request full tree structure and wait for response
		_debugger.send_debugger_ui_request("requesting_tree_structure", {"id":id})

func _clear_blackboard():
	for child : Node in _blackboard_data_container.get_children():
		child.queue_free()
	_key_to_bb_entry_map.clear()

func _center_view_around_graph():
	if _active_tree_id == -1: return
	
	# set zoom to encapsulate graph
	_graph_container.pivot_offset = Vector2.ZERO
	var size_ratio : Vector2 = _graph_panel.size / _active_tree_bounding_box.size
	_graph_container.scale = Vector2.ONE * clamp(
		size_ratio[size_ratio.min_axis_index()], _max_zoom_out, _max_zoom_in
	)
	
	# center position
	var panel_center : Vector2 = _graph_panel.size / 2.0
	_graph_container.position =\
		panel_center - (_active_tree_bounding_box.position + _active_tree_bounding_box.size/2.0) * _graph_container.scale

func _on_tree_sort_id_pressed(id : int):
	var menu_children : Array[Node] = _tree_menu_container.get_children()
	var sort_func : Callable
	
	# sort
	match id:
		0: # sort by scene
			sort_func = func(a : Button, b : Button) -> bool:
				if a.get_meta("scene") != b.get_meta("scene"):
					return true
				return false
		1: # sort by date
			sort_func = func(a : Button, b : Button) -> bool:
				if a.get_meta("instance_creation") < b.get_meta("instance_creation"):
					return true
				return false
	menu_children.sort_custom(sort_func)
	
	# reorder buttons based on sort result
	for i : int in menu_children.size():
		var menu_child : Button = menu_children[i]
		_tree_menu_container.move_child(menu_child, i)

func _on_graph_node_action_pressed(action_type : String, graph_node : Control):
	match action_type:
		"force_tick":
			var graph_id : int
			for id : int in _id_to_graph_node_map:
				if _id_to_graph_node_map[id] == graph_node:
					graph_id = id
					break
			
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
				# zoom
				# note to self: never touch pivots again
				var mouse_local : Vector2 = _graph_container.get_local_mouse_position()
				var mouse_global : Vector2 = _graph_container.global_position + (mouse_local * _graph_container.scale)
				_graph_container.scale = Vector2.ONE * zoom
				_graph_container.global_position = mouse_global - (mouse_local * _graph_container.scale)
		
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
	if _is_tracking_global_blackboard:
		_debugger.send_debugger_ui_request(
			"requesting_global_blackboard_data", {}
		)
	else:
		_debugger.send_debugger_ui_request(
			"requesting_blackboard_data", {"id":_active_tree_id}
		)
	_blackboard_update_timer.start()

func _on_open_global_blackboard_pressed():
	_is_tracking_global_blackboard = true
	_request_blackboard_content()

func _on_blackboard_update_timer_timeout():
	_request_blackboard_content()
