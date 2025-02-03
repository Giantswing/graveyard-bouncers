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
var extra_speed: float = 0.0
@export var zoom_speed: float = 0.01
@export var zoom_increase: float = 0.1


enum MODES { 
	BEFORE_ROUND,
	IN_ROUND,
	CHALLENGE_MODE,
}

var current_mode: MODES = MODES.BEFORE_ROUND

var current_shake_amount: float = 0

func _ready() -> void:
	current_zoom = zoom.x
	current_zoom_to = zoom.x

	Events.hp_changed.connect(on_hp_change)
	Events.player_parry.connect(on_player_parry)
	Events.player_dash.connect(on_player_parry)
	target = get_parent().get_node_or_null("%Player")
	start_y_pos = 0

	Events.round_started.connect(func() -> void:
		current_mode = MODES.IN_ROUND
	)

	Events.round_ended.connect(func() -> void:
		current_mode = MODES.BEFORE_ROUND
	)


	Events.enter_challenge_mode.connect(func(_enter_player: PlayerCharacter) -> void:
		current_mode = MODES.CHALLENGE_MODE
		extra_speed = 0.1
	)

	Events.exit_challenge_mode.connect(func(_exit_player: PlayerCharacter) -> void:
		current_mode = MODES.BEFORE_ROUND
		extra_speed = 2
	)

	# start_y_pos = global_position.y


func on_hp_change(_hp: int, change: int) -> void:
	if change >= 0:
		return

	current_shake_amount = on_hit_shake

	
func _process(delta: float) -> void:
	# return
	extra_speed = lerp(extra_speed, 0.0, 0.02)

	current_zoom = lerp(current_zoom, current_zoom_to, zoom_speed)

	if current_mode == MODES.IN_ROUND:
		current_zoom_to = 1
	elif current_mode == MODES.BEFORE_ROUND:
		current_zoom_to = 1 + zoom_increase
	elif current_mode == MODES.CHALLENGE_MODE:
		current_zoom_to = 1

	zoom = Vector2(current_zoom, current_zoom)
	if abs(current_zoom - current_zoom_to) < 0.005:
		current_zoom = current_zoom_to

	if current_shake_amount > 0:
		current_shake_amount = max(0, current_shake_amount - delta * decay)
		shake()

	point_target(delta)



func on_player_parry() -> void:
	current_shake_amount = on_parry_shake 
	make_shockwave(0.2, 1, 0.3, 0.45)

func make_shockwave(force: float, duration: float, size: float, decay_time: float) -> void:
	wave.material.set_shader_parameter("size", size * 0.25)
	wave.material.set_shader_parameter("force", force)

	Utils.fast_tween(wave, "material:shader_parameter/size", size, duration * 0.2, Tween.TRANS_QUAD)
	Utils.fast_tween(wave, "material:shader_parameter/force", 0.0, decay_time, Tween.TRANS_QUAD)

func point_target(delta: float) -> void:
	if !target:
		return

	var wave_position: Vector2 = Vector2(get_viewport_rect().size.x * GameManager.instance.player_screen_pos.x, get_viewport_rect().size.y * (1 - GameManager.instance.player_screen_pos.y))
	wave.material.set_shader_parameter("global_position", wave_position)

	var dist := target.global_position - global_position
	var final_pos: float

	if current_mode == MODES.IN_ROUND:
		final_pos = min(start_y_pos + 45, start_y_pos + dist.y * 0.2)
		position.y = lerp(position.y, final_pos, in_round_speed * delta * 60.0)
		if position.y > start_y_pos:
			position.y = start_y_pos

	elif current_mode == MODES.BEFORE_ROUND:
		final_pos = min(start_y_pos + 25, start_y_pos + dist.y)
		position.y = lerp(position.y, final_pos, before_round_speed * delta * 60.0)
		position.x = lerp(position.x, 0.0, (before_round_speed + extra_speed) * delta * 60.0)

		if position.y > start_y_pos:
			position.y = start_y_pos
	elif current_mode == MODES.CHALLENGE_MODE:
		position.x = lerp(position.x, target.global_position.x, 0.05 * delta * 60.0)
		position.y = lerp(position.y, target.global_position.y, (0.01 + extra_speed) * delta * 60.0)

	

func shake() -> void:
	var current_amount: float = pow(current_shake_amount, shake_power)
	rotation = max_roll * current_amount * randf_range(-1, 1)
	offset.x = max_offset.x * current_amount * randf_range(-1, 1)
	offset.y = max_offset.y * current_amount * randf_range(-1, 1)
	
