extends CharacterBody2D

@export var speed: float = 50
@export var wobble: float = 0.1
@export var wobble_speed: float = 1
@onready var sprite: AnimatedSprite2D = $Sprite
var direction: int = 0
var timer: float = 0


func _ready():
	scale = Vector2(0, 0)
	var tween := get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.5)

	speed = speed * randf_range(0.8, 1.2)
	wobble = wobble * randf_range(0.9, 1.1)
	wobble_speed = wobble_speed * randf_range(0.9, 1.1)

	if position.x > 0:
		direction = -1
	else:
		sprite.flip_h = 1
		direction = 1

	velocity.x = speed * direction

func _process(_delta):
	timer += _delta * wobble_speed * Engine.time_scale
	position.y += sin(timer) * wobble

	if position.x > get_viewport_rect().size.x/2 + 40 or position.x < -get_viewport_rect().size.x/2 - 40:
		queue_free()


func _physics_process(_delta):
	move_and_slide()
