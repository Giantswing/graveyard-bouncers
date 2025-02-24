extends Node

class_name PlayerAnimationController

@onready var sprite: AnimatedSprite2D = $"../Sprite"
var current_animation: String = "idle"
var last_fall_animation: float = 0


func _ready() -> void:
	play_animation("idle")
	sprite.animation_finished.connect(on_animation_finished)


func on_animation_finished() -> void:
	if sprite.animation == "parry" or sprite.animation == "dash":
		play_animation("jump")

func animate_fall(movement_input: Vector2, type: String = "normal") -> void:
	if last_fall_animation < 0.5:
		return

	last_fall_animation = 0

	sprite.position = Vector2(0, 0)
	sprite.scale = Vector2(1, 1)

	var rot: float = 0
	if movement_input.x > 0:
		rot = 1
	elif movement_input.x < 0:
		rot = -1

	if type == "attack" or type == "wall":
		rot *= 20
	else:
		rot *= 10

	if type == "normal" or type == "attack":
		var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_SPRING)
		tween.tween_property(sprite, "scale", Vector2(1.4, 0.6), 0.05)
		tween.parallel().tween_property(sprite, "rotation_degrees", rot, 0.05)
		tween.parallel().tween_property(sprite, "position", Vector2(0, 10), 0.05)
		tween.tween_property(sprite, "scale", Vector2(1, 1), 0.2)
		tween.parallel().tween_property(sprite, "position", Vector2(0, 0), 0.2)
		tween.parallel().tween_property(sprite, "rotation_degrees", 0, 0.2)
	elif type == "parry":
		var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_SPRING)

		tween.tween_property(sprite, "scale", Vector2(1.1, 0.9), 0.15)
		tween.parallel().tween_property(sprite, "rotation_degrees", rot, 0.15)
		tween.parallel().tween_property(sprite, "position", Vector2(0, 10), 0.15)

		tween.tween_property(sprite, "scale", Vector2(0.8, 1.5), 0.15)

		tween.tween_property(sprite, "scale", Vector2(1, 1), 0.2)
		tween.parallel().tween_property(sprite, "position", Vector2(0, 0), 0.2)
		tween.parallel().tween_property(sprite, "rotation_degrees", 0, 0.2)
	if type == "wall":
		var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_SPRING)

		tween.tween_property(sprite, "scale", Vector2(0.9, 1.3), 0.15)
		tween.parallel().tween_property(sprite, "rotation_degrees", rot, 0.15)
		tween.parallel().tween_property(sprite, "position", Vector2(0, -5), 0.15)

		# tween.tween_property(sprite, "scale", Vector2(0.8, 1.2), 0.15)

		tween.tween_property(sprite, "scale", Vector2(1, 1), 0.5)
		tween.parallel().tween_property(sprite, "position", Vector2(0, 0), 0.5)
		tween.parallel().tween_property(sprite, "rotation_degrees", 0, 0.4)

func _process(delta: float) -> void:
	last_fall_animation += delta

func handle_animation(movement_input: Vector2, velocity: Vector2, grounded:bool, on_wall:bool, is_attacking: int, received_damage: bool) -> void:
	if current_animation == "attack" and is_attacking == 0:
		play_animation("idle")

	if movement_input.x != 0 and grounded and current_animation != "dash":
		play_animation("run")
	elif movement_input.x == 0 and grounded and current_animation != "dash":
		play_animation("idle")

	if current_animation == "run" and movement_input.x == 0:
		play_animation("idle")

	if (current_animation == "run" || current_animation == "idle") and !grounded:
		play_animation("jump")

	if current_animation == "jump" and velocity.y > 0:
		play_animation("fall")

	if on_wall and !grounded and velocity.y > 0:
		play_animation("wallslide")

	if !on_wall and current_animation == "wallslide":
		play_animation("jump")

	if received_damage:
		play_animation("hit")
	elif current_animation == "hit" and !received_damage:
		play_animation("fall")


	if movement_input.x > 0:
		sprite.flip_h = false
	elif movement_input.x < 0:
		sprite.flip_h = true



func play_animation(animation: String, restart: bool = false, frame: int = 0) -> void:
	if restart:
		sprite.play(animation)
		sprite.stop()
		sprite.frame = frame
		sprite.play(animation)
	else:
		sprite.play(animation)
		

	current_animation = animation
	
