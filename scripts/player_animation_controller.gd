extends Node

class_name PlayerAnimationController

@onready var sprite: AnimatedSprite2D = $"../Sprite"
var current_animation: String = "idle"


func _ready() -> void:
	play_animation("idle")
	sprite.animation_finished.connect(on_animation_finished)


func on_animation_finished() -> void:
	if sprite.animation == "parry":
		sprite.play("idle")


func handle_animation(movement_input: Vector2, velocity: Vector2, grounded:bool, on_wall:bool, is_attacking: int) -> void:
	if current_animation == "attack" and is_attacking == 0:
		play_animation("idle")

	if movement_input.x != 0 and grounded:
		play_animation("run")
	elif movement_input.x == 0 and grounded:
		play_animation("idle")

	if current_animation == "run" and movement_input.x == 0:
		play_animation("idle")

	if (current_animation == "run" || current_animation == "idle") and !grounded:
		play_animation("jump")

	# if current_animation == "jump" and velocity.y > 0:
	# 	play_animation("fall")

	if velocity.x > 5 and !on_wall:
		sprite.flip_h = false
	elif velocity.x < -5 and !on_wall:
		sprite.flip_h = true



func play_animation(animation: String) -> void:
	current_animation = animation
	sprite.play(animation)
	pass
