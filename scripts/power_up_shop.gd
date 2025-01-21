extends Node2D

@export var all_powerups: Array[PowerUp]
@export var instance: PackedScene
@export var instance_width: int = 24
@export var instance_padding: int = 8

var is_active: bool = false
@export var amount_of_powerups: int = 2
var displayed_powerups: Array[PowerUpInstance] = []

func _ready() -> void:
	displayed_powerups.resize(amount_of_powerups)
	Events.round_started.connect(close_shop)
	Events.round_ended.connect(on_round_ended)
	# display_shop()
	

func on_round_ended() -> void:
	display_shop()


func display_shop() -> void:
	for i in range(amount_of_powerups):
		spawn_powerup(i)

func close_shop() -> void:
	for powerup in displayed_powerups:
		if powerup != null:
			powerup.queue_free()


func spawn_powerup(i: int) -> void:
	var total_chance: float = 0
	for powerup in all_powerups:
		total_chance += powerup.chance

	var chance: float = randf() * total_chance
	var current_chance: float = 0

	for powerup in all_powerups:
		current_chance += powerup.chance
		if chance > current_chance:
			continue
	
		var new_instance: PowerUpInstance = instance.instantiate()
		new_instance.powerup = powerup
		new_instance.position = Vector2(i * (instance_width + instance_padding), 0)
		displayed_powerups[i] = new_instance
		add_child(new_instance)

		return
