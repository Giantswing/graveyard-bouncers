extends Node2D

class_name Pickup

@onready var area: Area2D = $Area2D

@export var pickup_option: PICKUP_OPTIONS = PICKUP_OPTIONS.COIN
var pickup_state: int = 0 # 0 = not picked up, 1 = moving away, 2 = moving towards player
var target: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var time_following: float = 0
var speed: float = 15
var max_speed: float = 600
var follow_particles: GPUParticles2D = null
var player: PlayerCharacter = null

enum PICKUP_OPTIONS {
	COIN,
	ABILITY_ORB,
}

func _ready() -> void:
	scale = Vector2.ZERO
	Utils.fast_tween(self, "scale", Vector2(1.0, 1.0), 0.15, Tween.TRANS_QUAD)

	follow_particles = get_node_or_null("FollowParticles")
	if follow_particles:
		follow_particles.emitting = false

	area.body_entered.connect(
		func(body: Node2D) -> void:
			if body is PlayerCharacter:
				pickup(body)
	)

	if GameManager.instance.has_powerup("reward-magnet"):
		area.scale = Vector2(3, 3)

func reparent_pickup() -> void:
	self.reparent(get_tree().root)

func pickup(body: Node2D) -> void:
	if pickup_state != 0:
		return

	pickup_state = 1
	target = body
	player = body as PlayerCharacter

	if follow_particles:
		follow_particles.emitting = true 

func _process(delta: float) -> void:
	if !target or pickup_state == 0:
		return

	var my_pos: Vector2 = global_position
	var other_pos: Vector2 = target.global_position
	var direction: Vector2 = (other_pos - my_pos).normalized()

	time_following += delta

	if pickup_state == 1:
		velocity += -direction * speed

		if time_following > 0.2:
			pickup_state = 2
			time_following = 0

	elif pickup_state == 2:
		other_pos = target.global_position + player.velocity * 0.1
		direction = (other_pos - my_pos).normalized()

		time_following += delta
		velocity += direction * speed * 2

		if my_pos.distance_to(other_pos) < 32 or time_following > 3:
			if pickup_option == PICKUP_OPTIONS.COIN:
				Events.coins_changed.emit(GameManager.get_instance().coins + 1)
				FxSystem.play_fx("coin-collect", global_position)

			elif pickup_option == PICKUP_OPTIONS.ABILITY_ORB:
				GameManager.instance.gain_ability(GameManager.instance.find_ability("dash"))
				FxSystem.play_fx("power-up-picked", global_position)

			queue_free()

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	global_position += velocity * delta
