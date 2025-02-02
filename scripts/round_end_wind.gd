extends GPUParticles2D

func _ready() -> void:
	Events.round_ended.connect(on_round_ended)

func on_round_ended() -> void:
	emitting = true
