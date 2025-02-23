extends Node2D

class_name GameManager

static var instance: GameManager

enum MODES { 
	BEFORE_ROUND,
	IN_ROUND,
	COUNTDOWN,
	CHALLENGE_MODE,
}


var camera: Camera2D = null
var can_restart: bool = false
var challenge_data: Challenge = null
var current_game_width: float = 0
var enemy_count: int = 0
var enemy_spawn_countdown: float = 0
var game_mode: MODES = MODES.BEFORE_ROUND
var game_paused: bool = false
var game_started: bool = false
var game_width: float = 400
var game_width_start: float
var ground_y_pos: float
var other_spawn_countdown: float = 0
var player_combo: int = 0
var player_hp: int = 3
var player_screen_pos: Vector2
var pre_round_game_width: float = 500
var reward_spawn_countdown: float = 0
var round_data: GameRound = null
var round_started: bool = false
var round_time: int = 0
var score: int = 0



@onready var enemy_container: Node2D = $"/root/Level/Scenery/EnemyContainer"
@onready var fog: ColorRect = %FogRect
@onready var lava_floor: Node2D = $"/root/Level/Scenery/LavaFloor"
@onready var left_top_part: Node2D 	 = $"/root/Level/Scenery/TopPart/LeftTopPart"
@onready var left_wall: Node2D = $"/root/Level/Scenery/LeftWall"
@onready var normal_floor: Node2D = $"/root/Level/Scenery/NormalFloor"
@onready var other_container: Node2D = $"/root/Level/Scenery/OtherContainer"
@onready var player: PlayerCharacter = $"/root/Level/Player" 
@onready var power_up_shop: Node2D = $"/root/Level/Scenery/PowerUpShop"
@onready var reward_container: Node2D = $"/root/Level/Scenery/RewardContainer"
@onready var right_top_part: Node2D = $"/root/Level/Scenery/TopPart/RightTopPart"
@onready var right_wall: Node2D = $"/root/Level/Scenery/RightWall"
@onready var round_manager: RoundManager = $RoundManager
@onready var seconds_timer: Timer = %SecondsTimer
@onready var starting_ground: Bridge = $"/root/Level/Scenery/StartingGround"
@onready var toxic_floor: Node2D = $"/root/Level/Scenery/ToxicFloor"
@onready var tutorial: Node2D = $"/root/Level/Scenery/Tutorial"


@export var all_abilities: Array[Ability]
@export var all_powerups: Array[PowerUp]
@export var coins: int = 0
@export var countdown_timer: int = 3
@export var current_difficulty: float = 1.0
@export var current_round: int = 0 
@export var heart_reward: PackedScene
@export var helper_enemy_prefab: PackedScene
@export var player_ability: Ability = null
@export var player_hp_max: int = 3
@export var powerups: Array[PowerUp]
@export var spikes_prefab: PackedScene
@export var trampoline_prefab: PackedScene


static func get_instance() -> GameManager:
	return instance

static func get_player_position() -> Vector2:
	if instance:
		if instance.player:
			return instance.player.global_position
	return Vector2(0, 0)

func _ready() -> void:
	instance = self

	game_width = pre_round_game_width
	seconds_timer.timeout.connect(on_seconds_timer_timeout)
	game_width_start = right_wall.position.x - left_wall.position.x

	Events.round_started.connect(start_round)
	Events.score_changed.connect(func(new_score: int) -> void: score = new_score)
	Events.coins_changed.connect(func(new_coins: int) -> void: coins = new_coins)
	Events.hp_changed.connect(on_hp_changed)
	Events.player_died.connect(on_player_died)
	Events.round_ended.connect(end_round)
	Events.picked_up_powerup.connect(add_powerup)
	Events.round_time_changed.emit(0)
	Events.score_changed.emit(score)
	Events.hp_changed.emit(player_hp_max, 0)
	Events.max_hp_changed.emit(player_hp_max)
	Events.coins_changed.emit(coins)
	Events.round_counter_changed.emit(current_round)
	Events.level_restart.emit()

	Events.enemy_died.connect(func(stats: Stats, from_parry: bool) -> void:
		var result_combo: int = player_combo + 1

		if has_powerup("combo-ability") && result_combo >= 5:
			gain_ability(find_ability("dash"))

		if stats.gives_combo:
			Events.combo_changed.emit(result_combo)

	)

	Events.enemy_hit.connect(func(stats: Stats, from_parry: bool) -> void:
		if stats.gives_combo:
			Events.combo_changed.emit(player_combo)
	)

	Events.combo_changed.connect(func(new_combo: int) -> void:
		player_combo = new_combo
	)

	Events.round_started.connect(func() -> void: change_mode(MODES.IN_ROUND))
	Events.round_ended.connect(func() -> void: change_mode(MODES.BEFORE_ROUND))
	Events.enter_challenge_mode.connect(func(_enter_player: PlayerCharacter) -> void: 
		use_all_abilities()
		change_mode(MODES.CHALLENGE_MODE)
	)
	Events.exit_challenge_mode.connect(func(_exit_player: PlayerCharacter) -> void: change_mode(MODES.BEFORE_ROUND))
	Events.round_countdown_start.connect(start_countdown)


	TimeManager.change_time_speed(1.0, 0, true)


	%UI.visible = true 
	gain_ability(player_ability)
	update_current_round()
	update_current_challenge()
	set_up_round()

	current_game_width = game_width

	change_mode(MODES.BEFORE_ROUND)


func start_countdown(time: int) -> void:
	tutorial.visible = false
	change_mode(MODES.COUNTDOWN)

	get_tree().create_timer(time).timeout.connect(func() -> void:
		if game_mode == MODES.COUNTDOWN:
			Events.round_started.emit()
	)
		

func change_mode(mode: MODES) -> void:
	game_mode = mode

func find_ability(ability_name: String) -> Ability:
	for ability in all_abilities:
		if ability.name == ability_name:
			return ability

	return null

func gain_ability(new_ability: Ability) -> void:
	if new_ability == null:
		player_ability = null
		Events.ability_gained.emit(null)
		return
	else:
		if player_ability != null and player_ability.name == new_ability.name:
			new_ability.increase_uses(1)
		else:
			new_ability.init()
			player_ability = new_ability

		Events.ability_gained.emit(player_ability)

func use_current_ability() -> void:
	if player_ability == null or player_ability.uses <= 0:
		return

	player_ability.uses -= 1
	Events.ability_gained.emit(player_ability)


func use_all_abilities() -> void:
	for ability in all_abilities:
		ability.uses = 0
	
	Events.ability_gained.emit(player_ability)


func update_current_challenge() -> void:
	challenge_data = round_manager.get_challenge(current_difficulty)
	Events.set_up_challenge.emit(challenge_data)
	

	
func on_player_died() -> void:
	seconds_timer.stop()
	can_restart = false
	get_tree().create_timer(0.5).timeout.connect(func() -> void: can_restart = true)


func on_seconds_timer_timeout() -> void:
	round_time += 1
	Events.round_time_changed.emit(round_time)
	
	if round_time >= round_data.time_limit && round_data.time_limit > 0:
		Events.round_ended.emit()



func on_hp_changed(new_hp: int, _change: int) -> void:
	if new_hp < player_hp:
		Events.combo_changed.emit(0)

	player_hp = new_hp

	if player_hp > player_hp_max:
		player_hp = player_hp_max

	if player_hp <= 0:
		Events.player_died.emit()


func pause_game(is_paused: bool) -> void:
	# We add a small delay so that when exiting the menu with the jump button, the player doesn't jump
	get_tree().create_timer(0.05).timeout.connect(func() -> void:
		game_paused = is_paused 
		get_tree().paused = is_paused
		Events.game_paused.emit(is_paused)
	)


func restart_level() -> void:
	get_tree().paused = false
	TimeManager.change_time_speed(1.0, 0, true)
	get_tree().reload_current_scene()

func exit_game() -> void:
	get_tree().quit()


func _process(delta: float) -> void:
	if player:
		var player_canvas := player.get_global_transform_with_canvas().origin
		var screen_size := get_viewport_rect().size
		player_screen_pos = player_canvas / screen_size
	else:
		player_screen_pos = Vector2(0.5, 0.5)

	if Input.is_action_just_pressed("Reset"):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("Jump") and can_restart:
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("Menu"):
		pause_game(!game_paused)


	current_game_width = lerp(current_game_width, game_width, 0.05)

	if !game_paused:
		left_wall.position.x = -current_game_width / 2
		left_top_part.position.x = -current_game_width / 2
		right_wall.position.x = current_game_width / 2
		right_top_part.position.x = current_game_width / 2

	if round_started and !game_paused:
		enemy_spawn_countdown -= delta
		reward_spawn_countdown -= delta
		other_spawn_countdown -= delta

		game_width += round_data.game_width_speed_increase * delta

		game_width = min(game_width, round_data.max_game_width)
		if game_width > 620:
			game_width = 620

		if reward_spawn_countdown <= 0:
			reward_spawn_countdown = round_data.reward_spawn_rate 
			Utils.spawn_prefab_from_list(round_data.reward_list, reward_container, round_data.max_rewards)

		# if other_spawn_countdown <= 0:
		# 	other_spawn_countdown = round_data.other_spawn_rate
		# 	Utils.spawn_prefab_from_list(round_data.other_list, other_container, round_data.max_other)

		if enemy_spawn_countdown <= 0 or enemy_container.get_child_count() == 0:
			enemy_spawn_countdown = round_data.enemy_spawn_rate
			Utils.spawn_prefab_from_list(round_data.enemy_list, enemy_container, round_data.max_enemies)



	# if round_data.has_fog:
	# 	var tween := get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
	# 	tween.tween_property(fog, "material:shader_parameter/alpha_multiplier", 3, 2)
	# else:
	# 	var tween := get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
	# 	tween.tween_property(fog, "material:shader_parameter/alpha_multiplier", 0.3, 2)

	var current_alpha_multiplier: float = fog.material.get_shader_parameter("alpha_multiplier")
	var current_color: Color = fog.material.get_shader_parameter("color")

	if round_data.has_fog:
		fog.material.set_shader_parameter("alpha_multiplier", lerp(current_alpha_multiplier, 2.0, 0.01))
	else:
		fog.material.set_shader_parameter("alpha_multiplier", lerp(current_alpha_multiplier, 0.3, 0.01))

	match round_data.ground_type:
		GameRound.GROUND_TYPES.NORMAL:
			fog.material.set_shader_parameter("color", lerp(current_color, Color(1.0, 1.0, 1.0, 1.0), 0.01))
		GameRound.GROUND_TYPES.TOXIC:
			fog.material.set_shader_parameter("color", lerp(current_color, Color(0.5, 0.7, 0.2, 1.0), 0.01))
		GameRound.GROUND_TYPES.LAVA:
			fog.material.set_shader_parameter("color", lerp(current_color, Color(1.0, 0.5, 0.2, 1.0), 0.01))



func set_up_round() -> void:
	game_width = pre_round_game_width

	if current_round < 3:
		tutorial.visible = true
	else:
		tutorial.visible = false

	var ground_height: float = 180
	var offset: float = 200

	if round_data.has_trampoline:
		get_tree().create_timer(1).timeout.connect(
			func() -> void:
				var new_obj: Node2D = Utils.spawn_prefab(trampoline_prefab, reward_container, PrefabChance.SPAWN_POS_OPTIONS.GROUND, 20)
				new_obj.scale = Vector2(0, 0)
				Utils.fast_tween(new_obj, "scale", Vector2(1, 1), 0.4)
		)

	if round_data.has_helper_enemy:
		var new_obj: Node2D = Utils.spawn_prefab(helper_enemy_prefab, reward_container, PrefabChance.SPAWN_POS_OPTIONS.GROUND, 20)
		new_obj.scale = Vector2(0, 0)
		Utils.fast_tween(new_obj, "scale", Vector2(1, 1), 0.4)

	if round_data.spike_amount > 0:
		for i in range(round_data.spike_amount):
			var new_obj: Node2D = Utils.spawn_prefab(spikes_prefab, other_container, PrefabChance.SPAWN_POS_OPTIONS.GROUND, 42, true)
			if new_obj:
				new_obj.position.y = new_obj.position.y + 32
				Utils.fast_tween(new_obj, "position:y", new_obj.position.y - 18, 0.5)
		

	match round_data.ground_type:
		GameRound.GROUND_TYPES.NORMAL:
			# Utils.fast_tween(fog, "material:shader_parameter/color", Color(1.0, 1.0, 1.0, 0.5), 2)
			Utils.fast_tween(normal_floor, "position:y", ground_height, 0.5)
			Utils.fast_tween(toxic_floor, "position:y", ground_height + offset, 0.5)
			Utils.fast_tween(lava_floor, "position:y", ground_height + offset, 0.5)

		GameRound.GROUND_TYPES.TOXIC:
			# Utils.fast_tween(fog, "material:shader_parameter/color", Color(0.5, 0.7, 0.2, 1), 2)
			Utils.fast_tween(normal_floor, "position:y", ground_height + offset, 0.5)
			Utils.fast_tween(toxic_floor, "position:y", ground_height, 0.5)
			Utils.fast_tween(lava_floor, "position:y", ground_height + offset, 0.5)

		GameRound.GROUND_TYPES.LAVA:
			# Utils.fast_tween(fog, "material:shader_parameter/color", Color(1.0, 0.5, 0.2, 1), 2)
			Utils.fast_tween(normal_floor, "position:y", ground_height + offset, 0.5)
			Utils.fast_tween(toxic_floor, "position:y", ground_height + offset, 0.5)
			Utils.fast_tween(lava_floor, "position:y", ground_height, 0.5)
	


func should_spawn(current_amount: int, max_amount: int) -> bool:
	if current_amount >= max_amount:
		return false

	return true


func update_current_round() -> void:
	round_data = round_manager.get_round(current_difficulty)
	if player:
		player.base_strength = 285 * sqrt(round_data.gravity_multiplier) * player.all_jumps_str_mult
	# print("Current difficulty: ", current_difficulty)
	# print("Current round: ", "dif: ", round_data.difficulty, ", time: ", round_data.time_limit, ", enemies: ", round_data.max_enemies, ", rewards: ", round_data.max_rewards)

func add_powerup(powerup: PowerUp) -> void:
	powerups.append(powerup)

	if powerup.power_up_name == "heal-potion":
		Events.hp_changed.emit(player_hp_max, 0)
	elif powerup.power_up_name == "dash-increase":
		find_ability("dash").max_uses += 1
		print("Dash uses: ", find_ability("dash").max_uses)
	elif powerup.power_up_name == "extra-life":
		player_hp_max += 1
		Events.max_hp_changed.emit(player_hp_max)
		Events.hp_changed.emit(player_hp_max, 0)

	if player:
		get_tree().create_timer(0.1).timeout.connect(func() -> void:
			player.base_strength = 285 * sqrt(round_data.gravity_multiplier) * player.all_jumps_str_mult
		)


func has_powerup(powerup_name: String, ignore_active: bool = false) -> bool:
	for powerup in powerups:
		if ignore_active:
			if powerup.power_up_name == powerup_name:
				return true
		else:
			if powerup.power_up_name == powerup_name and powerup.active:
				return true

	return false


	
func set_powerup_active(powerup_name: String, active: bool) -> void:
	for powerup in powerups:
		if powerup.power_up_name == powerup_name:
			powerup.active = active
			break


func start_round() -> void:
	tutorial.visible = false
	# game_width_start = right_wall.position.x - left_wall.position.x
	game_width = round_data.start_game_width
	starting_ground.enable_bridge()

	starting_ground.disable_bridge()

	ground_y_pos = starting_ground.position.y
	Utils.fast_tween(starting_ground, "position:y", 220, 0.5)

	current_round += 1
	Events.round_counter_changed.emit(current_round)

	seconds_timer.start()

	game_started = true
	round_started = true


func end_round() -> void:
	Events.round_time_changed.emit(0)
	starting_ground.disable_bridge()
	SoundSystem.play_audio("round-end")

	round_started = false
	round_time = 0
	enemy_spawn_countdown = 0
	reward_spawn_countdown = 0

	seconds_timer.stop()
	game_width = game_width_start
	Utils.fast_tween(starting_ground, "position:y", ground_y_pos, 1)

	starting_ground.enable_bridge()

	for enemy in enemy_container.get_children():
		enemy.queue_free()

	for reward in reward_container.get_children():
		if reward is Pickup:
			var pickup_reward: Pickup = reward as Pickup
			if pickup_reward.pickup_state != 0:
				continue

		reward.queue_free()

	for other in other_container.get_children():
		other.queue_free()

	current_difficulty += 1

	update_current_round()
	update_current_challenge()
	set_up_round()
