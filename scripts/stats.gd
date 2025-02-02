extends Node2D

class_name Stats

@export var hp: int = 1
@export var hp_max: int = 1
@export var damage: int = 0
@export var bounciness: float = 1
@export var invulnerable_time: float = 0.5
@export var score_reward: int = 0
@export var coin_reward: int = 0
@export var wall_reward: int = 0
@export var can_take_damage: bool = true
@export var can_be_parried: bool = true
@export var spawn_rate_reduction: float = 0
@export var sprite: AnimatedSprite2D
@export var spawn_type: SPAWN_TYPE_OPTIONS = SPAWN_TYPE_OPTIONS.DEFAULT
@export var only_damage_when_moving_down: bool = false

var hurt_area: Area2D
var area: Area2D
@export var height: int = 24

enum DEATH_BEHAVIOUR_OPTIONS {
	DEFAULT,
}

enum SPAWN_TYPE_OPTIONS {
	DEFAULT,
	AIR,
	GROUND,
}

@export var death_behaviour: DEATH_BEHAVIOUR_OPTIONS = DEATH_BEHAVIOUR_OPTIONS.DEFAULT

var is_invulnerable: bool = false
var is_alive: bool = true
var parent: Node2D


@warning_ignore_start("unused_signal")
signal on_death
signal on_hit

func _ready() -> void:
	hp = hp_max
	parent = get_parent()
	hurt_area = get_node_or_null("HurtArea")

	if hurt_area and damage > 0:
		hurt_area.body_entered.connect(
			func(body: Node2D) -> void:
				if body is PlayerCharacter:
					body.get_hit(self)
	)

	if !sprite:
		sprite = owner.get_node_or_null("Sprite")

	if sprite:
		sprite.animation_finished.connect(on_animation_finished)

	if spawn_type == SPAWN_TYPE_OPTIONS.GROUND:
		owner.process_mode = Node.PROCESS_MODE_DISABLED

		if sprite:
			sprite.visible = false

		FxSystem.play_fx("GroundExplosion", global_position - Vector2(0, 18))
		get_tree().create_timer(0.7).timeout.connect(func() -> void:
			owner.process_mode = Node.PROCESS_MODE_PAUSABLE

			if sprite:
				sprite.visible = true
		)


# func on_area_entered(_body: Node) -> void:
# 	if coin_reward != 0:
# 		Events.coins_changed.emit(GameManager.get_instance().coins + coin_reward)
# 		FxSystem.play_fx("CoinCollect", global_position)
# 		get_parent().queue_free()
	
	

func on_spawn_finished() -> void:
	pass

func on_animation_finished() -> void:
	if sprite.animation == "GetHit" and sprite.get_sprite_frames().has_animation("Idle"):
		sprite.play("Idle")



func hit_flash() -> void:
	if !sprite or !sprite.material:
		return

	sprite.material.set_shader_parameter("active", 1)
	sprite.offset = Vector2(0, 3.0)
	sprite.scale = Vector2(1.0, 0.8)

	get_tree().create_timer(0.1).connect("timeout", func() -> void:
		sprite.material.set_shader_parameter("active", 0)
		sprite.offset = Vector2(0, 0)
		sprite.scale = Vector2(1.0, 1.0)
	)

func take_damage(amount: int) -> void:
	if !can_take_damage or is_invulnerable:
		return

	hp -= amount

	emit_signal("on_hit")
	is_invulnerable = true
	get_tree().create_timer(invulnerable_time).timeout.connect(reset_invulnerable)

	if sprite and sprite.get_sprite_frames().has_animation("GetHit"):
		sprite.play("GetHit")

	if hp <= 0:
		die()
	else:
		hit_flash()

func die() -> void:
	if !is_alive:
		return

	is_alive = false

	if sprite:
		sprite.material.set_shader_parameter("active", 1)

	Utils.fast_tween(parent, "scale", Vector2(0, 0), 0.2, Tween.TRANS_ELASTIC).tween_callback(
		func() -> void:
		emit_signal("on_death")
		parent.queue_free()
	)

	if hurt_area:
		hurt_area.queue_free()

	if spawn_rate_reduction > 0:
		GameManager.get_instance().enemy_spawn_countdown -= spawn_rate_reduction
	
	if score_reward != 0:
		Events.score_changed.emit(GameManager.get_instance().score + score_reward * 10)

	if wall_reward != 0:
		GameManager.get_instance().game_width -= wall_reward


func reset_invulnerable() -> void:
	is_invulnerable = false
