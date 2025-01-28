extends Camera2D

@onready var noise:FastNoiseLite = FastNoiseLite.new()

@export var decay: float = 0.8
@export var max_offset: Vector2 = Vector2(100, 75)
@export var max_roll: float = 0.1
@export var shake_power: float = 2
@export var on_hit_shake: float = 0.1
@export var on_parry_shake: float = 0.1

var target: Node2D
var start_y_pos: float
@export var max_y_increase: float = 25

var current_shake_amount: float = 0

func _ready() -> void:
	Events.hp_changed.connect(on_hp_change)
	Events.player_parry.connect(on_player_parry)
	target = get_parent().get_node_or_null("%Player")
	start_y_pos = 0
	# start_y_pos = global_position.y


func on_hp_change(_hp: int, change: int) -> void:
	if change >= 0:
		return

	current_shake_amount = on_hit_shake

func on_player_parry() -> void:
	current_shake_amount = on_parry_shake 

	
func _process(delta: float) -> void:
	if current_shake_amount > 0:
		current_shake_amount = max(0, current_shake_amount - delta * decay)
		shake()

	point_target()


func point_target() -> void:
	if !target:
		return

	var dist := target.global_position - global_position
	var final_pos: float

	if GameManager.get_instance().round_started:
		final_pos = min(start_y_pos + 15, start_y_pos + dist.y * 0.2)
		position.y = lerp(position.y, final_pos, 0.05)
	else:
		final_pos = min(start_y_pos - 15, start_y_pos + dist.y * 0.7)
		position.y = lerp(position.y, final_pos, 0.02)

	if position.y > start_y_pos:
		position.y = start_y_pos
	

func shake() -> void:
	var current_amount: float = pow(current_shake_amount, shake_power)
	rotation = max_roll * current_amount * randf_range(-1, 1)
	offset.x = max_offset.x * current_amount * randf_range(-1, 1)
	offset.y = max_offset.y * current_amount * randf_range(-1, 1)
	
