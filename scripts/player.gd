extends CharacterBody2D

class_name PlayerCharacter

@onready var sprite: AnimatedSprite2D = $Sprite

@onready var body_forward_cast: RayCast2D = $Raycasts/BodyForwardCast
@onready var dash_cast: RayCast2D = $Raycasts/DashCast
@onready var speed_particles: GPUParticles2D = $SpeedParticles
@onready var dash_particles: GPUParticles2D = $DashParticles
@onready var animation_controller: PlayerAnimationController = $AnimationController 
@onready var parry_collision: CollisionShape2D = $ParryArea/CollisionShape2D

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

@export var hit_invincibility_time: float = 1.5
@export var mov_speed: float = 100

@export var extra_speed_decay: float = 0.1
@export var extra_speed_strength: float = 1
@export var dash_distance: float = 100

@export var dash_frames_left: Texture2D
@export var dash_frames_right: Texture2D

var extra_speed: Vector2 = Vector2.ZERO

var hspeed: float = 0
var hspeed_to: float = 0

var jump_pressed: bool = false 
var ability_pressed: bool = false
var movement_input: Vector2
var received_damage: bool = false
var previous_velocity: Vector2 = Vector2.ZERO
var grounded: bool = false
var on_wall: bool = false

var can_move: bool = true
var can_be_on_wall: bool = true 
var can_jump: bool = true
var can_get_hit: bool = true
var can_attack: bool = true

var is_attacking: int = 0 # 0 = not attacking, 1 = preparing attack, 2 = attacking
var is_parrying: bool = false
var is_dashing: bool = false

var slide_fx_timer: float = 0

var parry_targets: Array[Stats]
var attack_targets: Array[Stats]
var walk_counter: float = 0

var coyote_time: float = 0.0

@export var coyote_time_max: float = 0.5

@onready var parry_area: Area2D = %ParryArea
@onready var attack_area: Area2D = %AttackArea
@onready var dash_attack_area: Area2D = %DashAttackArea

@onready var ctarget: CameraTarget = $CameraTarget


func _ready() -> void:
	speed_particles.emitting = false
	dash_particles.emitting = false

	Events.player_died.connect(on_player_died)
	Events.ability_gained.connect(on_ability_gained)
	Events.picked_up_powerup.connect(on_picked_up_powerup)
	Events.round_ended.connect(on_round_ended)
	Events.round_started.connect(func() -> void:
		velocity.y = -base_strength * 1.5
		is_attacking = 0
	)


	Events.enter_challenge_mode.connect(func(_player: PlayerCharacter) -> void: disable_movement())
	Events.exit_challenge_mode.connect(func(_player: PlayerCharacter) -> void:	disable_movement())

	parry_targets = []
	parry_area.body_entered.connect(on_parry_area_body_entered)
	parry_area.body_exited.connect(on_parry_area_body_exited)

	attack_targets = []
	attack_area.body_entered.connect(on_attack_area_body_entered)
	attack_area.body_exited.connect(on_attack_area_body_exited)

	dash_attack_area.body_entered.connect(handle_dash_attack)


func get_input() -> void:
	if !can_move:
		movement_input = Vector2.ZERO
		velocity.x = 0
		extra_speed = Vector2.ZERO
		return

	movement_input = Input.get_vector("Left", "Right", "Up", "Down")
	jump_pressed = Input.is_action_just_pressed("Jump")
	ability_pressed = Input.is_action_just_pressed("Ability")


func handle_dash_attack(body: Node2D) -> void:
	if !is_dashing or !GameManager.instance.has_powerup("dash-attack"):
		return

	var stats: Stats = body.get_node_or_null("Stats")

	if stats != null and stats.can_take_damage:
		stats.take_damage(2)
		velocity.x = 0
		velocity.y = 0
		velocity.y = -parry_bounce_str_mult * base_strength * 0.7
		is_attacking = 0
		animation_controller.play_animation("parry")
		GameManager.get_instance().set_powerup_active("double-jump", true)
		Engine.time_scale = 0.1
		get_tree().create_timer(0.05).timeout.connect(reset_time_scale)
		FxSystem.play_fx("smoke-hit", position)

func _process(delta: float) -> void:
	get_input()

	if grounded:
		coyote_time = 0
	else:
		coyote_time += delta

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

	handle_jump()
	handle_ability()

	if GameManager.instance.game_mode == GameManager.MODES.CHALLENGE_MODE:
		ctarget.importance.x = 1
		var look: float = -1 if sprite.flip_h else 1
		ctarget.offset.y = 0.0
		ctarget.offset.x = lerpf(ctarget.offset.x, 45.0 * look, 0.01)
	elif GameManager.instance.game_mode == GameManager.MODES.BEFORE_ROUND:
		ctarget.importance.x = 0
		ctarget.offset.x = 0
		ctarget.offset.y = -130.0
	elif GameManager.instance.game_mode == GameManager.MODES.IN_ROUND:
		ctarget.importance.x = 0
		ctarget.offset.x = 0
		ctarget.offset.y = 0.0
	elif GameManager.instance.game_mode == GameManager.MODES.COUNTDOWN:
		ctarget.importance.x = 0
		ctarget.offset.x = 0
		ctarget.offset.y = 100.0


func _physics_process(delta: float) -> void:
	previous_velocity = velocity

	if is_attacking == 0:
		if on_wall:
			set_collision_mask_value(8, false)
			velocity.y += get_gravity().y * delta * GameManager.get_instance().round_data.gravity_multiplier
			velocity.y = clamp(velocity.y, -4000, slide_down_max_speed)
			slide_fx_timer += delta
			if slide_fx_timer > 0.2 and velocity.y > 10:
				var direction: int = 0

				if movement_input.x > 0 or movement_input.x < 0:
					SoundSystem.play_audio("scratch")

				if movement_input.x > 0:
					direction = 1
					FxSystem.play_fx("smoke-puff", position + Vector2(direction * 7, -15)) 
				elif movement_input.x < 0:
					direction = -1
					FxSystem.play_fx("smoke-puff-flip", position + Vector2(direction * 7, -15)) 


				slide_fx_timer = 0

		else:
			set_collision_mask_value(8, true)
			velocity.y += get_gravity().y * delta * GameManager.get_instance().round_data.gravity_multiplier
			
	else:
		velocity.y += get_gravity().y * delta * attack_gravity_mult * GameManager.get_instance().round_data.gravity_multiplier

	move_and_slide()

	if is_dashing == false:
		if is_on_floor() and grounded == false:
			SoundSystem.play_audio("fall")

		grounded = is_on_floor()
	else:
		grounded = false


	if grounded and movement_input.x != 0:
		walk_counter += delta
		if walk_counter > 0.3:
			SoundSystem.play_audio("fall")
			walk_counter = 0

	on_wall = false

	body_forward_cast.target_position.x = 20 if movement_input.x > 0 else -20
	if movement_input.x == 0:
		body_forward_cast.target_position.x = 0

	if is_attacking == 0 and movement_input.x != 0 and can_be_on_wall:
		on_wall = body_forward_cast.is_colliding()


	if (attack_targets.size() > 0 and is_attacking == 2 and can_attack and velocity.y > 0):
		process_attack()

	elif (grounded and is_attacking == 2 and !is_parrying): # Failed attack
		velocity.y = -failed_attack_str_mult * base_strength
		is_attacking = 0
		is_parrying = false
		FxSystem.play_fx("smoke-hit-small", position)
		SoundSystem.play_audio("shovel-hit")



func handle_ability() -> void:
	var current_ability := GameManager.instance.player_ability

	if !current_ability or !ability_pressed:
		return

	if current_ability.name == "dash":
		process_dash()

	GameManager.instance.use_current_ability()



func handle_jump() -> void:
	if jump_pressed and can_jump:
		can_jump = false
		get_tree().create_timer(0.1).timeout.connect(reset_jump)

		if grounded or coyote_time < coyote_time_max:
			GameManager.get_instance().set_powerup_active("double-jump", true)
			velocity.y = -base_strength * jump_str_mult
			grounded = false
			animation_controller.play_animation("jump")
			SoundSystem.play_audio("jump")

		elif on_wall:
			deactivate_can_be_on_wall()

			extra_speed = Vector2.ZERO
			extra_speed.x = -movement_input.x * 1500 * extra_speed_strength
			velocity.y = -base_strength * jump_str_mult
			coyote_time = 100
			SoundSystem.play_audio("jump")

			

		else: # If we are in the air and jump again, we attack
			if is_attacking == 0:
				SoundSystem.play_audio("charge-hit")
				animation_controller.play_animation("attack")
				process_jump()
				return
			
			if is_attacking > 0 and GameManager.get_instance().has_powerup("double-jump"):
				SoundSystem.play_audio("charge-hit")
				animation_controller.play_animation("attack")
				GameManager.get_instance().set_powerup_active("double-jump", false)
				process_jump()
				return




func process_jump() -> void:
	var parry_target: Node2D = null
	var max_distance: float = 10000
	coyote_time = 100

	for target: Stats in parry_targets:
		var distance: float = target.global_position.distance_to(global_position)
		if distance < max_distance:
			max_distance = distance
			parry_target = target


	if parry_target != null and is_attacking == 0 and can_attack:
		received_damage = false
		process_parry(parry_target)
	else:
		# is_attacking = 1
		is_attacking = 2
		received_damage = false
		velocity.y = -attack_recoil_str_mult * base_strength


func process_attack() -> void:
	var target: Stats = null
	var max_distance: float = 10000

	for attack_target: Stats in attack_targets:
		var distance: float = attack_target.global_position.distance_to(global_position)
		if distance < max_distance:
			max_distance = distance
			target = attack_target

	velocity.y = 0
	can_attack = false
	can_get_hit = false

	Utils.fast_tween(self, "position:y", target.global_position.y - target.height, 0.05).tween_callback(
		func() -> void:
			if target:
				velocity.y = -normal_attack_bounce_str_mult * base_strength * target.bounciness 
				target.take_damage(1)
				SoundSystem.play_audio("shovel-hit")
			else:
				velocity.y = -normal_attack_bounce_str_mult * base_strength

			can_get_hit = false
			is_attacking = 0
			get_tree().create_timer(0.1).timeout.connect(reset_can_get_hit)

			GameManager.get_instance().set_powerup_active("double-jump", true)
			speed_particles.emitting = false

			Engine.time_scale = 0.4
			get_tree().create_timer(0.05).timeout.connect(reset_time_scale)

			FxSystem.play_fx("smoke-hit-small", position)

			can_jump = false
			get_tree().create_timer(0.2).timeout.connect(
				func() -> void:
					can_get_hit = true
					can_attack = true
					can_jump = true
			)
	)
	


func process_parry(target: Stats) -> void:
	velocity.y = 0
	is_parrying = true

	Utils.fast_tween(self, "position:y", target.global_position.y - target.height, 0.05).tween_callback(
		func() -> void:
			if !can_attack:
				return
			
			if target:
				var from_parry: bool = true
				target.take_damage(1, from_parry)
				velocity.y = -parry_bounce_str_mult * base_strength * target.bounciness

			SoundSystem.play_audio("parry-hit")
			can_get_hit = false
			get_tree().create_timer(0.2).timeout.connect(reset_can_get_hit)

			GameManager.get_instance().set_powerup_active("double-jump", true)
			grounded = false

			animation_controller.play_animation("parry")

			GameManager.instance.gain_ability(GameManager.instance.find_ability("dash"))

			Engine.time_scale = 0.1
			get_tree().create_timer(0.05).timeout.connect(reset_time_scale)

			Events.player_parry.emit()
			speed_particles.emitting = true

			FxSystem.play_fx("smoke-hit", position)

			can_jump = false
			is_parrying = false
			get_tree().create_timer(0.1).timeout.connect(reset_jump)
	)




func process_dash() -> void:
	is_attacking = 0

	var direction := movement_input.normalized()
	# velocity.x = 0
	velocity.y = 0
	# velocity.y = (direction * 500 * extra_speed_strength).y * 0.01

	extra_speed.x = direction.x * 50 * extra_speed_strength
	extra_speed.y = direction.y * 10 * extra_speed_strength
	is_dashing = true

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

	Events.player_dash.emit()
	get_tree().create_timer(0.15).timeout.connect(reset_time_scale)
	get_tree().create_timer(0.15).timeout.connect(func() -> void: is_dashing = false)
	get_tree().create_timer(0.06).timeout.connect(func() -> void: dash_particles.emitting = false)

	SoundSystem.play_audio("dash")
	Utils.fast_tween(self, "position", new_position, 0.05)



func reset_jump() -> void:
	can_jump = true


func reset_time_scale() -> void:
	Engine.time_scale = 1.0


func deactivate_can_be_on_wall() -> void:
	can_be_on_wall = false
	get_tree().create_timer(0.1).timeout.connect(func() -> void: can_be_on_wall = true)


func on_parry_area_body_entered(body: Node2D) -> void:
	var stats: Stats = body.get_node_or_null("Stats")

	if stats != null && stats.can_be_parried && parry_targets.find(stats) == -1:
		parry_targets.append(stats)

func on_parry_area_body_exited(body: Node2D) -> void:
	var stats: Stats = body.get_node_or_null("Stats")
	if stats != null:
		parry_targets.erase(stats)

func on_attack_area_body_entered(body: Node2D) -> void:
	var stats: Stats = body.get_node_or_null("Stats")

	if stats != null && stats.can_take_damage && attack_targets.find(stats) == -1:
		attack_targets.append(stats)

func on_attack_area_body_exited(body: Node2D) -> void:
	var stats: Stats = body.get_node_or_null("Stats")
	if stats != null:
		attack_targets.erase(stats)


func on_round_ended() -> void:
	velocity.y = -base_strength * 2.3
	is_attacking = 0


func on_picked_up_powerup(powerup: PowerUp) -> void:
	if powerup.power_up_name == "sticky-boots":
		slide_down_max_speed *= 0.3
	if powerup.power_up_name == "easy-parry":
		parry_collision.position.y += 10
		parry_collision.scale = Vector2(1, 1.7)


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
			sprite.material.set_shader_parameter("color", Color(1, 0.5, 0, 1))
		elif ability_uses == 3: # White
			sprite.material.set_shader_parameter("color", Color(1, 1, 1, 1))

		sprite.material.set_shader_parameter("width", 1.0)


func on_player_died() -> void:
	Engine.time_scale = 0.5
	queue_free()


func get_hit(from: Stats) -> void:
	if !can_get_hit:
		return

	if is_attacking == 2 and from.global_position.y > global_position.y and from.can_take_damage:
		return

	if is_dashing and GameManager.instance.has_powerup("dash-attack"):
		return

	if (grounded or velocity.y < 0) and from.only_damage_when_moving_down:
		return

	# if from.only_damage_when_moving_down:
	# 	if velocity.y < 0 or grounded:
	# 		return

	can_get_hit = false
	received_damage = true

	sprite.material.set_shader_parameter("tint", Color(1, 1, 1, 0.5))

	can_attack = false
	get_tree().create_timer(0.5).timeout.connect(func() -> void: can_attack = true)

	get_tree().create_timer(hit_invincibility_time).timeout.connect(reset_can_get_hit)
	get_tree().create_timer(1.0).timeout.connect(func() -> void: received_damage = false)

	velocity.y = -getting_hit_bounce_str_mult * base_strength
	is_attacking = 0
	can_jump = false

	Events.hp_changed.emit(GameManager.get_instance().player_hp - from.damage, -from.damage)
	SoundSystem.play_audio("get-hit")
	
	if(GameManager.get_instance().player_hp > 0):
		Engine.time_scale = 0.1
		get_tree().create_timer(0.1).timeout.connect(reset_time_scale)
		get_tree().create_timer(0.1).timeout.connect(reset_jump)

	if (from.dies_when_deal_damage):
		from.take_damage(1000)

func disable_movement() -> void:
	can_move = false
	get_tree().create_timer(0.8).timeout.connect(func() -> void:can_move = true)

func reset_can_get_hit() -> void:
	can_get_hit = true
	sprite.material.set_shader_parameter("tint", Color(1, 1, 1, 1))


# func handle_collision(collision: KinematicCollision2D) -> void:
# 	var am_i_above: bool = position.y < parent.get_position().y
# 	var am_i_moving_down: bool = previous_velocity.y > 0
# 	var will_atack: bool = is_attacking == 2 and am_i_above and am_i_moving_down
