extends Node2D

var current_time_speed: float = 1.0
var slowdown_duration: float = 0.0
@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.timeout.connect(func() -> void:
		current_time_speed = 1.0
		slowdown_duration = 0.0
		Engine.time_scale = current_time_speed
	)

func change_time_speed(new_speed: float, duration: float, force: bool = false) -> void:
	if abs(current_time_speed - Engine.time_scale) < 0.01:
		force = true

	if force:
		current_time_speed = new_speed
		slowdown_duration = duration
	else:
		current_time_speed = lerp(current_time_speed, new_speed, 0.5) 
		slowdown_duration = max(slowdown_duration, duration)  # Extend to keep longest duration
	
	Engine.time_scale = current_time_speed
	timer.start(slowdown_duration)
