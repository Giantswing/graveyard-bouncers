extends CharacterBody2D

@export var speed: float = 50
@export var speed_variance: float = 10
@export var jump_speed: float = 100
@export var jump_speed_variance: float = 10
@export var jump_timer_max: float = 2
@export var jump_timer_variance: float = 1
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var body_forward_cast: RayCast2D = $BodyForwardCast
var jump_timer: float = 0
var raycast_distance: float = 15

var direction: int = 0

func _ready() -> void:
	speed += randf_range(-speed_variance, speed_variance)
	jump_speed += randf_range(-jump_speed_variance, jump_speed_variance)
	jump_timer_max += randf_range(-jump_timer_variance, jump_timer_variance)
	sprite.play("Idle")
	raycast_distance = body_forward_cast.target_position.x
	change_direction(1 if randi() % 2 == 0 else -1)

func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity.x = speed * direction
		velocity.y += get_gravity().y * delta
	else:
		velocity.x = 0

	jump_timer += delta

	if is_on_floor() and jump_timer > jump_timer_max:
		velocity.y = -jump_speed
		jump_timer = 0

	if body_forward_cast.is_colliding():
		change_direction(-direction)

	move_and_slide()

func change_direction(new_direction: int) -> void:
	if new_direction != direction:
		direction = new_direction
		sprite.flip_h = direction == -1
		body_forward_cast.target_position = Vector2(direction * raycast_distance, 0)
