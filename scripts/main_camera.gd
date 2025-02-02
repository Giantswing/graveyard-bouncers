extends Camera2D

@onready var noise: FastNoiseLite = FastNoiseLite.new()
@onready var wave: ColorRect = %ScreenShockWave

@export var decay: float = 0.8
@export var max_offset: Vector2 = Vector2(100, 75)
@export var max_roll: float = 0.1
@export var shake_power: float = 2
@export var on_hit_shake: float = 0.1
@export var on_parry_shake: float = 0.1

var target: Node2D
var start_y_pos: float
@export var max_y_increase: float = 25

@export var before_round_speed: float = 0.05
@export var in_round_speed: float = 0.05

var current_zoom: float = 1
var current_zoom_to: float = 1
@export var zoom_speed: float = 0.01
@export var zoom_increase: float = 0.1

var current_shake_amount: float = 0

func _ready() -> void:
	current_zoom = zoom.x
	current_zoom_to = zoom.x

	Events.hp_changed.connect(on_hp_change)
	Events.player_parry.connect(on_player_parry)
	target = get_parent().get_node_or_null("%Player")
	start_y_pos = 0
	# start_y_pos = global_position.y


func on_hp_change(_hp: int, change: int) -> void:
	if change >= 0:
		return

	current_shake_amount = on_hit_shake

	
func _process(delta: float) -> void:
	# return


	current_zoom = lerp(current_zoom, current_zoom_to, zoom_speed)

	if GameManager.instance.round_started:
		current_zoom_to = 1
	else:
		current_zoom_to = 1 + zoom_increase

	zoom = Vector2(current_zoom, current_zoom)
	if abs(current_zoom - current_zoom_to) < 0.005:
		current_zoom = current_zoom_to

	if current_shake_amount > 0:
		current_shake_amount = max(0, current_shake_amount - delta * decay)
		shake()

	point_target()



func on_player_parry() -> void:
	current_shake_amount = on_parry_shake 
	make_shockwave(0.1, 1, 0.25, 0.75)

func make_shockwave(force: float, duration: float, size: float, decay_time: float) -> void:
	wave.material.set_shader_parameter("size", size * 0.35)
	wave.material.set_shader_parameter("force", force)

	Utils.fast_tween(wave, "material:shader_parameter/size", size, duration * 0.2, Tween.TRANS_QUAD)
	Utils.fast_tween(wave, "material:shader_parameter/force", 0.0, decay_time, Tween.TRANS_QUAD)

func point_target() -> void:
	if !target:
		return

	var wave_position: Vector2 = Vector2(get_viewport_rect().size.x * GameManager.instance.player_screen_pos.x, get_viewport_rect().size.y * (1 - GameManager.instance.player_screen_pos.y))
	wave.material.set_shader_parameter("global_position", wave_position)

	var dist := target.global_position - global_position
	var final_pos: float

	if GameManager.get_instance().round_started:
		final_pos = min(start_y_pos + 45, start_y_pos + dist.y * 0.2)
		position.y = lerp(position.y, final_pos, in_round_speed)
	else:
		final_pos = min(start_y_pos + 25, start_y_pos + dist.y)
		position.y = lerp(position.y, final_pos, before_round_speed)

	if position.y > start_y_pos:
		position.y = start_y_pos
	

func shake() -> void:
	var current_amount: float = pow(current_shake_amount, shake_power)
	rotation = max_roll * current_amount * randf_range(-1, 1)
	offset.x = max_offset.x * current_amount * randf_range(-1, 1)
	offset.y = max_offset.y * current_amount * randf_range(-1, 1)
	
