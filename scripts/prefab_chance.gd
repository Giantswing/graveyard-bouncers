extends Resource

class_name PrefabChance

enum SPAWN_POS_OPTIONS {
	GROUND,
	AIR,
}

@export var name: String
@export var prefab: PackedScene
@export var chance: float = 1.0
@export var spawn_type: SPAWN_POS_OPTIONS = SPAWN_POS_OPTIONS.GROUND
