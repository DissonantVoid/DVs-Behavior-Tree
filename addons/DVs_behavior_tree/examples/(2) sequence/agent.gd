extends Node2D

const _move_speed : float = 120.0
var _move_target : Vector2
var _is_moving : bool = false

var _picked_obstacle : Node2D = null

func _physics_process(delta : float):
	if _is_moving:
		position += (_move_target - global_position).normalized() * _move_speed * delta

func move_to(target : Vector2):
	_is_moving = true
	_move_target = target

func stop_moving():
	_is_moving = false

func pickup_obstacle(obstacle : Node2D):
	obstacle.reparent(self)
	_picked_obstacle = obstacle

func drop_obstacle():
	_picked_obstacle.queue_free()
