extends RigidBody2D

@onready var stats: Stats = $Stats

func _ready() -> void:
	stats.on_hit.connect(start_round)

func start_round() -> void:
	stats.hp = stats.hp_max
	Events.round_started.emit()
