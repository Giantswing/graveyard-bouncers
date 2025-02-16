extends CharacterBody2D

var max_speed: float = 180

@export var rotation_speed_to: float = 1.0  # Controls how fast the enemy rotates when colliding
var rotation_speed: float = 0

@export var acceleration: float = 10

@onready var raycast: RayCast2D = $Raycast
@onready var raycast2: RayCast2D = $Raycast2
@onready var raycast3: RayCast2D = $Raycast3
@onready var raycast4: RayCast2D = $Raycast4
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var stats: Stats = $Stats

var impulse: Vector2 = Vector2.ZERO

var movement_angle: float = 0
var last_rotation: float = 1  # Determines rotation direction
var speed: float = 0
var change_rotation_timer: float = 0
var change_rotation_time: float = 3.5

func _ready() -> void:
	stats.on_hit.connect(on_hit)
	movement_angle = rotation
	raycast.rotation = rotation

func on_hit() -> void:
	# var new_rotation_value := 1 if randf() > 0.5 else -1
	var new_rotation_value := last_rotation * -1
	Utils.fast_tween(self, "last_rotation", new_rotation_value, 3)
	var player_position := GameManager.get_player_position()
	var direction := (global_position - player_position).normalized()
	impulse = direction * (100 + 25 * randf()) 

func _process(delta: float) -> void:
	impulse.x = lerpf(impulse.x, 0, 0.1)
	impulse.y = lerpf(impulse.y, 0, 0.1)

	rotation_speed += (rotation_speed_to - rotation_speed) * 0.05

	if global_position.y < GameManager.get_player_position().y:
		# rotation_speed += rotation_speed * 2 * delta
		movement_angle += rotation_speed_to * 0.15 * last_rotation * delta * (randf() * 0.5 + 0.5)

	if change_rotation_timer > change_rotation_time:
		change_rotation_timer = 0
		var new_rotation_value := 1 if randf() > 0.5 else -1
		Utils.fast_tween(self, "last_rotation", new_rotation_value, 1)

	if raycast.is_colliding() or raycast2.is_colliding() or raycast3.is_colliding() or raycast4.is_colliding():
		movement_angle += rotation_speed_to * last_rotation * delta * (randf() * 0.5 + 0.5)
	else:
		change_rotation_timer += delta
		speed += acceleration * delta * 60
		if speed > max_speed:
			speed = max_speed

	var target_velocity := Vector2.RIGHT.rotated(movement_angle) * speed 
	velocity = velocity.lerp(target_velocity, acceleration * delta)
	velocity += impulse

	# Keep raycast aligned with movement direction
	raycast.rotation = movement_angle
	raycast2.rotation = movement_angle
	raycast3.rotation = movement_angle
	raycast4.rotation = movement_angle

	if velocity.length() > 0.1:
		sprite.flip_h = velocity.x > 0

	# sprite.rotation = movement_angle * 0.05 * (1 if sprite.flip_h else -1)

func _physics_process(_delta: float) -> void:
	move_and_slide()
