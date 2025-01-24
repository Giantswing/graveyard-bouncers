extends Resource

class_name PrefabChance

enum SPAWN_POS_OPTIONS {
	GROUND,
	AIR,
	AIR_OUTSIDE,
	REWARD,
}

@export var name: String
@export var prefab: PackedScene
@export var chance: float = 1.0
@export var free_space: float = 30.0
@export var spawn_type: SPAWN_POS_OPTIONS = SPAWN_POS_OPTIONS.GROUND
