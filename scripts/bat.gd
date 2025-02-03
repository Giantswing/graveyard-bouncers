extends CharacterBody2D

@export var speed: float = 50
@export var wobble: float = 0.1
@export var wobble_speed: float = 1
@onready var sprite: AnimatedSprite2D = $Sprite
var direction: int = 0
var timer: float = 0
var game_manager: GameManager


func _ready() -> void:
	game_manager = GameManager.instance
	speed = speed * randf_range(0.8, 1.2)
	wobble = wobble * randf_range(0.9, 1.1)
	wobble_speed = wobble_speed * randf_range(0.9, 1.1)

	if position.x > 0:
		direction = -1
	else:
		sprite.flip_h = 1
		direction = 1

	velocity.x = speed * direction

func _process(delta: float) -> void:
	timer += delta * wobble_speed

	if position.x > get_viewport_rect().size.x/2 + 100 or position.x < -get_viewport_rect().size.x/2 - 100:
		queue_free()


func _physics_process(_delta: float) -> void:
	if game_manager.game_paused:
		return

	position.y += sin(timer) * wobble
	move_and_slide()
