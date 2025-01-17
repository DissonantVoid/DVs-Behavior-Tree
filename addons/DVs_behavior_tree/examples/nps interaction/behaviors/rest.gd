extends BTAction

func enter():
	super()
	
	var agent := behavior_tree.agent
	agent.rotation = -PI/2.0
	agent.modulate.a = 0.5

func exit(is_interrupted : bool):
	super(is_interrupted)
	
	var agent := behavior_tree.agent
	agent.rotation = 0.0
	agent.modulate.a = 1.0

func tick(delta : float):
	super(delta)
	
	# running until interrupted by another branch
	_set_status(Status.running)
