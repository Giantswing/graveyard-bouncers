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
@export var dies_when_deal_damage: bool = false
@export var always_force_damage: bool = false
@export var gives_combo: bool = false

@onready var master_material: ShaderMaterial = load("res://shaders/materials/MasterMaterial.tres")

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
var time_dead: float = 0

@export var hit_sound: String = ""
@export var death_sound: String = ""


@warning_ignore_start("unused_signal")
signal on_death
signal on_hit
signal on_parry

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
		sprite.material = master_material.duplicate()

	if spawn_type == SPAWN_TYPE_OPTIONS.GROUND:
		owner.process_mode = Node.PROCESS_MODE_DISABLED

		if sprite:
			sprite.visible = false

		FxSystem.play_fx("ground-explosion", global_position - Vector2(0, 18))
		get_tree().create_timer(0.7).timeout.connect(func() -> void:
			owner.process_mode = Node.PROCESS_MODE_PAUSABLE

			if sprite:
				sprite.visible = true
		)
	else:
		# var original_scale: Vector2 = owner.scale
		owner.scale = Vector2.ZERO
		Utils.fast_tween(owner, "scale", Vector2(1.0, 1.0), 0.15, Tween.TRANS_QUAD)



func on_spawn_finished() -> void:
	pass

func on_animation_finished() -> void:
	if sprite.animation == "GetHit" and sprite.get_sprite_frames().has_animation("Idle"):
		sprite.play("Idle")


func _process(delta: float) -> void:

	if !is_alive and sprite:
		time_dead += delta
		if time_dead > 0.04:
			time_dead = 0
			sprite.position = Vector2(randf_range(-1, 1), 0)
			sprite.rotation = randf_range(-0.4, 0.4)


func hit_flash() -> void:
	if !sprite:
		return

	sprite.material.set_shader_parameter("hit_active", 1)
	sprite.offset = Vector2(0, 0)
	sprite.scale = Vector2(1.0, 1.0)

	var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(sprite, "offset", Vector2(0, 8.0), 0.05)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.05)
	tween.tween_property(sprite, "offset", Vector2(0, 0), 0.3)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3)
	tween.finished.connect(func() -> void:
		sprite.material.set_shader_parameter("hit_active", 0)
	)

func take_damage(amount: int, from_parry: bool = false, force: bool = false) -> void:
	if from_parry and can_be_parried:
		emit_signal("on_parry")

	if can_be_parried:
		can_be_parried = false
		get_tree().create_timer(invulnerable_time).timeout.connect(func() -> void:
			can_be_parried = true
		)

		
	if is_invulnerable:
		return

	if !can_take_damage and force == false and !always_force_damage:
		return

	hp -= amount
	is_invulnerable = true

	get_tree().create_timer(invulnerable_time).timeout.connect(reset_invulnerable)

	if sprite and sprite.get_sprite_frames().has_animation("GetHit"):
		sprite.play("GetHit")


	if hp <= 0:
		if death_sound != "":
			SoundSystem.play_audio(death_sound)
		die(from_parry)
	else:
		emit_signal("on_hit")
		Events.enemy_hit.emit(self, from_parry)

		if hit_sound != "":
			SoundSystem.play_audio(hit_sound)

		hit_flash()

func die(from_parry: bool = false) -> void:
	if !is_alive:
		return

	is_alive = false

	if sprite:
		sprite.material.set_shader_parameter("hit_active", 1)

	parent.scale = Vector2(scale.x * 1.2, scale.y * 1.1)
	emit_signal("on_death")

	var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(sprite, "offset", Vector2(0, 8.0), 0.05)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.05)
	# tween.parallel().tween_property(sprite, "material:shader_parameter/dissolve_percentage", 0, 0.5)

	Utils.fast_tween(parent, "scale", Vector2(0, 0), 0.35, Tween.TRANS_ELASTIC).tween_callback(
		func() -> void:
		parent.queue_free()
	)

	if hurt_area:
		hurt_area.queue_free()

	Events.enemy_died.emit(self, from_parry)

	if GameManager.get_instance().has_powerup("vampiric") and can_take_damage:
		var chance: float = 0.1
		if randf() < chance:
			var heart: Node2D = GameManager.get_instance().heart_reward.instantiate()
			heart.global_position = global_position
			owner.get_parent().add_child(heart)
		

	if spawn_rate_reduction > 0:
		GameManager.get_instance().enemy_spawn_countdown -= spawn_rate_reduction
	
	# if score_reward != 0:
	# 	Events.score_changed.emit(GameManager.get_instance().score + score_reward)

	if wall_reward != 0:
		GameManager.get_instance().game_width -= wall_reward

	parent.process_mode = Node.PROCESS_MODE_DISABLED


func reset_invulnerable() -> void:
	is_invulnerable = false
