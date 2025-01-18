extends BTCompositeAttachment

func tick(delta : float):
	super(delta)
	
	# NOTE: in an actual game there would be some centralized croud manager class
	#       responsible for calculations that control all NPCs in a croud.
	#       for this example, giving all agents the same rng seed ensures that
	#       even if they all roll to determine who should attack, they all get the same value
	if behavior_tree.global_blackboard.has("current_attack_dog") == false:
		var dogs : Array = behavior_tree.global_blackboard["dogs"]
		
		var rng := RandomNumberGenerator.new()
		rng.seed = Engine.get_frames_drawn()
		var rand_dog : Node2D = dogs[rng.randf_range(0, dogs.size())]
		behavior_tree.global_blackboard["current_attack_dog"] = rand_dog
