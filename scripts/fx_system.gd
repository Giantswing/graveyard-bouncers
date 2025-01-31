extends Node2D

@onready var particles: Dictionary[String, GPUParticles2D] = {}

func _ready() -> void:
	for child in get_children():
		particles[child.name] = child
		particles[child.name].emitting = false
		particles[child.name].one_shot = true

func play_fx(fx_name: String, spawn_position: Vector2, _flip: bool = false) -> void:
	if particles.has(fx_name):
		particles[fx_name].emitting = true
		particles[fx_name].global_position = spawn_position
		particles[fx_name].restart()
