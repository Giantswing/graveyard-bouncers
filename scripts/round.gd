extends Resource

class_name GameRound

enum GROUND_TYPES {
	NORMAL,
	TOXIC,
	LAVA,
}

enum ROUND_MODES {
	TIME_LIMIT,
	ENEMY_COUNT,
	COLLECT,
}

@export var debug: bool = false

@export var difficulty: float = 1
@export var mode: ROUND_MODES = ROUND_MODES.TIME_LIMIT
@export var time_limit: int = 45
@export var enemy_count: int = 0
@export var collect_amount: int = 0

@export var chance: float = 1

@export_subgroup("Base adjustments")
@export var max_game_width: float = 250
@export var start_game_width: float = 150
@export var gravity_multiplier: float = 0.5
@export var game_width_speed_increase: float = 4 

@export_subgroup("Spawning")
@export var round_scenery: PackedScene

@export var enemy_list: Array[PrefabChance]
@export var enemy_spawn_rate: float = 2
@export var max_enemies: int = 10

@export var reward_list: Array[PrefabChance]
@export var reward_spawn_rate: float = 4
@export var max_rewards: int = 5

@export var other_list: Array[PrefabChance]
@export var other_spawn_rate: float = 4
@export var max_other: int = 5


@export_subgroup("Extras")
@export var ground_type: GROUND_TYPES = GROUND_TYPES.NORMAL
@export var has_trampoline: bool = false
@export var has_helper_enemy: bool = false
@export var has_fog: bool = false
@export_range(0, 10, 0.99) var spike_amount: int = 0

var original_chance: float
var id: int = 0

func init() -> void:
	id = randi()
	original_chance = chance
