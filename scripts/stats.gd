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
@export var damage_on_touch: bool = false
@export var spawn_rate_reduction: float = 0
@export var sprite: AnimatedSprite2D
var area: Area2D

enum DEATH_BEHAVIOUR_OPTIONS {
	DEFAULT,
	START_ROUND
}

@export var death_behaviour: DEATH_BEHAVIOUR_OPTIONS = DEATH_BEHAVIOUR_OPTIONS.DEFAULT

var is_invulnerable = false
var parent: Node2D


@warning_ignore_start("unused_signal")
signal on_death
signal on_hit

func _ready() -> void:
	hp = hp_max
	parent = get_parent()
	if sprite:
		sprite.animation_finished.connect(on_animation_finished)

	if damage_on_touch:
		area = $Area2D
		area.body_entered.connect(on_area_entered)


func on_area_entered(_body: Node) -> void:
	if coin_reward != 0:
		Events.coins_changed.emit(GameManager.get_instance().coins + coin_reward)
		FxSystem.play_fx("CoinCollect", global_position)
		get_parent().queue_free()
	
	

func on_spawn_finished() -> void:
	pass

func on_animation_finished() -> void:
	if sprite.animation == "GetHit" and sprite.get_sprite_frames().has_animation("Idle"):
		sprite.play("Idle")


func take_damage(amount: int) -> void:
	hp -= amount

	is_invulnerable = true
	get_tree().create_timer(invulnerable_time).timeout.connect(reset_invulnerable)

	if sprite and sprite.get_sprite_frames().has_animation("GetHit"):
		sprite.play("GetHit")

	if hp <= 0:
		if spawn_rate_reduction > 0:
			GameManager.get_instance().enemy_spawn_countdown -= spawn_rate_reduction
		
		if score_reward != 0:
			Events.score_changed.emit(GameManager.get_instance().score + score_reward)

		if wall_reward != 0:
			GameManager.get_instance().game_width -= wall_reward

		emit_signal("on_death")

		if death_behaviour == DEATH_BEHAVIOUR_OPTIONS.START_ROUND:
			hp = hp_max
			death_behaviour_start_round()
		else:
			parent.queue_free()


func death_behaviour_start_round() -> void:
	Events.round_started.emit()

func reset_invulnerable() -> void:
	is_invulnerable = false
