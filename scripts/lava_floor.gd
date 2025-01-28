extends Node2D

@export var lava_ball: PackedScene
@export var spawn_timer_max: float = 2.0
var spawn_timer: float = 0.0

func _ready() -> void:
	spawn_timer = spawn_timer_max

func _process(delta: float) -> void:
	spawn_timer -= delta

	if spawn_timer <= 0 and GameManager.instance.round_data.ground_type == GameRound.GROUND_TYPES.LAVA:
		spawn_timer = spawn_timer_max * randf_range(0.8, 1.2)
		Utils.spawn_prefab(lava_ball, null, PrefabChance.SPAWN_POS_OPTIONS.GROUND, 30)
	

	
