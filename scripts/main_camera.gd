extends Camera2D

@onready var noise:FastNoiseLite = FastNoiseLite.new()

@export var decay: float = 0.8
@export var max_offset: Vector2 = Vector2(100, 75)
@export var max_roll: float = 0.1
@export var shake_power: float = 2
@export var on_hit_shake: float = 0.1
@export var on_parry_shake: float = 0.1

var current_shake_amount: float = 0

func _ready():
	Events.hp_changed.connect(on_hp_change)
	Events.player_parry.connect(on_player_parry)

func on_hp_change(_hp: int, change: int):
	if change >= 0:
		return

	current_shake_amount = on_hit_shake

func on_player_parry():
	current_shake_amount = on_parry_shake 

	
func _process(delta: float) -> void:
	if current_shake_amount > 0:
		current_shake_amount = max(0, current_shake_amount - delta * decay)
		shake()


func shake():
	var current_amount: float = pow(current_shake_amount, shake_power)
	rotation = max_roll * current_amount * randf_range(-1, 1)
	offset.x = max_offset.x * current_amount * randf_range(-1, 1)
	offset.y = max_offset.y * current_amount * randf_range(-1, 1)
	
