extends CharacterBody2D

@export var speed: float = 50
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var body_forward_cast: RayCast2D = $BodyForwardCast

var raycast_length_x: float = 0

var direction: int = 0
var game_manager: GameManager

func _ready() -> void:
	raycast_length_x = body_forward_cast.target_position.x
	change_direction(1 if randi() % 2 == 0 else -1)
	sprite.play("Walk")
	game_manager = GameManager.get_instance()


func _physics_process(_delta: float) -> void:
	# if !is_on_floor():
	# 	velocity.y += get_gravity().y * delta

	velocity.x = speed * direction

	if body_forward_cast.is_colliding():
		change_direction(-direction)

	var padding: float = 20
	if global_position.x > game_manager.game_width / 2 - padding:
		global_position.x = game_manager.game_width / 2 - padding
	elif global_position.x < -game_manager.game_width / 2 + padding:
		global_position.x = -game_manager.game_width / 2 + padding

	move_and_slide()


func change_direction(new_direction: int) -> void:
	if new_direction != direction:
		direction = new_direction
		sprite.flip_h = direction == -1
		body_forward_cast.target_position = Vector2(direction * raycast_length_x, 0)
