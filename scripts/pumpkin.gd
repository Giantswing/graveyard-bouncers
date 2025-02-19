extends CharacterBody2D

@export var speed: float = 50
@export var speed_variance: float = 10
@export var jump_speed: float = 100
@export var jump_speed_variance: float = 10
@export var jump_timer_max: float = 2
@export var jump_timer_variance: float = 1
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var body_forward_cast: RayCast2D = $BodyForwardCast
@onready var stats: Stats = $Stats
var jump_timer: float = 0
var raycast_distance: float = 15

var direction: int = 0
var charging: bool = false
var can_charge: bool = true

func _ready() -> void:
	speed += randf_range(-speed_variance, speed_variance)
	jump_speed += randf_range(-jump_speed_variance, jump_speed_variance)
	jump_timer_max += randf_range(-jump_timer_variance, jump_timer_variance)
	jump_timer = jump_timer_max * 0.5
	sprite.play("Idle")
	raycast_distance = body_forward_cast.target_position.x
	change_direction(1 if randi() % 2 == 0 else -1)
	can_charge = false
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		can_charge = true
	)
	
	stats.on_hit.connect(
		func() -> void:
			velocity.y = jump_speed
			jump_timer *= 0.6
	)

func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity.x = speed * direction
		velocity.y += get_gravity().y * delta
	else:
		velocity.x = 0

	if can_charge:
		jump_timer += delta

	if charging:
		translate(Vector2(randf_range(-0.4, 0.4), 0))
		sprite.rotation = randf_range(-0.1, 0.1)

	if jump_timer > (jump_timer_max * 0.5) and !charging:
		charging = true
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector2(1.3, 0.7), jump_timer_max - jump_timer)
		tween.parallel().tween_property(self, "modulate", Color(1, 0.2, 0.2), jump_timer_max - jump_timer)

	if is_on_floor() and jump_timer > jump_timer_max:
		charging = false

		sprite.rotation = 0
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector2(0.6, 1.6), 0.1)
		tween.parallel().tween_property(self, "modulate", Color(1, 1, 1), 0.1)
		tween.tween_property(self, "scale", Vector2(1, 1), 0.2)

		can_charge = false
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			can_charge = true
		)

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
