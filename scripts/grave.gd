extends RigidBody2D

@onready var stats: Stats = $Stats

func _ready() -> void:
	stats.on_hit.connect(start_round)

func start_round() -> void:
	stats.hp = stats.hp_max
	Events.round_countdown_start.emit(GameManager.instance.countdown_timer)
	# get_tree().create_timer(3.0).timeout.connect(func() -> void:
	# 	Events.round_started.emit()
	# )
