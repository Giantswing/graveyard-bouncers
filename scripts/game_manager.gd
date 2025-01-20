extends Node2D

@export var enemy_spawn_rate: float = 1
@export var game_width_speed_increase: float = 0.1
@export var max_enemies: int = 10
@export var spawn_list: Array[PrefabChance]
@export var gravity_multiplier: float = 1
@export var player_hp_max: int = 3

@onready var seconds_timer: Timer = %SecondsTimer

var round_time: int = 0
var score: int = 0
var player_hp: int = 3
var enemy_container: Node2D
var enemy_spawn_countdown: float = 0
var game_width: float = 200
var left_wall: Node2D
var right_wall: Node2D
var round_started: bool = false
var starting_ground: Node2D
var trampoline: Node2D
var can_restart: bool = false

func _ready() -> void:
	Events.round_started.connect(start_round)
	Events.score_changed.connect(on_score_changed)
	Events.hp_changed.connect(on_hp_changed)
	Events.player_died.connect(on_player_died)
	Events.level_restarted.connect(on_level_restarted)
	seconds_timer.timeout.connect(on_seconds_timer_timeout)

func on_level_restarted() -> void:
	round_time = 0
	score = 0
	player_hp = player_hp_max
	round_started = false
	enemy_spawn_countdown = 0
	game_width = 200
	seconds_timer.stop()
	can_restart = false
	Engine.time_scale = 1

func on_player_died() -> void:
	seconds_timer.stop()
	can_restart = false
	get_tree().create_timer(0.5).timeout.connect(allow_can_restart)

func on_seconds_timer_timeout() -> void:
	round_time += 1
	Events.round_time_changed.emit(round_time)

func on_score_changed(new_score: int) -> void:
	score = new_score

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

	if round_started:
		enemy_spawn_countdown -= delta
		game_width += game_width_speed_increase * delta

		left_wall.position.x = lerp(left_wall.position.x, -game_width / 2, 0.1)
		right_wall.position.x = lerp(right_wall.position.x, game_width / 2, 0.1)

		if enemy_spawn_countdown <= 0:
			enemy_spawn_countdown = enemy_spawn_rate
			spawn_prefab()


func spawn_prefab() -> void:
	if enemy_container.get_child_count() >= max_enemies:
		return 

	var max_spawn_attempts: int = 10

	var totalChance: float = 0

	for prefab_chance in spawn_list:
		totalChance += prefab_chance.chance

	var chance: float = randf() * totalChance
	var currentChance: float = 0

	for prefab_chance in spawn_list:
		currentChance += prefab_chance.chance
		if chance > currentChance:
			continue

		var instance: Node2D = prefab_chance.prefab.instantiate()
		var spawn_pos: Vector2 = Vector2.ZERO

		var horizontal_wall_padding = 10

		for i in range(max_spawn_attempts):
			var pos_x = randf_range(-game_width / 2 + horizontal_wall_padding, game_width / 2 - horizontal_wall_padding)
			var pos_y = 147

			if prefab_chance.spawn_type == PrefabChance.SPAWN_POS_OPTIONS.AIR:
				pos_y = randf_range(90, 147)


			spawn_pos = Vector2(pos_x, pos_y)

			var is_free: bool = true

			for enemy in enemy_container.get_children():
				if enemy.position.distance_to(spawn_pos) < 20:
					is_free = false
					break

			if not is_free and i != max_spawn_attempts - 1:
				continue

			instance.position = spawn_pos
			enemy_container.add_child(instance)

			break

func start_round() -> void:
	left_wall = $"/root/Level/Scenery/LeftWall"
	right_wall = $"/root/Level/Scenery/RightWall"
	starting_ground = $"/root/Level/Scenery/StartingGround"
	trampoline = $"/root/Level/Scenery/Trampoline"
	enemy_container = $"/root/Level/Scenery/EnemyContainer"

	starting_ground.process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
	starting_ground.visible = false

	trampoline.process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
	trampoline.visible = false

	seconds_timer.start()

	round_started = true

func allow_can_restart() -> void:
	can_restart = true
