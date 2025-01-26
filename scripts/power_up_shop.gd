extends Node2D

@export var all_powerups: Array[PowerUp]

@export var instance: PackedScene
@export var instance_width: int = 24
@export var instance_padding: int = 8

var is_active: bool = false
@export var amount_of_powerups: int = 2
var displayed_powerups: Array[PowerUpInstance] = []

func _ready() -> void:
	for i in range(all_powerups.size()):
		all_powerups[i] = all_powerups[i].duplicate(true)

	displayed_powerups.resize(amount_of_powerups)
	Events.round_started.connect(close_shop)
	Events.round_ended.connect(on_round_ended)
	Events.picked_up_powerup.connect(on_powerup_picked_up)
	set_up_powerups()
	display_shop()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Menu"):
		Events.coins_changed.emit(20)

		if is_active:
			close_shop()
		else:
			display_shop()

func set_up_powerups() -> void:
	for powerup in all_powerups:
		# print(str(powerup.power_up_name) + ", " + str(powerup.amount) + ", " + str(powerup.chance))
		powerup.original_chance = powerup.chance

	
func on_powerup_picked_up(powerup: PowerUp) -> void:
	for i in range(all_powerups.size()):
		if all_powerups[i] == powerup:
			all_powerups[i].amount -= 1
			if all_powerups[i].amount == 0:
				all_powerups.pop_at(i)
				break

			break

func on_round_ended() -> void:
	display_shop()

func display_shop() -> void:
	displayed_powerups.resize(amount_of_powerups)
	is_active = true

	for powerup in all_powerups:
		powerup.chance = powerup.original_chance

	for i in range(amount_of_powerups):
		spawn_powerup(i)

func close_shop() -> void:
	is_active = false

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

		powerup.chance = 0

		return
