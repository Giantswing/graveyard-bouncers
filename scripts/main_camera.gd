extends Camera2D

@onready var noise: FastNoiseLite = FastNoiseLite.new()
@onready var wave: ColorRect = %ScreenShockWave

@export var decay: float = 0.8
@export var max_offset: Vector2 = Vector2(100, 75)
@export var max_roll: float = 0.1
@export var shake_power: float = 2
@export var on_hit_shake: float = 0.1
@export var on_parry_shake: float = 0.2

var simple_target: Node2D
var targets: Array[CameraTarget] = []
var final_target_pos: Vector2

var targets_zoom: float = 0
var max_targets_zoom: float = 0.25
var round_zoom: float = 1
var zoom_speed: float = 0.01


@export var bottom_limit: float = 0
@export var follow_speed: Vector2 = Vector2(0.08, 0.06)


var current_shake_amount: float = 0

func _ready() -> void:
	Events.hp_changed.connect(on_hp_change)
	Events.player_parry.connect(on_player_parry)
	Events.player_dash.connect(on_player_parry)

	Events.ctarget_add.connect(add_camera_target)
	Events.ctarget_remove.connect(remove_camera_target)


func add_camera_target(new_target: CameraTarget) -> void:
	if not targets.has(new_target):
		targets.append(new_target)

func remove_camera_target(remove_target: CameraTarget) -> void:
	targets.erase(remove_target)


func on_hp_change(_hp: int, change: int) -> void:
	if change >= 0:
		return

	current_shake_amount = on_hit_shake

	
func _process(delta: float) -> void:
	if GameManager.instance.game_mode == GameManager.MODES.IN_ROUND:
		round_zoom = 1
	elif GameManager.instance.game_mode == GameManager.MODES.BEFORE_ROUND:
		round_zoom = 1.3
	elif GameManager.instance.game_mode == GameManager.MODES.CHALLENGE_MODE:
		round_zoom = 1
	else:
		round_zoom = 1

	var zoom_target: float = round_zoom + (targets_zoom * -1)
	zoom = Vector2(lerp(zoom.x, zoom_target, zoom_speed), lerp(zoom.y, zoom_target, zoom_speed))

	if abs(zoom.x - zoom_target) < 0.005:
		zoom = Vector2(zoom_target, zoom_target)

	if current_shake_amount > 0:
		current_shake_amount = max(0, current_shake_amount - delta * decay)
		shake()

	point_target_v2(delta)


func on_player_parry() -> void:
	current_shake_amount = on_parry_shake 
	make_shockwave(0.2, 1, 0.3, 0.45)


func make_shockwave(force: float, duration: float, size: float, decay_time: float) -> void:
	wave.material.set_shader_parameter("size", size * 0.25)
	wave.material.set_shader_parameter("force", force)

	Utils.fast_tween(wave, "material:shader_parameter/size", size, duration * 0.2, Tween.TRANS_QUAD)
	Utils.fast_tween(wave, "material:shader_parameter/force", 0.0, decay_time, Tween.TRANS_QUAD)


func point_target_v2(_delta: float) -> void:
	var wave_position: Vector2 = Vector2(get_viewport_rect().size.x * GameManager.instance.player_screen_pos.x, get_viewport_rect().size.y * (1 - GameManager.instance.player_screen_pos.y))
	wave.material.set_shader_parameter("global_position", wave_position)

	if targets.size() == 0:
		return

	var target_pos: Vector2 = Vector2()
	var target_count: float = 0
	var targets_out: int = 0
	var targets_in: int = 0

	for target in targets:
		if global_position.distance_to(target.global_position) > target.max_distance:
			continue

		target_pos += (target.global_position + target.offset) * target.importance
		target_count += 1
		var target_screen_pos := target.get_global_transform_with_canvas().origin / get_viewport_rect().size
		var padding: float = 0.01

		if target_screen_pos.x < padding or target_screen_pos.x > 1 - padding or target_screen_pos.y < padding or target_screen_pos.y > 1 - padding:
			targets_out += 1
		else:
			targets_in += 1
		

	if targets_out > 0:
		targets_zoom = lerp(targets_zoom, max_targets_zoom, 0.0025)
	else:
		targets_zoom = 0

		
	if target_count > 0:
		target_pos /= target_count

	final_target_pos = target_pos

	var computed_bottom_limit: float = bottom_limit + (1 - zoom.x) * -100

	if final_target_pos.y > computed_bottom_limit:
		final_target_pos.y = computed_bottom_limit

	global_position.x = lerp(global_position.x, final_target_pos.x, follow_speed.x * _delta * 60.0)
	global_position.y = lerp(global_position.y, final_target_pos.y, follow_speed.y * _delta * 60.0)


func shake() -> void:
	var current_amount: float = pow(current_shake_amount, shake_power)
	rotation = max_roll * current_amount * randf_range(-1, 1)
	offset.x = max_offset.x * current_amount * randf_range(-1, 1)
	offset.y = max_offset.y * current_amount * randf_range(-1, 1)
	
