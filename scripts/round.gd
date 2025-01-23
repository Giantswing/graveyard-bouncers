extends Resource

class_name GameRound

@export var time_limit: int = 45
@export var gravity_multiplier: float = 0.5
@export var game_width_speed_increase: float = 4 

@export var enemy_list: Array[PrefabChance]
@export var enemy_spawn_rate: float = 2
@export var max_enemies: int = 10

@export var reward_list: Array[PrefabChance]
@export var reward_spawn_rate: float = 4
@export var max_rewards: int = 5

@export var has_toxic_floor: bool = false
