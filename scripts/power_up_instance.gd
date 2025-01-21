extends StaticBody2D

class_name PowerUpInstance

@export var powerup: PowerUp

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var stats: Stats = $Stats
@onready var cost_label: Label = %PowerUpCostLabel

var active: bool = true

func _ready() -> void:
	sprite.sprite_frames = powerup.frames
	sprite.play("default")
	cost_label.text = str(powerup.cost)
	stats.on_death.connect(on_pickup)
	%BubbleBack.play("ShineBack")
	%BubbleFront.play("ShineFor")

func _process(_delta: float) -> void:
	if GameManager.coins < powerup.cost and active:
		active = false
		set_collision_layer_value(3, false)
		# sprite.modulate = Color(1, 1, 1, 0.5)
	
func on_pickup() -> void:
	FxSystem.play_fx("PowerUpPicked", global_position)
	Events.coins_changed.emit(GameManager.coins - powerup.cost)
	Events.picked_up_powerup.emit(powerup)
