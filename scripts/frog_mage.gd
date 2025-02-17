extends CharacterBody2D

var max_speed: float = 180

@export var rotation_speed_to: float = 6.0  # Controls how fast the enemy rotates when colliding
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

var state: states = states.FLOATING

enum states {
	FLOATING,
	ATTACKING
}

var is_attacking: int = 0

func _ready() -> void:
	stats.on_hit.connect(on_hit)
	movement_angle = rotation
	raycast.rotation = rotation

func on_hit() -> void:
	# var new_rotation_value := 1 if randf() > 0.5 else -1
	var new_rotation_value := last_rotation * -1
	Utils.fast_tween(self, "last_rotation", new_rotation_value, 0.5)
	var player_position := GameManager.get_player_position()
	var direction := (global_position - player_position).normalized()
	impulse = direction * (100 + 25 * randf()) 

func _process(delta: float) -> void:
	impulse.x = lerpf(impulse.x, 0, 0.1)
	impulse.y = lerpf(impulse.y, 0, 0.1)

	rotation_speed += (rotation_speed_to - rotation_speed) * 0.05

	if state == states.FLOATING:
		handle_floating(delta)
	elif state == states.ATTACKING:
		handle_attacking(delta)

	var target_velocity := Vector2.RIGHT.rotated(movement_angle) * speed 
	velocity.x = lerpf(velocity.x, target_velocity.x * 0.8, acceleration * delta)
	velocity.y = lerpf(velocity.y, target_velocity.y, acceleration * delta)
	velocity += impulse

	raycast.rotation = movement_angle
	raycast2.rotation = movement_angle
	raycast3.rotation = movement_angle
	raycast4.rotation = movement_angle

	if velocity.length() > 0.1:
		sprite.flip_h = velocity.x > 0

func handle_attacking(delta: float) -> void:
	pass
	# if is_attacking == 0:
	# 	is_attacking = 1
	# 	var new_rotation_value := last_rotation * -1
	# 	Utils.fast_tween(self, "last_rotation", new_rotation_value, 0.5)
	# 	impulse = Vector2.RIGHT.rotated(movement_angle) * 100

func handle_floating(delta: float) -> void:
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
		movement_angle += (rotation_speed_to * last_rotation * delta * (randf() * 0.5 + 0.5)) * 0.2
		change_rotation_timer += delta
		speed += acceleration * delta * 60
		if speed > max_speed:
			speed = max_speed


func _physics_process(_delta: float) -> void:
	move_and_slide()
