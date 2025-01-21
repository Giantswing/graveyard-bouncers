extends Node2D

@export var enemy_spawn_rate: float = 1
@export var reward_spawn_rate: float = 4
@export var game_width_speed_increase: float = 0.1
@export var max_enemies: int = 10
@export var max_reward: int = 8
@export var spawn_list: Array[PrefabChance]
@export var reward_list: Array[PrefabChance]
@export var gravity_multiplier: float = 1
@export var player_hp_max: int = 3
@export var game_width_start: float

@onready var seconds_timer: Timer = %SecondsTimer

@export var round_max_time: int = 20
@export var current_round: int = 0

@export var powerups: Array[PowerUp]

var round_time: int = 0

var score: int = 0
var coins: int = 0
var player_hp: int = 3
var enemy_container: Node2D
var reward_container: Node2D
var power_up_shop: Node2D
var enemy_spawn_countdown: float = 0
var reward_spawn_countdown: float = 0
var game_width: float = 200
var left_wall: Node2D
var right_wall: Node2D
var round_started: bool = false
var game_started: bool = false
var starting_ground: StaticBody2D
var trampoline: Node2D
var grave: Node2D
var can_restart: bool = false
var ground_y_pos: float

func _ready() -> void:
	Events.round_started.connect(start_round)
	Events.score_changed.connect(on_score_changed)
	Events.coins_changed.connect(on_coins_changed)
	Events.hp_changed.connect(on_hp_changed)
	Events.player_died.connect(on_player_died)
	Events.level_restarted.connect(on_level_restarted)
	seconds_timer.timeout.connect(on_seconds_timer_timeout)
	Events.round_ended.connect(end_round)
	Events.picked_up_powerup.connect(add_powerup)
	Events.level_restarted.emit()

func on_level_restarted() -> void:
	round_time = 0
	score = 0
	coins = 0
	game_started = false
	player_hp = player_hp_max
	round_started = false
	enemy_spawn_countdown = 0
	game_width = game_width_start
	seconds_timer.stop()
	can_restart = false
	Engine.time_scale = 1

func on_player_died() -> void:
	seconds_timer.stop()
	can_restart = false
	get_tree().create_timer(0.5).timeout.connect(func(): can_restart = true)


func on_seconds_timer_timeout() -> void:
	round_time += 1
	Events.round_time_changed.emit(round_time)
	
	if round_time >= round_max_time:
		Events.round_ended.emit()

func on_score_changed(new_score: int) -> void:
	score = new_score

func on_coins_changed(new_coins: int) -> void:
	coins = new_coins

func on_hp_changed(new_hp: int, _change: int) -> void:
	player_hp = new_hp
	if player_hp <= 0:
		Events.player_died.emit()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Reset"):
		Events.level_restarted.emit()
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("Jump") and can_restart:
		Events.level_restarted.emit()
		get_tree().reload_current_scene()

	if game_started:
		left_wall.position.x = lerp(left_wall.position.x, -game_width / 2, 0.1)
		right_wall.position.x = lerp(right_wall.position.x, game_width / 2, 0.1)


	if round_started:
		enemy_spawn_countdown -= delta
		reward_spawn_countdown -= delta
		game_width += game_width_speed_increase * delta
		game_width = min(game_width, 620)

		if reward_spawn_countdown <= 0:
			reward_spawn_countdown = reward_spawn_rate
			if should_spawn(reward_container.get_child_count(), max_reward):
				spawn_prefab(reward_list, reward_container, max_reward, 20)

		if enemy_spawn_countdown <= 0 or enemy_container.get_child_count() == 0:
			enemy_spawn_countdown = enemy_spawn_rate
			if should_spawn(enemy_container.get_child_count(), max_enemies):
				spawn_prefab(spawn_list, enemy_container, max_enemies, 100)


func spawn_prefab(list: Array[PrefabChance], container: Node2D, max_amount: int, free_space: float) -> void:
	if container.get_child_count() >= max_amount:
		return 

	var max_spawn_attempts: int = 10

	var total_chance: float = 0

	for prefab_chance in list:
		total_chance += prefab_chance.chance

	var chance: float = randf() * total_chance
	var current_chance: float = 0

	for prefab_chance in list:
		current_chance += prefab_chance.chance
		if chance > current_chance:
			continue

		var instance: Node2D = prefab_chance.prefab.instantiate()
		var spawn_pos: Vector2 = Vector2.ZERO

		var horizontal_wall_padding = 10

		for i in range(max_spawn_attempts):
			var pos_x = randf_range(-game_width / 2 + horizontal_wall_padding, game_width / 2 - horizontal_wall_padding)
			var pos_y = 147

			if prefab_chance.spawn_type == PrefabChance.SPAWN_POS_OPTIONS.AIR:
				pos_y = randf_range(90, 147)
			elif prefab_chance.spawn_type == PrefabChance.SPAWN_POS_OPTIONS.REWARD:
				pos_y = randf_range(0, -150)
			elif prefab_chance.spawn_type == PrefabChance.SPAWN_POS_OPTIONS.AIR_OUTSIDE:
				pos_y = randf_range(90, -120)
				# var side = randf() < 0.5
				var side = randf() > 1 

				pos_x = -game_width / 2 - 80 if side else game_width / 2 + 80


			spawn_pos = Vector2(pos_x, pos_y)

			var is_free: bool = true

			for unit in container.get_children():
				if unit.position.distance_to(spawn_pos) < free_space:
					is_free = false
					break

			# if not is_free and i != max_spawn_attempts - 1:
			if not is_free:
				continue

			print(i)
			instance.position = spawn_pos
			container.add_child(instance)
			
			return


func should_spawn(current_amount: int, max_amount: int) -> bool:
	if current_amount >= max_amount:
		return false

	var spawn_chance = 1.0 - float(current_amount) / float(max_amount)
	
	var roll = randf()
	
	if roll < spawn_chance:
		return true
	else:
		return false


func add_powerup(powerup: PowerUp) -> void:
	print(powerup.power_up_name)
	powerups.append(powerup)

	if powerup.power_up_name == "Potion":
		Events.hp_changed.emit(player_hp_max, 0)


func start_round() -> void:
	left_wall = $"/root/Level/Scenery/LeftWall"
	right_wall = $"/root/Level/Scenery/RightWall"
	starting_ground = $"/root/Level/Scenery/StartingGround"
	trampoline = $"/root/Level/Scenery/Trampoline"
	enemy_container = $"/root/Level/Scenery/EnemyContainer"
	reward_container = $"/root/Level/Scenery/RewardContainer"
	grave = $"/root/Level/Scenery/Grave"
	power_up_shop = $"/root/Level/Scenery/PowerUpShop"

	game_width_start = right_wall.position.x - left_wall.position.x
	game_width = game_width_start

	ground_y_pos = starting_ground.position.y
	starting_ground.set_collision_layer_value(1, false)
	get_tree().create_tween().tween_property(starting_ground, "position:y", 220, 0.5)

	current_round += 1
	Events.round_counter_changed.emit(current_round)

	deactivate(trampoline)
	deactivate(grave)

	seconds_timer.start()

	game_started = true

	round_started = true


func end_round() -> void:
	Events.round_time_changed.emit(0)

	round_started = false
	round_time = 0
	enemy_spawn_countdown = 0
	reward_spawn_countdown = 0

	seconds_timer.stop()
	starting_ground.set_collision_layer_value(1, true)
	game_width = game_width_start
	get_tree().create_tween().tween_property(starting_ground, "position:y", ground_y_pos, 0.5)

	get_tree().create_timer(0.5).timeout.connect(func():
		activate(trampoline)
		activate(grave)
	)

	for enemy in enemy_container.get_children():
		enemy.queue_free()

	for reward in reward_container.get_children():
		reward.queue_free()


func deactivate(target: Node2D) -> void:
	var tween := get_tree().create_tween().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(target, "scale", Vector2(0, 0), 0.5)
	tween.tween_callback(
		func() -> void:
			target.process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
			target.visible = false
	)

func activate(target: Node2D) -> void:
	target.process_mode = Node.ProcessMode.PROCESS_MODE_ALWAYS
	target.visible = true
	target.scale = Vector2(0, 0)

	var tween := get_tree().create_tween().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(target, "scale", Vector2(1, 1), 0.5)
