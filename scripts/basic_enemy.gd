extends Node

enum ENEMY_TYPE_OPTIONS {
	GROUND_BASIC,
	FLOATING_BASIC,
}

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var stats: Stats = $Stats
@onready var forward_raycast: RayCast2D = $ForwardRaycast

@export var speed: float = 50
@export var enemy_type: ENEMY_TYPE_OPTIONS = ENEMY_TYPE_OPTIONS.GROUND_BASIC

var direction: int = 0
var state: String = "Spawn"

func _ready() -> void:
	sprite.animation_finished.connect(on_animation_finished)

	if sprite.get_sprite_frames().has_animation("Spawn"):
		sprite.play("Spawn")
	else:
		state = "Idle"
	

func on_animation_finished() -> void:
	if sprite.animation == "Spawn":
		sprite.play("Idle")
