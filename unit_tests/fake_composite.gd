extends BTComposite

@export var pick_child : int = -1

var _ticks_counter : int = 0

func enter():
	super()
	
	if pick_child < 0 || pick_child >= get_child_count():
		return
	
	_active_child = get_child(pick_child)
	_active_child.enter()

func tick(delta : float):
	super(delta)
	if _active_child == null:
		_set_status(Status.failure)
		_ticks_counter += 1
		return
	
	if pick_child != _active_child.get_index():
		# pick_child was changed
		_active_child.exit(true)
		_active_child = get_child(pick_child)
		_active_child.enter()
		
		_set_status(Status.running)
		_ticks_counter += 1
		return
	
	_active_child.tick(delta)
	var status : Status = _active_child.get_status()
	if status == Status.success || status == Status.failure:
		_active_child.exit(false)
		_active_child.enter()
	_ticks_counter += 1
	_set_status(Status.running)

func get_ticks() -> int:
	return _ticks_counter

func reset_ticks():
	_ticks_counter = 0
