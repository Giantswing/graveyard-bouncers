extends StaticBody2D

@onready var collision: CollisionShape2D = $Collision
@onready var display: Node2D = $Display
@onready var area: Area2D = $Area
@onready var sprite: AnimatedSprite2D = %Sprite

@export var speed: float = 100.0

var direction: int = 0
var player: PlayerCharacter
var is_active: bool = true
var is_dead: bool = false

func _ready() -> void:
	scale = Vector2.ZERO

	Utils.fast_tween(self, "scale", Vector2(1.0, 1.0), 1)

	sprite.play("Idle")
	speed = speed * randf_range(0.8, 1.5)
	player = GameManager.instance.player
	area.body_entered.connect(on_body_entered)
	sprite.animation_finished.connect(on_animation_finished)
	# change_direction(1 if randi() % 2 == 0 else -1)

	if position.x > 0:
		direction = -1
		sprite.flip_h = true
	else:
		direction = 1
		sprite.flip_h = false


func on_body_entered(body: Node2D) -> void:
	if body is PlayerCharacter:
		if (body.is_attacking == 2) and is_dead == false:
			die()
		elif (body.is_attacking != 2 and body.grounded) and is_dead == false:
			get_tree().create_timer(0.5).timeout.connect(die)

func die() -> void:
	is_dead = true
	set_collision_layer_value(8, false)
	sprite.play("Break")

func on_animation_finished() -> void:
	if sprite.animation == "Break":
		queue_free()

func _process(delta: float) -> void:
	translate(Vector2(speed * delta * direction, 0))
	constant_linear_velocity = Vector2(speed * direction, 0)

	if is_dead:
		return

	if player == null:
		return

	if player.is_attacking == 2 and is_active:
		is_active = false
		set_collision_layer_value(8, false)

	elif player.is_attacking != 2 and !is_active:
		is_active = true
		set_collision_layer_value(8, true)

	if is_active:
		display.modulate = lerp(display.modulate, Color(1, 1, 1, 1), 0.1)
	else:
		display.modulate = lerp(display.modulate, Color(1, 1, 1, 0.5), 0.1)


	if position.x > get_viewport_rect().size.x/2 + 100 or position.x < -get_viewport_rect().size.x/2 - 100:
		queue_free()


func change_direction(new_direction: int) -> void:
	if new_direction != direction:
		direction = new_direction
