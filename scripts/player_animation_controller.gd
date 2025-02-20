extends Node

class_name PlayerAnimationController

@onready var sprite: AnimatedSprite2D = $"../Sprite"
var current_animation: String = "idle"


func _ready() -> void:
	play_animation("idle")
	sprite.animation_finished.connect(on_animation_finished)


func on_animation_finished() -> void:
	if sprite.animation == "parry" or sprite.animation == "dash":
		play_animation("jump")


func handle_animation(movement_input: Vector2, velocity: Vector2, grounded:bool, on_wall:bool, is_attacking: int, received_damage: bool) -> void:
	if current_animation == "attack" and is_attacking == 0:
		play_animation("idle")

	if movement_input.x != 0 and grounded:
		play_animation("run")
	elif movement_input.x == 0 and grounded:
		play_animation("idle")

	if current_animation == "run" and movement_input.x == 0:
		play_animation("idle")

	if (current_animation == "run" || current_animation == "idle") and !grounded and current_animation != "parry":
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



func play_animation(animation: String, restart: bool = false) -> void:
	if restart:
		sprite.play(animation)
		sprite.stop()
		sprite.frame = 0
		sprite.play(animation)
	else:
		sprite.play(animation)
		

	current_animation = animation
	
