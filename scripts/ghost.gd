extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Sprite

@export var float_speed: float = 50.0
@export var float_speed_variance: float = 10.0
@export var max_time_alive: float = 3.0
@export var spawn_time: float = 0

var time_alive: float = 0.0
var is_alive: bool = true

func _ready() -> void:
	sprite.play("Idle")
	velocity.y = -float_speed + randf() * float_speed_variance
	sprite.modulate = Color(1, 1, 1, 0)

	var tween := get_tree().create_tween()
	tween.tween_property(sprite, "modulate:a", 1, 0.5)

	if spawn_time > 0:
		set_collision_layer_value(3, false)
		get_tree().create_timer(spawn_time).timeout.connect(on_spawn_finished)

func on_spawn_finished() -> void:
	set_collision_layer_value(3, true)

func _process(delta: float) -> void:
	time_alive += delta

	if time_alive > max_time_alive and is_alive:
		is_alive = false
		var tween := get_tree().create_tween()
		tween.tween_property(sprite, "modulate:a", 0, 0.5)
		tween.tween_callback(queue_free)


func _physics_process(_delta: float) -> void:
	move_and_slide()
