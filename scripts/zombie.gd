extends CharacterBody2D

@export var speed: float = 50
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var body_forward_cast: RayCast2D = $BodyForwardCast

var state: String = "Spawn"
var direction: int = 0

func _ready() -> void:
	sprite.play("Spawn")
	sprite.animation_finished.connect(on_animation_finished)

func on_animation_finished() -> void:
	if sprite.animation == "Spawn":
		sprite.play("Walk")
		state = "Walk"
		change_direction(1 if randi() % 2 == 0 else -1)

func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity.y += get_gravity().y * delta

	if state == "Walk":
		velocity.x = speed * direction

	if body_forward_cast.is_colliding():
		change_direction(-direction)

	move_and_slide()

func change_direction(new_direction: int) -> void:
	if new_direction != direction:
		direction = new_direction
		sprite.flip_h = direction == -1
		body_forward_cast.target_position = Vector2(direction * 15, 0)
