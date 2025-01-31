extends CharacterBody2D

class_name PlayerCharacter

@onready var sprite: AnimatedSprite2D = $Sprite

@onready var parry_cast1: RayCast2D = $Raycasts/ParryCast1
@onready var parry_cast2: RayCast2D = $Raycasts/ParryCast2
@onready var attack_cast1: RayCast2D = $Raycasts/AttackCast1
@onready var attack_cast2: RayCast2D = $Raycasts/AttackCast2

@onready var body_forward_cast: RayCast2D = $Raycasts/BodyForwardCast
@onready var dash_cast: RayCast2D = $Raycasts/DashCast
@onready var speed_particles: GPUParticles2D = $SpeedParticles
@onready var dash_particles: GPUParticles2D = $DashParticles
@onready var animation_controller: PlayerAnimationController = $AnimationController 

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

@export var extra_speed_decay: float = 0.1
@export var extra_speed_strength: float = 1
@export var dash_distance: float = 100

@export var dash_frames_left: Texture2D
@export var dash_frames_right: Texture2D

var extra_speed: Vector2 = Vector2.ZERO

var can_jump: bool = true
var hspeed: float = 0
var hspeed_to: float = 0

var is_attacking: int = 0 # 0 = not attacking, 1 = preparing attack, 2 = attacking
var is_parrying: bool = false
var jump_pressed: bool = false 
var ability_pressed: bool = false
var movement_input: Vector2
var can_get_hit: bool = true
var received_damage: bool = false
var previous_velocity: Vector2 = Vector2.ZERO
var grounded: bool = false
var on_wall: bool = false
var can_be_on_wall: bool = true 


func _ready() -> void:
	speed_particles.emitting = false
	dash_particles.emitting = false
	base_strength *= GameManager.get_instance().round_data.gravity_multiplier
	parry_cast1.target_position.y = parry_raycast_distance
	parry_cast2.target_position.y = parry_raycast_distance

	Events.player_died.connect(on_player_died)
	Events.ability_gained.connect(on_ability_gained)
	Events.picked_up_powerup.connect(on_picked_up_powerup)
	Events.round_ended.connect(on_round_ended)

func on_round_ended() -> void:
	velocity.y = -base_strength * 2.3
	is_attacking = 0

func on_picked_up_powerup(powerup: PowerUp) -> void:
	if powerup.power_up_name == "sticky-boots":
		slide_down_max_speed *= 0.3

func on_ability_gained(new_ability: Ability) -> void:
	if new_ability == null:
		sprite.material.set_shader_parameter("width", 0)

		return

	var ability_name: String = new_ability.name
	var ability_uses: int = new_ability.uses

	if ability_name == "dash":
		if ability_uses == 1: # Blue
			sprite.material.set_shader_parameter("color", Color(0, 1, 1, 0.8))
		elif ability_uses == 2: # Orange
			sprite.material.set_shader_parameter("color", Color(1, 0.5, 0, 0.8))
		elif ability_uses == 3: # White
			sprite.material.set_shader_parameter("color", Color(1, 1, 1, 1))

		sprite.material.set_shader_parameter("width", 1.0)

func on_player_died() -> void:
	Engine.time_scale = 0.5

	queue_free()

func _process(delta: float) -> void:
	get_input()

	animation_controller.handle_animation(movement_input, velocity, grounded, on_wall, is_attacking, received_damage)

	if velocity.y > 0 and is_attacking == 1:
		speed_particles.emitting = true
		is_attacking = 2

	if velocity.y > 0 and is_attacking != 2 and speed_particles.emitting == true:
		speed_particles.emitting = false

	extra_speed.x += (0 - extra_speed.x) * delta * extra_speed_decay * 60
	extra_speed.y += (0 - extra_speed.y) * delta * extra_speed_decay * 60

	hspeed_to = movement_input.x * mov_speed
	hspeed += (hspeed_to - hspeed) * acceleration * delta * 60

	velocity.x = hspeed + extra_speed.x
	velocity.y = velocity.y + extra_speed.y

	if is_attacking == 0:
		if on_wall:
			velocity.y += get_gravity().y * delta * GameManager.get_instance().round_data.gravity_multiplier
			velocity.y = clamp(velocity.y, -4000, slide_down_max_speed)


		else:
			velocity.y += get_gravity().y * delta * GameManager.get_instance().round_data.gravity_multiplier
			
	else:
		velocity.y += get_gravity().y * delta * attack_gravity_mult * GameManager.get_instance().round_data.gravity_multiplier


	handle_jump()
	handle_ability()


func _physics_process(_delta: float) -> void:
	previous_velocity = velocity

	move_and_slide()

	grounded = is_on_floor()
	on_wall = false

	body_forward_cast.target_position.x = 20 if movement_input.x > 0 else -20
	if movement_input.x == 0:
		body_forward_cast.target_position.x = 0

	# if is_attacking == 0 and velocity.y > 0 and movement_input.x != 0:
	if is_attacking == 0 and movement_input.x != 0 and can_be_on_wall:
		on_wall = body_forward_cast.is_colliding()


	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		handle_collision(collision)
	

	if(grounded and is_attacking == 2): # Failed attack
		velocity.y = -failed_attack_str_mult * base_strength
		is_attacking = 0
		is_parrying = false
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
				GameManager.get_instance().set_powerup_active("double-jump", true)
				speed_particles.emitting = false
				velocity.y = -normal_attack_bounce_str_mult * base_strength

				FxSystem.play_fx("SmokeHitSmall", position)

				can_jump = false
				get_tree().create_timer(0.1).timeout.connect(reset_jump)

				velocity.y = clamp(velocity.y, -2000, 2000)
			else: # Parry attack
				GameManager.get_instance().set_powerup_active("double-jump", true)
				velocity.y = -parry_bounce_str_mult * base_strength
				grounded = false

				animation_controller.play_animation("parry")

				GameManager.instance.gain_ability(GameManager.instance.find_ability("dash"))

				Engine.time_scale = 0.1
				get_tree().create_timer(0.05).timeout.connect(reset_time_scale)
				
				Events.player_parry.emit()
				speed_particles.emitting = true
				
				FxSystem.play_fx("SmokeHit", position)

				can_jump = false
				get_tree().create_timer(0.1).timeout.connect(reset_jump)


			is_attacking = 0
			is_parrying = false

		else:
			if can_get_hit and stats.damage > 0: # Take damage get hit
				can_get_hit = false
				received_damage = true

				set_collision_mask_value(3, false)
				get_tree().create_timer(hit_invincibility_time).timeout.connect(reset_can_get_hit)

				velocity.y = -getting_hit_bounce_str_mult * base_strength
				is_attacking = 0
				can_jump = false

				Events.hp_changed.emit(GameManager.get_instance().player_hp - stats.damage, -stats.damage)

				if(GameManager.get_instance().player_hp > 0):
					Engine.time_scale = 0.1
					get_tree().create_timer(0.1).timeout.connect(reset_time_scale)
					get_tree().create_timer(0.1).timeout.connect(reset_jump)



func handle_ability() -> void:
	var current_ability := GameManager.instance.player_ability

	if !current_ability or !ability_pressed:
		return

	if current_ability.name == "dash":
		process_dash()

	GameManager.instance.use_current_ability()

func process_dash() -> void:
	is_attacking = 0

	var direction := movement_input.normalized()
	# velocity.x = 0
	velocity.y = 0
	# velocity.y = (direction * 500 * extra_speed_strength).y * 0.01

	extra_speed.x = direction.x * 50 * extra_speed_strength
	extra_speed.y = direction.y * 10 * extra_speed_strength

	var target_position: Vector2 = direction * dash_distance
	var new_position: Vector2 = Vector2.ZERO

	dash_cast.target_position = target_position
	dash_cast.force_raycast_update()

	if dash_cast.is_colliding():
		new_position = dash_cast.get_collision_point()
	else:
		new_position = position + target_position

	animation_controller.play_animation("dash")

	Engine.time_scale = 0.3

	if movement_input.x < 0:
		dash_particles.texture = dash_frames_left
	else:
		dash_particles.texture = dash_frames_right

	dash_particles.emitting = true

	get_tree().create_timer(0.15).timeout.connect(reset_time_scale)
	get_tree().create_timer(0.06).timeout.connect(func() -> void: dash_particles.emitting = false)

	Utils.fast_tween(self, "position", new_position, 0.05)


func handle_jump() -> void:
	if jump_pressed and can_jump:
		can_jump = false
		get_tree().create_timer(0.1).timeout.connect(reset_jump)

		if grounded:
			GameManager.get_instance().set_powerup_active("double-jump", true)
			velocity.y = -base_strength * jump_str_mult
			grounded = false
			animation_controller.play_animation("jump")

		elif on_wall:
			deactivate_can_be_on_wall()
			extra_speed = Vector2.ZERO
			extra_speed.x = -movement_input.x * 1500 * extra_speed_strength
			velocity.y = -base_strength * jump_str_mult

		else: # If we are in the air and jump again, we attack
			if is_attacking == 0:
				animation_controller.play_animation("attack")
				process_jump()
				return
			
			if is_attacking > 0 and GameManager.get_instance().has_powerup("double-jump"):
				animation_controller.play_animation("attack")
				GameManager.get_instance().set_powerup_active("double-jump", false)
				process_jump()
				return

func process_jump() -> void:
	var collision := get_raycasts_collision_node([parry_cast1, parry_cast2])

	if collision != null and is_attacking == 0:
		var stats: Stats = collision.get_node_or_null("Stats")

		if stats != null and stats.can_be_parried: # Start parry
			is_parrying = true
			if velocity.y < parry_downward_str_mult * base_strength:
				velocity.y = parry_downward_str_mult * base_strength
			else:
				velocity.y *= parry_downward_str_mult * 2

			is_attacking = 2
			return


	is_attacking = 1
	velocity.y = -attack_recoil_str_mult * base_strength

func get_input() -> void:
	movement_input = Input.get_vector("Left", "Right", "Up", "Down")
	jump_pressed = Input.is_action_just_pressed("Jump")
	ability_pressed = Input.is_action_just_pressed("Ability")


func get_raycasts_collision_node(raycasts: Array) -> Node2D:
	for raycast: RayCast2D in raycasts:
		if raycast.is_colliding():
			return raycast.get_collider()

	return null


func reset_jump() -> void:
	can_jump = true

func reset_time_scale() -> void:
	Engine.time_scale = 1.0

func reset_can_get_hit() -> void:
	set_collision_mask_value(3, true)
	received_damage = false
	can_get_hit = true

func deactivate_can_be_on_wall() -> void:
	can_be_on_wall = false
	get_tree().create_timer(0.1).timeout.connect(func() -> void: can_be_on_wall = true)
