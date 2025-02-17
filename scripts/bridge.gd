extends Node2D

class_name Bridge

@export var bridge_piece_prefab: PackedScene
@export var bridge_length: int = 32

@onready var start_point: Node2D = $StartPoint
@onready var end_point: Node2D = $EndPoint
@onready var bridge_pieces_container: Node2D = $BridgePiecesContainer

var game_manager: GameManager
var distance: float
var old_distance: float
var bridge_pieces: Array[BridgePiece]
var player: Node2D

@export var allow_from_below: bool = true
@export var main_bridge: bool = false

var bridge_count: int
var old_bridge_count: int
var bridge_enabled: bool = true

@export var default_max_sag: float = -20.0
@export var player_max_sag: float = -20.0
var current_sag: float
var sag_to_reach: float

func _ready() -> void:
	current_sag = default_max_sag
	game_manager = GameManager.instance
	player = game_manager.player
	distance = 0
	bridge_count = 0
	start_point.visible = false
	end_point.visible = false
	construct_bridge()

func disable_bridge() -> void:
	bridge_enabled = false

	for b_piece: BridgePiece in bridge_pieces:
		b_piece.set_collision_layer_value(1, false)

func enable_bridge() -> void:
	bridge_enabled = true

	for b_piece: BridgePiece in bridge_pieces:
		b_piece.set_collision_layer_value(1, true)

func _process(delta: float) -> void:
	old_distance = distance
	old_bridge_count = bridge_count

	current_sag += (sag_to_reach - current_sag) * 0.04 * delta * 60.0

	if main_bridge:
		start_point.position.x = -game_manager.current_game_width / 2 - 10.0
		end_point.position.x = game_manager.current_game_width / 2 + 20.0

	distance = end_point.position.x - start_point.position.x
	bridge_count = ceil(distance / bridge_length)

	if bridge_count != old_bridge_count:
		construct_bridge()
	else:
		update_bridge()

func update_bridge() -> void:
	get_dynamic_sag()

	var prev_x: float = start_point.position.x
	var prev_y: float = start_point.position.y

	for i in range(bridge_pieces.size()):
		var bridge: Node2D = bridge_pieces[i]
		bridge.position.x = start_point.position.x + i * bridge_length

		var progress: float = (bridge.position.x - start_point.position.x) / distance
		bridge.position.y = start_point.position.y + current_sag * (4 * (progress - 0.5) ** 2 - 1)

		if i > 0:
			var dy: float = bridge.position.y - prev_y - 1
			var dx: float = bridge.position.x - prev_x
			bridge.rotation = atan2(dy, dx)
		else:
			bridge.rotation = 0.0

		prev_x = bridge.position.x
		prev_y = bridge.position.y


func is_player_on_bridge() -> bool:
	var result: bool = false

	for b_piece: BridgePiece in bridge_pieces:
		if b_piece.colliding_with_player:
			result = true
			break

	return result


func get_dynamic_sag() -> void:
	var base_sag: float = default_max_sag
	var extra_sag: float = player_max_sag
	var sag_radius: float = distance * 0.3

	if player and is_player_on_bridge():
		var bridge_center_x: float = (start_point.global_position.x + end_point.global_position.x) / 2
		var player_distance_from_center: float = abs(player.global_position.x - bridge_center_x)

		var sag_factor: float = clamp(1.0 - (player_distance_from_center / sag_radius), 0.0, 1.0)
		sag_to_reach = base_sag + extra_sag * sag_factor
	else:
		sag_to_reach = base_sag

func construct_bridge() -> void:
	for child in bridge_pieces_container.get_children():
		child.queue_free()

	bridge_pieces.clear()

	for i in range(bridge_count):
		var bridge_piece: BridgePiece = bridge_piece_prefab.instantiate()
		bridge_pieces_container.add_child(bridge_piece)
		bridge_pieces.append(bridge_piece)

		if allow_from_below:
			bridge_piece.allow_from_below()

		if bridge_enabled:
			bridge_piece.set_collision_layer_value(7, true)
			if main_bridge:
				bridge_piece.set_collision_layer_value(1, true)
		else:
			bridge_piece.set_collision_layer_value(7, false)
			if main_bridge:
				bridge_piece.set_collision_layer_value(1, false)

	update_bridge()
