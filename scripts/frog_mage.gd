extends CharacterBody2D

var max_speed: float = 180

@export var rotation_speed_to: float = 6.0  # Controls how fast the enemy rotates when colliding
var rotation_speed: float = 0

@export var acceleration: float = 10
@export var projectile: PackedScene
@export var projectile_speed: float = 100


@onready var raycast: RayCast2D = $Raycast
@onready var raycast2: RayCast2D = $Raycast2
@onready var raycast3: RayCast2D = $Raycast3
@onready var raycast4: RayCast2D = $Raycast4
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var stats: Stats = $Stats
@onready var light: Light2D = $StaffLight

var impulse: Vector2 = Vector2.ZERO

var movement_angle: float = 0
var last_rotation: float = 1  # Determines rotation direction
var speed: float = 0
var change_rotation_timer: float = 0
var change_rotation_time: float = 3.5
var target_velocity: Vector2 = Vector2.ZERO

var state: states = states.FLOATING

var changing_state: bool = false
var floating_length: float = 3
var attack_charge_length: float = 2
var attack_cooldown: float = 2
var sine_timer: float = 0


enum states {
	FLOATING,
	ATTACKING
}

func _ready() -> void:
	stats.on_hit.connect(on_hit)
	movement_angle = rotation
	raycast.rotation = rotation
	changing_state = true
	light.energy = 0
	sprite.play("Idle")

	get_tree().create_timer(floating_length).timeout.connect(func() -> void:
		changing_state = false
	)
		
	
func change_state() -> void:
	if changing_state:
		return

	changing_state = true
	var new_state := states.FLOATING if state == states.ATTACKING else states.ATTACKING

	if new_state == states.FLOATING:
		state = states.FLOATING
		get_tree().create_timer(floating_length).timeout.connect(func() -> void:
			state = states.ATTACKING
			light.energy = 0
		)
	elif new_state == states.ATTACKING:
		state = states.ATTACKING
		light.scale = Vector2(0, 0)
		sprite.play("PrepareAttack")
		Utils.fast_tween(light, "energy", 2, attack_charge_length - 0.1)
		Utils.fast_tween(light, "scale", Vector2(1, 1), attack_charge_length * 0.75)

		get_tree().create_timer(attack_charge_length).timeout.connect(func() -> void:
			spawn_projectile()
			light.energy = 0
			sprite.play("Cooldown")
			get_tree().create_timer(attack_cooldown).timeout.connect(func() -> void:
				state = states.FLOATING
				get_tree().create_timer(floating_length).timeout.connect(func() -> void:
					changing_state = false
					sprite.play("Idle")
				)
			)
		)

func on_hit() -> void:
	# var new_rotation_value := 1 if randf() > 0.5 else -1
	var new_rotation_value := last_rotation * -1
	Utils.fast_tween(self, "last_rotation", new_rotation_value, 0.5)
	var player_position := GameManager.get_player_position()
	var direction := (global_position - player_position).normalized()
	impulse = direction * (100 + 25 * randf()) 

func _process(delta: float) -> void:
	light.position.x = 12 * (1 if sprite.flip_h else -1)

	sine_timer += delta
	impulse.x = lerpf(impulse.x, 0, 0.1)
	impulse.y = lerpf(impulse.y, 0, 0.1)

	rotation_speed += (rotation_speed_to - rotation_speed) * 0.05

	if state == states.FLOATING:
		handle_floating(delta)
	elif state == states.ATTACKING:
		handle_attacking(delta)

	velocity.x = lerpf(velocity.x, target_velocity.x * 0.8, acceleration * delta)
	velocity.y = lerpf(velocity.y, target_velocity.y, acceleration * delta)
	velocity += impulse

	raycast.rotation = movement_angle
	raycast2.rotation = movement_angle
	raycast3.rotation = movement_angle
	raycast4.rotation = movement_angle

	position.y += sin(sine_timer * 8) * 0.2

	change_state()

func spawn_projectile() -> void:
	var projectile_instance: EnemyProjectile = projectile.instantiate()
	projectile_instance.global_position = light.global_position
	var player_pos := GameManager.get_player_position()
	projectile_instance.velocity = (player_pos - global_position).normalized() * projectile_speed
	projectile_instance.owner_stats = stats
	light.energy = 0
	impulse = -projectile_instance.velocity * 0.5

	get_parent().add_child(projectile_instance)

func handle_attacking(delta: float) -> void:
	# print("Attacking")
	# sprite.modulate = Color(1, 0, 0)
	# sprite.scale = Vector2(1.2, 1.2)
	target_velocity = Vector2.ZERO

	var player_pos: Vector2 = GameManager.get_player_position()
	if global_position.x < player_pos.x:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func handle_floating(delta: float) -> void:
	# print("Floating")
	sprite.modulate = Color(1, 1, 1)
	light.energy = 0

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

	target_velocity = Vector2.RIGHT.rotated(movement_angle) * speed 

	if velocity.length() > 0.1:
		sprite.flip_h = velocity.x > 0




func _physics_process(_delta: float) -> void:
	move_and_slide()
