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
@export var chance_decay: float = 1.0
@export var free_space: float = 30.0
@export var spawn_type: SPAWN_POS_OPTIONS = SPAWN_POS_OPTIONS.GROUND
@export var amount: int = -1

@export var variations: Array[PrefabChance] = []

var original_chance: float
var original_amount: int


func init() -> void:
	original_chance = chance
	original_amount = amount

func select() -> PrefabChance:
	chance *= chance_decay
	return self

func reset() -> void:
	chance = original_chance
	original_amount = amount
