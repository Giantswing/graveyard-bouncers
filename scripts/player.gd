extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var body_down_cast1: RayCast2D = $Raycasts/BodyDownCast1
@onready var body_down_cast2: RayCast2D = $Raycasts/BodyDownCast2
@onready var body_forward_cast: RayCast2D = $Raycasts/BodyForwardCast
@onready var speed_particles: GPUParticles2D = $SpeedParticles

@export var acceleration: float = 0.1 
@export var base_strength: float = 300

@export var attack_recoil_str_mult: float = 1
@export var jump_str_mult: float = 1
@export var failed_attack_str_mult: float = 0.3
@export var normal_attack_bounce_str_mult: float = 1
@export var attack_gravity_mult: float = 2
@export var parry_bounce_str_mult: float = 2
@export var parry_downward_str_mult: float = 1
@export var getting_hit_bounce_str_mult: float = 1.5
@export var slide_down_max_speed: float = 30

@export var hit_invincibility_time: float = 0.5
@export var mov_speed: float = 100
@export var parry_raycast_distance: float = 30
@export var extra_hspeed_decay: float = 0.1
@export var extra_hspeed_strength: float = 1

var can_jump: bool = true
var hspeed: float = 0
var extra_hspeed: float = 0
var hspeed_to: float = 0
var is_attacking: int = 0 # 0 = not attacking, 1 = preparing attack, 2 = attacking
var is_parrying: bool = false
var jump_pressed: bool = false 
var movement_input: Vector2
var can_get_hit: bool = true
var previous_velocity: Vector2 = Vector2.ZERO
var grounded: bool = false
var on_wall: bool = false
var can_be_on_wall: bool = true 


func _ready() -> void:
	speed_particles.emitting = false
	base_strength *= GameManager.gravity_multiplier
	sprite.animation_finished.connect(on_animation_finished)
	body_down_cast1.target_position.y = parry_raycast_distance
	body_down_cast2.target_position.y = parry_raycast_distance

	Events.player_died.connect(on_player_died)

func on_player_died() -> void:
	Engine.time_scale = 0.5

	queue_free()

func on_animation_finished() -> void:
	if sprite.animation == "Parry":
		sprite.play("Idle")

func _process(delta: float) -> void:
	get_input()


	if velocity.y > 0 and is_attacking == 1:
		speed_particles.emitting = true
		is_attacking = 2

	if velocity.y > 0 and is_attacking != 2 and speed_particles.emitting == true:
		speed_particles.emitting = false

	extra_hspeed += (0 - extra_hspeed) * delta * extra_hspeed_decay * 60
	hspeed_to = movement_input.x * mov_speed
	hspeed += (hspeed_to - hspeed) * acceleration * delta * 60

	if on_wall and GameManager.has_powerup("sticky-boots"):
		GameManager.set_powerup_active("sticky-boots", true)

	velocity.x = hspeed + extra_hspeed
	if is_attacking == 0:
		if on_wall:
			hspeed = 0
			velocity.y += get_gravity().y * delta * GameManager.gravity_multiplier
			velocity.y = clamp(velocity.y, -4000, slide_down_max_speed)
		else:
			velocity.y += get_gravity().y * delta * GameManager.gravity_multiplier
			
	else:
		velocity.y += get_gravity().y * delta * attack_gravity_mult * GameManager.gravity_multiplier

	handle_jump()


	if velocity.x > 5 and !on_wall:
		sprite.flip_h = false
	elif velocity.x < -5 and !on_wall:
		sprite.flip_h = true


func _physics_process(_delta: float) -> void:
	previous_velocity = velocity

	move_and_slide()

	grounded = is_on_floor()
	on_wall = false

	body_forward_cast.target_position.x = 10 if movement_input.x > 0 else -10
	if movement_input.x == 0:
		body_forward_cast.target_position.x = 0

	# if is_attacking == 0 and velocity.y > 0 and movement_input.x != 0:
	if is_attacking == 0 and movement_input.x != 0 and can_be_on_wall:
		on_wall = body_forward_cast.is_colliding()

	if on_wall:
		sprite.play("WallSlide")
	elif sprite.animation == "WallSlide":
		sprite.play("Idle")

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		handle_collision(collision)
	

	if(grounded and is_attacking == 2): # Failed attack
		velocity.y = -failed_attack_str_mult * base_strength
		is_attacking = 0
		is_parrying = false
		sprite.play("Idle")
		FxSystem.play_fx("SmokeHitSmall", position)


func handle_collision(collision: KinematicCollision2D) -> void:
	var parent := collision.get_collider()
	var stats: Stats = parent.get_node_or_null("Stats")

	var am_i_above: bool = position.y < parent.get_position().y
	var am_i_moving_down: bool = previous_velocity.y > 0
	var will_atack: bool = is_attacking == 2 and am_i_above and am_i_moving_down

	if stats != null:
		if will_atack and stats.can_take_damage:
			stats.take_damage(1)

			can_get_hit = false
			get_tree().create_timer(0.1).timeout.connect(reset_can_get_hit)

			if is_parrying == false: # Normal attack
				GameManager.set_powerup_active("double-jump", true)
				speed_particles.emitting = false
				velocity.y = -normal_attack_bounce_str_mult * base_strength
				sprite.play("Idle")

				FxSystem.play_fx("SmokeHitSmall", position)
			else: # Parry atack
				GameManager.set_powerup_active("double-jump", true)
				velocity.y = -parry_bounce_str_mult * base_strength
				sprite.play("Parry")

				Engine.time_scale = 0.1
				get_tree().create_timer(0.02).timeout.connect(reset_time_scale)
				
				Events.player_parry.emit()
				speed_particles.emitting = true
				
				FxSystem.play_fx("SmokeHit", position)


			is_attacking = 0
			is_parrying = false

		else:
			if can_get_hit and stats.damage > 0: # Take damage get hit
				can_get_hit = false

				set_collision_mask_value(3, false)
				get_tree().create_timer(hit_invincibility_time).timeout.connect(reset_can_get_hit)

				velocity.y = -getting_hit_bounce_str_mult * base_strength
				is_attacking = 0
				sprite.play("Idle")
				can_jump = false

				Events.hp_changed.emit(GameManager.player_hp - stats.damage, -stats.damage)

				if(GameManager.player_hp > 0):
					Engine.time_scale = 0.1
					get_tree().create_timer(0.1).timeout.connect(reset_time_scale)
					get_tree().create_timer(0.1).timeout.connect(reset_jump)



func handle_jump() -> void:
	if jump_pressed and can_jump:
		can_jump = false
		get_tree().create_timer(0.1).timeout.connect(reset_jump)

		if grounded:
			GameManager.set_powerup_active("double-jump", true)
			velocity.y = -base_strength * jump_str_mult

		elif on_wall and GameManager.has_powerup("sticky-boots", true):
			deactivate_can_be_on_wall()
			GameManager.set_powerup_active("sticky-boots", false)
			extra_hspeed = -movement_input.x * 500 * extra_hspeed_strength
			velocity.y = -base_strength * jump_str_mult

		else:
			if is_attacking == 0:
				process_jump()
				return
			
			if is_attacking > 0 and GameManager.has_powerup("double-jump"):
				GameManager.set_powerup_active("double-jump", false)
				process_jump()
				return

func process_jump() -> void:
	var collision = get_raycasts_collision_node([body_down_cast1, body_down_cast2])

	if collision != null:
		var stats: Stats = collision.get_node_or_null("Stats")

		if stats != null and stats.can_be_parried:
			is_parrying = true
			velocity.y = parry_downward_str_mult * base_strength
			is_attacking = 2
			return


	is_attacking = 1
	velocity.y = -attack_recoil_str_mult * base_strength
	sprite.play("Attack")

func get_input() -> void:
	movement_input = Input.get_vector("Left", "Right", "Up", "Down")
	jump_pressed = Input.is_action_just_pressed("Jump")


func get_raycasts_collision_node(raycasts: Array) -> Node2D:
	for raycast in raycasts:
		if raycast.is_colliding():
			return raycast.get_collider()

	return null


func reset_jump() -> void:
	can_jump = true

func reset_time_scale() -> void:
	Engine.time_scale = 1.0

func reset_can_get_hit() -> void:
	set_collision_mask_value(3, true)
	can_get_hit = true

func deactivate_can_be_on_wall() -> void:
	can_be_on_wall = false
	get_tree().create_timer(0.1).timeout.connect(func(): can_be_on_wall = true)
