extends Node2D

@onready var _behavior_tree : BTBehaviorTree = $BTBehaviorTree
@onready var _talk_label : Label = $TalkLabel

var _talk_tween : Tween
const _talk_tween_time : float = 2.2
const circulate_speed : float = 60.0

func _ready():
	if _behavior_tree.global_blackboard.has("dogs") == false:
		_behavior_tree.global_blackboard["dogs"] = []
	_behavior_tree.global_blackboard["dogs"].append(self)

func say(message : String):
	_talk_label.text = message
	if _talk_tween && _talk_tween.is_valid():
		_talk_tween.kill()
	
	_talk_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	_talk_tween.tween_property(_talk_label, "modulate:a", 0.0, _talk_tween_time).from(1.0)
