extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision: CollisionShape2D = $Collision
@onready var light: PointLight2D = $Light
@export var speed: float = 100
@export var jump_time: float = 1.5

var current_jump_time: float = 0
var state: String = "Spawn"

func _ready() -> void:
	state = "Spawn"
	sprite.play("Spawn")
	set_collision_layer_value(4, false)
	light.energy = 0
	Utils.fast_tween(light, "energy", 10, 1.5)

func _process(delta: float) -> void:
	current_jump_time += delta

	if current_jump_time > jump_time and sprite.animation == "Spawn":
		state = "Idle"
		sprite.play("Idle")
		velocity.y = -speed * randf_range(0.8, 1.2)
		set_collision_layer_value(4, true)

	if state == "Idle":
		velocity.y += get_gravity().y * delta * 0.2
		if velocity.y > 0:
			sprite.flip_v = true

	if global_position.y > 300:
		queue_free()
	

func _physics_process(_delta: float) -> void:
	move_and_slide()
