extends BTAction

func tick(delta : float):
	super(delta)
	
	behavior_tree.blackboard.erase("closest_obstacle")
	behavior_tree.agent.drop_obstacle()
	_set_status(Status.success)
