@tool
@icon("res://addons/DVs_behavior_tree/icons/control_particles.svg")
class_name BTControlParticles
extends "res://addons/DVs_behavior_tree/behavior_tree/leaves/action.gd"

## Sets particle node to emit/stop and optionally waits for it to finish.

enum ParticlesType {
	cpu_2d, ## CPUParticles2D.
	gpu_2d, ## GPUParticles2D.
	cpu_3d, ## CPUParticles3D.
	gpu_3d ## GPUParticles3D.
}
enum Action {
	emit, ## Emit particles.
	stop ## Stop emitting particles.
}

## Particles type.
@export var particles_type : ParticlesType :
	set(value):
		particles_type = value
		notify_property_list_changed()
## Particles node for type of cpu_2d.
@export var particles_2d_cpu : CPUParticles2D
## Particles node for type of gpu_2d.
@export var particles_2d_gpu : GPUParticles2D
## Particles node for type of cpu_3d.
@export var particles_3d_cpu : CPUParticles3D
## Particles node for type of gpu_3d.
@export var particles_3d_gpu : GPUParticles3D
## Action to perform on particles.
@export var action : Action :
	set(value):
		action = value
		notify_property_list_changed()
## If true, waits for particles to finish before setting status to success.
@export var wait_for_finish : bool

var _is_waiting_for_finish : bool
var _is_particles_finished : bool

func enter():
	super()
	
	_is_waiting_for_finish = false
	_is_particles_finished = false

func exit(is_interrupted : bool):
	super(is_interrupted)
	
	if is_interrupted:
		var particles =_get_target_particles()
		if particles.finished.is_connected(_on_particles_finished):
			particles.finished.disconnect(_on_particles_finished)

func tick(delta : float):
	super(delta)
	var particles =_get_target_particles()
	
	if particles == null:
		_set_status(Status.failure)
		return
	
	if _is_waiting_for_finish:
		if _is_particles_finished:
			_set_status(Status.success)
			return
		else:
			_set_status(Status.running)
			return
	
	match action:
		Action.emit:
			if particles.one_shot:
				particles.restart()
			else:
				particles.emitting = true
			
			if wait_for_finish == false:
				_set_status(Status.success)
			else:
				_is_waiting_for_finish = true
				particles.finished.connect(_on_particles_finished)
				_set_status(Status.running)
			
		Action.stop:
			particles.emitting = false
			_set_status(Status.success)

func _on_particles_finished():
	_is_particles_finished = true

func _get_target_particles() -> Variant:
	match particles_type:
		ParticlesType.cpu_2d:
			return particles_2d_cpu
		ParticlesType.gpu_2d:
			return particles_2d_gpu
		ParticlesType.cpu_3d:
			return particles_3d_cpu
		ParticlesType.gpu_3d:
			return particles_3d_gpu
	
	return null

func _validate_property(property : Dictionary):
	var prop_name : String = property["name"]
	
	if action != Action.emit:
		if prop_name == "wait_for_finish":
			property.usage = PROPERTY_USAGE_NO_EDITOR
	
	if prop_name == "particles_2d_cpu" && particles_type != ParticlesType.cpu_2d:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif prop_name == "particles_2d_gpu" && particles_type != ParticlesType.gpu_2d:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif prop_name == "particles_3d_cpu" && particles_type != ParticlesType.cpu_3d:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif prop_name == "particles_3d_gpu" && particles_type != ParticlesType.gpu_3d:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super()
	
	var particles = _get_target_particles()
	if particles == null:
		warnings.append("No particles node set")
	elif wait_for_finish && particles.one_shot == false:
		warnings.append("Particles node has one_shot set to false which means wait_for_finish will cause this node to wait forever")
	
	return warnings
