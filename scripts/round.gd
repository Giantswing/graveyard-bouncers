extends Resource

class_name GameRound

enum GROUND_TYPES {
	NORMAL,
	TOXIC,
	LAVA,
}

@export var difficulty: float = 1
@export var time_limit: int = 45
@export var chance: float = 1

@export var gravity_multiplier: float = 0.5
@export var game_width_speed_increase: float = 4 

@export var enemy_list: Array[PrefabChance]
@export var enemy_spawn_rate: float = 2
@export var max_enemies: int = 10

@export var reward_list: Array[PrefabChance]
@export var reward_spawn_rate: float = 4
@export var max_rewards: int = 5

@export_category("Extras")
@export var ground_type: GROUND_TYPES = GROUND_TYPES.NORMAL
@export var has_trampoline: bool = false
@export var has_helper_enemy: bool = false

var original_chance: float
var id: int = 0

func init() -> void:
	id = randi()
	original_chance = chance
