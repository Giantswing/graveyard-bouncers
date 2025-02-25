extends Node2D

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var detect_area: Area2D = $DetectArea

@export var spawn: PackedScene = null
@export var time_to_spawn: float = 1.0
@export var spawn_limit: int = -1

var time_elapsed: float = 0.0
var game_manager: GameManager
var spawn_name: String = ""
var delta_process: float = 0.0

func _ready() -> void:
	game_manager = GameManager.get_instance()
	spawn_name = spawn.instantiate().name
	print(spawn_name)

func _process(delta: float) -> void:
	if spawn_limit == 0:
		return

	var overlapping_bodies := detect_area.get_overlapping_bodies()
	var overlapping_areas := detect_area.get_overlapping_areas()
	var increase_timer := true

	for body in overlapping_bodies:
		if body is PlayerCharacter or body.name == spawn_name or body.get_parent().name == spawn_name:
			increase_timer = false
			break

	for area in overlapping_areas:
		if area.name == spawn_name or area.get_parent().name == spawn_name:
			increase_timer = false
			break

	# print(overlapping_bodies, " ", overlapping_areas)
	
	if increase_timer:
		time_elapsed += delta
	else:
		time_elapsed = 0.0

	if time_elapsed >= time_to_spawn:
		time_elapsed = 0.0
		process_spawn()



func process_spawn() -> void:
	var new_obj: Node2D = spawn.instantiate()
	new_obj.global_position = spawn_point.global_position
	game_manager.other_container.add_child(new_obj)
	spawn_limit -= 1
